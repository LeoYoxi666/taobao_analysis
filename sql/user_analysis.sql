-- User-level summary
-- Produces the same six metrics as src/user_segmentation.py before segment
-- assignment. FILTER performs the per-behaviour conditional counts.
SELECT
    user_id,
    COUNT(*) AS total_actions,
    COUNT(*) FILTER (WHERE behaviour_type = 1) AS view_count,
    COUNT(*) FILTER (WHERE behaviour_type = 2) AS favorite_count,
    COUNT(*) FILTER (WHERE behaviour_type = 3) AS cart_count,
    COUNT(*) FILTER (WHERE behaviour_type = 4) AS purchase_count,
    COUNT(DISTINCT event_time::DATE) AS active_days
FROM taobao.behaviour_events
GROUP BY user_id
ORDER BY user_id;

-- Percentile-based user segmentation
-- percentile_cont implements the continuous 80th-percentile thresholds used
-- by pandas. Segment CASE clauses follow the existing priority order:
-- High-Frequency Buyer, No Purchase, High Activity Low Purchase, Regular Buyer.
WITH user_summary AS (
    SELECT
        user_id,
        COUNT(*) AS total_actions,
        COUNT(*) FILTER (WHERE behaviour_type = 1) AS view_count,
        COUNT(*) FILTER (WHERE behaviour_type = 2) AS favorite_count,
        COUNT(*) FILTER (WHERE behaviour_type = 3) AS cart_count,
        COUNT(*) FILTER (WHERE behaviour_type = 4) AS purchase_count,
        COUNT(DISTINCT event_time::DATE) AS active_days
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
        user_summary.*,
        thresholds.high_activity_threshold,
        thresholds.high_purchase_threshold,
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
    ) AS segments(sort_order, user_segment)
),
segment_counts AS (
    SELECT user_segment, COUNT(*) AS user_count
    FROM classified_users
    GROUP BY user_segment
),
summary_totals AS (
    SELECT
        COUNT(*) AS total_users,
        MAX(high_activity_threshold) AS high_activity_threshold,
        MAX(high_purchase_threshold) AS high_purchase_threshold
    FROM classified_users
)
SELECT
    segment_order.sort_order AS segment_order,
    segment_order.user_segment,
    COALESCE(segment_counts.user_count, 0) AS user_count,
    ROUND(
        COALESCE(segment_counts.user_count, 0) * 100.0
            / NULLIF(summary_totals.total_users, 0),
        2
    ) AS percentage_of_users,
    summary_totals.high_activity_threshold,
    summary_totals.high_purchase_threshold,
    summary_totals.total_users,
    SUM(COALESCE(segment_counts.user_count, 0)) OVER ()
        AS classified_user_total
FROM segment_order
CROSS JOIN summary_totals
LEFT JOIN segment_counts USING (user_segment)
ORDER BY segment_order.sort_order;

-- The total_users and classified_user_total columns must be equal. The four
-- unrounded segment percentages are defined from the same total and therefore
-- sum to 100% whenever at least one user exists.
