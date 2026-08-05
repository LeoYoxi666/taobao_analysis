-- Power BI dataset: 24-hour activity and purchase trend.
-- All hours are returned even if no events occurred during an hour.
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
