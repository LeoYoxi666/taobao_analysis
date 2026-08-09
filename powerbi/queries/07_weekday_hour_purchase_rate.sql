-- Power BI dataset: weekday-by-hour purchase rate heatmap.
-- Rate = distinct purchasing users / distinct viewing users in the same
-- weekday-hour cell. It describes a time-cell propensity, not a chronological
-- session funnel; no session identifier exists in the source data.
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
hourly_users AS (
    SELECT
        EXTRACT(ISODOW FROM event_time)::INTEGER AS weekday_number,
        EXTRACT(HOUR FROM event_time)::INTEGER AS activity_hour,
        COUNT(DISTINCT user_id) FILTER (WHERE behaviour_type = 1)
            AS view_user_count,
        COUNT(DISTINCT user_id) FILTER (WHERE behaviour_type = 4)
            AS purchase_user_count
    FROM taobao.behaviour_events
    GROUP BY
        EXTRACT(ISODOW FROM event_time)::INTEGER,
        EXTRACT(HOUR FROM event_time)::INTEGER
)
SELECT
    weekday_hours.weekday_number,
    weekday_hours.weekday_name,
    weekday_hours.activity_hour,
    COALESCE(hourly_users.view_user_count, 0) AS view_user_count,
    COALESCE(hourly_users.purchase_user_count, 0) AS purchase_user_count,
    ROUND(
        COALESCE(hourly_users.purchase_user_count, 0)::NUMERIC
            / NULLIF(hourly_users.view_user_count, 0),
        6
    ) AS purchase_rate
FROM weekday_hours
LEFT JOIN hourly_users
    ON hourly_users.weekday_number = weekday_hours.weekday_number
   AND hourly_users.activity_hour = weekday_hours.activity_hour
ORDER BY weekday_hours.weekday_number, weekday_hours.activity_hour;
