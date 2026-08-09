-- Power BI dataset: daily behaviour trend and daily purchase rate.
-- purchase_rate is distinct purchasing users / distinct viewing users on the
-- same date. It is repeated on the four behaviour rows for use in a combo
-- visual, not a chronological session-conversion metric.
WITH date_bounds AS (
    SELECT
        MIN(event_time)::DATE AS first_date,
        MAX(event_time)::DATE AS last_date
    FROM taobao.behaviour_events
),
calendar AS (
    SELECT activity_date::DATE AS activity_date
    FROM date_bounds
    CROSS JOIN LATERAL generate_series(
        first_date,
        last_date,
        INTERVAL '1 day'
    ) AS calendar_dates(activity_date)
),
daily_behaviour_counts AS (
    SELECT
        event_time::DATE AS activity_date,
        behaviour_type,
        COUNT(*) AS action_count
    FROM taobao.behaviour_events
    GROUP BY event_time::DATE, behaviour_type
),
daily_user_counts AS (
    SELECT
        event_time::DATE AS activity_date,
        COUNT(DISTINCT user_id) FILTER (WHERE behaviour_type = 1)
            AS view_user_count,
        COUNT(DISTINCT user_id) FILTER (WHERE behaviour_type = 4)
            AS purchase_user_count
    FROM taobao.behaviour_events
    GROUP BY event_time::DATE
)
SELECT
    calendar.activity_date,
    EXTRACT(ISODOW FROM calendar.activity_date)::INTEGER AS weekday_number,
    CASE
        WHEN EXTRACT(ISODOW FROM calendar.activity_date) IN (6, 7)
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    behaviour_types.behaviour_type,
    behaviour_types.behaviour_name,
    COALESCE(daily_behaviour_counts.action_count, 0) AS action_count,
    COALESCE(daily_user_counts.view_user_count, 0) AS view_user_count,
    COALESCE(daily_user_counts.purchase_user_count, 0) AS purchase_user_count,
    ROUND(
        COALESCE(daily_user_counts.purchase_user_count, 0)::NUMERIC
            / NULLIF(daily_user_counts.view_user_count, 0),
        6
    ) AS purchase_rate
FROM calendar
CROSS JOIN taobao.behaviour_types AS behaviour_types
LEFT JOIN daily_behaviour_counts
    ON daily_behaviour_counts.activity_date = calendar.activity_date
   AND daily_behaviour_counts.behaviour_type = behaviour_types.behaviour_type
LEFT JOIN daily_user_counts
    ON daily_user_counts.activity_date = calendar.activity_date
ORDER BY calendar.activity_date, behaviour_types.behaviour_type;
