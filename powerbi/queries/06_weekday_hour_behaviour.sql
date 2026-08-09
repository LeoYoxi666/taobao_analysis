-- Power BI dataset: weekday-by-hour behaviour activity heatmap.
-- The result includes every weekday, hour, and behaviour combination so
-- zero-activity cells remain visible in a Power BI matrix.
WITH weekday_hours AS (
    SELECT
        weekday_number,
        CASE weekday_number
            WHEN 1 THEN 'Monday'
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
            WHEN 7 THEN 'Sunday'
        END AS weekday_name,
        activity_hour
    FROM generate_series(1, 7) AS weekdays(weekday_number)
    CROSS JOIN generate_series(0, 23) AS hours(activity_hour)
),
behaviour_counts AS (
    SELECT
        EXTRACT(ISODOW FROM event_time)::INTEGER AS weekday_number,
        EXTRACT(HOUR FROM event_time)::INTEGER AS activity_hour,
        behaviour_type,
        COUNT(*) AS action_count
    FROM taobao.behaviour_events
    GROUP BY
        EXTRACT(ISODOW FROM event_time)::INTEGER,
        EXTRACT(HOUR FROM event_time)::INTEGER,
        behaviour_type
)
SELECT
    weekday_hours.weekday_number,
    weekday_hours.weekday_name,
    weekday_hours.activity_hour,
    behaviour_types.behaviour_type,
    behaviour_types.behaviour_name,
    COALESCE(behaviour_counts.action_count, 0) AS action_count
FROM weekday_hours
CROSS JOIN taobao.behaviour_types AS behaviour_types
LEFT JOIN behaviour_counts
    ON behaviour_counts.weekday_number = weekday_hours.weekday_number
   AND behaviour_counts.activity_hour = weekday_hours.activity_hour
   AND behaviour_counts.behaviour_type = behaviour_types.behaviour_type
ORDER BY
    weekday_hours.weekday_number,
    weekday_hours.activity_hour,
    behaviour_types.behaviour_type;
