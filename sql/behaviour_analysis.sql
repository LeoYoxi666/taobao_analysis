-- Behaviour distribution
-- Counts all event rows by behaviour code, matching pandas value_counts().
-- The lookup table drives the result so every configured behaviour remains
-- visible in report output even when its event count is zero.
WITH behaviour_counts AS (
    SELECT behaviour_type, COUNT(*) AS action_count
    FROM taobao.behaviour_events
    GROUP BY behaviour_type
)
SELECT
    types.behaviour_type,
    types.behaviour_name,
    COALESCE(behaviour_counts.action_count, 0) AS action_count,
    ROUND(
        COALESCE(behaviour_counts.action_count, 0) * 100.0
            / NULLIF(
                SUM(COALESCE(behaviour_counts.action_count, 0)) OVER (),
                0
            ),
        2
    ) AS percentage_of_actions
FROM taobao.behaviour_types AS types
LEFT JOIN behaviour_counts
    ON behaviour_counts.behaviour_type = types.behaviour_type
ORDER BY action_count DESC, types.behaviour_type;

-- Hourly activity analysis
-- generate_series guarantees that hours with no events are still returned.
WITH hours AS (
    SELECT generate_series(0, 23) AS activity_hour
),
hourly_counts AS (
    SELECT
        EXTRACT(HOUR FROM event_time)::INTEGER AS activity_hour,
        COUNT(*) AS total_actions,
        COUNT(*) FILTER (WHERE behaviour_type = 4) AS purchase_actions
    FROM taobao.behaviour_events
    GROUP BY EXTRACT(HOUR FROM event_time)::INTEGER
)
SELECT
    hours.activity_hour,
    COALESCE(hourly_counts.total_actions, 0) AS total_actions,
    COALESCE(hourly_counts.purchase_actions, 0) AS purchase_actions
FROM hours
LEFT JOIN hourly_counts USING (activity_hour)
ORDER BY hours.activity_hour;
