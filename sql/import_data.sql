-- Bulk import workflow for PostgreSQL psql.
--
-- Run this file from the project root after create_tables.sql. The \copy
-- command streams the CSV from the client machine and does not use pandas.
-- This script intentionally refuses to append to a populated database so an
-- accidental second run cannot duplicate all source events.

\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM taobao.behaviour_events LIMIT 1) THEN
        RAISE EXCEPTION
            'behaviour_events is not empty; import into a fresh database or clear it deliberately first';
    END IF;

    IF EXISTS (SELECT 1 FROM taobao.staging_user_behaviour LIMIT 1) THEN
        RAISE EXCEPTION
            'staging_user_behaviour is not empty; resolve the previous import before retrying';
    END IF;
END
$$;

-- Source column order:
-- time, user_id, item_id, item_category, behavior_type
\copy taobao.staging_user_behaviour (source_time, user_id, item_id, category_id, behaviour_type) FROM 'data/user_behavior_processed.csv' WITH (FORMAT csv, HEADER true)

-- Reject behaviour codes outside the four values used by the Python project.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM taobao.staging_user_behaviour
        WHERE behaviour_type NOT BETWEEN 1 AND 4
    ) THEN
        RAISE EXCEPTION 'The source contains an unsupported behaviour_type';
    END IF;
END
$$;

-- The normalized items table assumes one category per item. Stop rather than
-- silently selecting a category if the source violates that relationship.
DO $$
BEGIN
    IF EXISTS (
        SELECT item_id
        FROM taobao.staging_user_behaviour
        GROUP BY item_id
        HAVING COUNT(DISTINCT category_id) > 1
    ) THEN
        RAISE EXCEPTION
            'At least one item maps to multiple categories; review the schema before importing';
    END IF;
END
$$;

INSERT INTO taobao.users (user_id)
SELECT DISTINCT user_id
FROM taobao.staging_user_behaviour
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO taobao.categories (category_id)
SELECT DISTINCT category_id
FROM taobao.staging_user_behaviour
ON CONFLICT (category_id) DO NOTHING;

INSERT INTO taobao.items (item_id, category_id)
SELECT item_id, MIN(category_id) AS category_id
FROM taobao.staging_user_behaviour
GROUP BY item_id
ON CONFLICT (item_id) DO NOTHING;

-- Ordering by staging_id makes event_id follow source file order. This is
-- important when multiple events share the same timestamp.
INSERT INTO taobao.behaviour_events (
    event_time,
    user_id,
    item_id,
    behaviour_type
)
SELECT
    (source_time || ':00:00')::TIMESTAMP WITHOUT TIME ZONE,
    user_id,
    item_id,
    behaviour_type
FROM taobao.staging_user_behaviour
ORDER BY staging_id;

ANALYZE taobao.users;
ANALYZE taobao.categories;
ANALYZE taobao.items;
ANALYZE taobao.behaviour_events;

COMMIT;

-- Post-import row and dimension counts. Compare these values with the verified
-- project totals before running analytical queries.
SELECT
    (SELECT COUNT(*) FROM taobao.behaviour_events) AS event_rows,
    (SELECT COUNT(*) FROM taobao.users) AS users,
    (SELECT COUNT(*) FROM taobao.items) AS items,
    (SELECT COUNT(*) FROM taobao.categories) AS categories;

-- Data-quality checks equivalent to the existing Python checks. Duplicate
-- event rows are reported but not removed.
SELECT COALESCE(SUM(rows_in_group - 1), 0) AS duplicate_rows
FROM (
    SELECT
        event_time,
        user_id,
        item_id,
        behaviour_type,
        COUNT(*) AS rows_in_group
    FROM taobao.behaviour_events
    GROUP BY
        event_time,
        user_id,
        item_id,
        behaviour_type
    HAVING COUNT(*) > 1
) AS duplicated_event_groups;
