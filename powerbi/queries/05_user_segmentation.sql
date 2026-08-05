-- Power BI dataset: mutually exclusive user segment distribution.
-- user_share is a decimal fraction for Power BI percentage formatting.
WITH user_summary AS (
    SELECT
        user_id,
        COUNT(*) AS total_actions,
        COUNT(*) FILTER (WHERE behaviour_type = 4) AS purchase_count
    FROM taobao.behaviour_events
    GROUP BY user_id
),
thresholds AS (
    SELECT
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY total_actions)
            AS high_activity_threshold,
        PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY purchase_count)
            FILTER (WHERE purchase_count > 0)
            AS high_purchase_threshold
    FROM user_summary
),
classified_users AS (
    SELECT
        CASE
            WHEN purchase_count >= thresholds.high_purchase_threshold
                THEN 'High-Frequency Buyer'
            WHEN purchase_count = 0
                THEN 'No Purchase'
            WHEN purchase_count > 0
             AND purchase_count < thresholds.high_purchase_threshold
             AND total_actions >= thresholds.high_activity_threshold
                THEN 'High Activity Low Purchase'
            ELSE 'Regular Buyer'
        END AS user_segment
    FROM user_summary
    CROSS JOIN thresholds
),
segment_order AS (
    SELECT *
    FROM (
        VALUES
            (1, 'High-Frequency Buyer'),
            (2, 'No Purchase'),
            (3, 'High Activity Low Purchase'),
            (4, 'Regular Buyer')
    ) AS segments(segment_order, user_segment)
),
segment_counts AS (
    SELECT user_segment, COUNT(*) AS user_count
    FROM classified_users
    GROUP BY user_segment
),
total_users AS (
    SELECT COUNT(*) AS user_count
    FROM user_summary
)
SELECT
    segment_order.segment_order,
    segment_order.user_segment,
    COALESCE(segment_counts.user_count, 0) AS user_count,
    ROUND(
        COALESCE(segment_counts.user_count, 0)::NUMERIC
            / NULLIF(total_users.user_count, 0),
        6
    ) AS user_share
FROM segment_order
CROSS JOIN total_users
LEFT JOIN segment_counts USING (user_segment)
ORDER BY segment_order.segment_order;
