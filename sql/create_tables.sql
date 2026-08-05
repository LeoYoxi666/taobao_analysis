-- Taobao User Behaviour Analysis
-- PostgreSQL schema for the SQL database layer.
--
-- The source CSV is not modified by this script. Duplicate source rows are
-- deliberately allowed in behaviour_events because the Python data-quality
-- checks report duplicates without deleting them.

BEGIN;

CREATE SCHEMA IF NOT EXISTS taobao;

-- Lookup table matching the behaviour constants in src/config.py.
CREATE TABLE IF NOT EXISTS taobao.behaviour_types (
    behaviour_type SMALLINT PRIMARY KEY,
    behaviour_name VARCHAR(20) NOT NULL UNIQUE,
    CONSTRAINT valid_behaviour_type
        CHECK (behaviour_type BETWEEN 1 AND 4)
);

INSERT INTO taobao.behaviour_types (behaviour_type, behaviour_name)
VALUES
    (1, 'View'),
    (2, 'Favorite'),
    (3, 'Cart'),
    (4, 'Purchase')
ON CONFLICT (behaviour_type) DO UPDATE
SET behaviour_name = EXCLUDED.behaviour_name;

-- One row per observed user. The dataset contains no additional user profile
-- attributes, so no unsupported demographic fields are added.
CREATE TABLE IF NOT EXISTS taobao.users (
    user_id BIGINT PRIMARY KEY
);

-- One row per observed item category.
CREATE TABLE IF NOT EXISTS taobao.categories (
    category_id BIGINT PRIMARY KEY
);

-- Each item is linked to its observed category. The import script validates
-- that one item does not map to multiple categories before populating this
-- table.
CREATE TABLE IF NOT EXISTS taobao.items (
    item_id BIGINT PRIMARY KEY,
    category_id BIGINT NOT NULL,
    CONSTRAINT fk_items_category
        FOREIGN KEY (category_id)
        REFERENCES taobao.categories (category_id)
        ON DELETE RESTRICT
);

-- Fact table containing every source behaviour event. event_id provides a
-- deterministic tie-breaker when events share the same timestamp.
CREATE TABLE IF NOT EXISTS taobao.behaviour_events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    user_id BIGINT NOT NULL,
    item_id BIGINT NOT NULL,
    behaviour_type SMALLINT NOT NULL,
    CONSTRAINT fk_events_user
        FOREIGN KEY (user_id)
        REFERENCES taobao.users (user_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_events_item
        FOREIGN KEY (item_id)
        REFERENCES taobao.items (item_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_events_behaviour_type
        FOREIGN KEY (behaviour_type)
        REFERENCES taobao.behaviour_types (behaviour_type)
        ON DELETE RESTRICT
);

-- Staging table mirrors the five CSV columns. source_time remains text until
-- the controlled insert into behaviour_events, making conversion failures
-- explicit. staging_id preserves the original file order.
CREATE TABLE IF NOT EXISTS taobao.staging_user_behaviour (
    staging_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_time TEXT NOT NULL,
    user_id BIGINT NOT NULL,
    item_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    behaviour_type SMALLINT NOT NULL
);

-- Indexes support chronological user, funnel, path, product, and hourly
-- analyses over the event fact table.
CREATE INDEX IF NOT EXISTS idx_items_category
    ON taobao.items (category_id);

CREATE INDEX IF NOT EXISTS idx_events_user_time
    ON taobao.behaviour_events (user_id, event_time, event_id);

CREATE INDEX IF NOT EXISTS idx_events_user_item_time
    ON taobao.behaviour_events (
        user_id,
        item_id,
        event_time,
        event_id
    );

CREATE INDEX IF NOT EXISTS idx_events_behaviour_time
    ON taobao.behaviour_events (behaviour_type, event_time);

CREATE INDEX IF NOT EXISTS idx_events_item_behaviour
    ON taobao.behaviour_events (item_id, behaviour_type);

CREATE INDEX IF NOT EXISTS idx_events_time_brin
    ON taobao.behaviour_events USING BRIN (event_time);

COMMENT ON TABLE taobao.behaviour_events IS
    'Chronological Taobao user-item behaviour events; duplicate source rows are preserved.';
COMMENT ON COLUMN taobao.behaviour_events.event_time IS
    'Naive source timestamp, equivalent to the pandas datetime used by the existing analysis.';
COMMENT ON COLUMN taobao.behaviour_events.event_id IS
    'Surrogate key and stable tie-breaker for events with identical timestamps.';

COMMIT;
