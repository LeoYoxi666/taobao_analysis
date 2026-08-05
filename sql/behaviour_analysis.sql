-- Behaviour distribution
-- Counts all event rows by behaviour code, matching pandas value_counts().
SELECT
    events.behaviour_type,
    types.behaviour_name,
    COUNT(*) AS action_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_actions
FROM taobao.behaviour_events AS events
JOIN taobao.behaviour_types AS types
    ON types.behaviour_type = events.behaviour_type
GROUP BY events.behaviour_type, types.behaviour_name
ORDER BY action_count DESC, events.behaviour_type;

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
