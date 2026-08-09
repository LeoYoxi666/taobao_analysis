-- Power BI dataset: fixed logarithmic activity buckets and purchase-frequency
-- buckets. Fixed bins retain zero-count intervals and work reliably in Power BI.
WITH user_summary AS (
    SELECT
        users.user_id,
        COUNT(events.event_id) AS total_actions,
        COUNT(events.event_id) FILTER (WHERE events.behaviour_type = 4)
            AS purchase_count
    FROM taobao.users AS users
    LEFT JOIN taobao.behaviour_events AS events
        ON events.user_id = users.user_id
    GROUP BY users.user_id
),
total_users AS (
    SELECT COUNT(*) AS user_count
    FROM user_summary
),
activity_buckets AS (
    SELECT *
    FROM (
        VALUES
            (1, '1', 1::BIGINT, 2::BIGINT),
            (2, '2-3', 2, 4),
            (3, '4-7', 4, 8),
            (4, '8-15', 8, 16),
            (5, '16-31', 16, 32),
            (6, '32-63', 32, 64),
            (7, '64-127', 64, 128),
            (8, '128-255', 128, 256),
            (9, '256-511', 256, 512),
            (10, '512-1,023', 512, 1024),
            (11, '1,024-2,047', 1024, 2048),
            (12, '2,048-4,095', 2048, 4096),
            (13, '4,096-8,191', 4096, 8192),
            (14, '8,192+', 8192, NULL::BIGINT)
    ) AS buckets(bin_order, bin_label, lower_bound, upper_bound)
),
purchase_buckets AS (
    SELECT *
    FROM (
        VALUES
            (1, '0', 0::BIGINT, 1::BIGINT),
            (2, '1', 1, 2),
            (3, '2-3', 2, 4),
            (4, '4-7', 4, 8),
            (5, '8-15', 8, 16),
            (6, '16-31', 16, 32),
            (7, '32-63', 32, 64),
            (8, '64+', 64, NULL::BIGINT)
    ) AS buckets(bin_order, bin_label, lower_bound, upper_bound)
),
activity_results AS (
    SELECT
        1 AS distribution_order,
        'Activity'::TEXT AS distribution_type,
        activity_buckets.bin_order,
        activity_buckets.bin_label,
        COUNT(user_summary.user_id) AS user_count,
        ROUND(
            COUNT(user_summary.user_id)::NUMERIC
                / NULLIF(total_users.user_count, 0),
            6
        ) AS user_share,
        ROUND(
            COUNT(user_summary.user_id) FILTER (WHERE user_summary.purchase_count > 0)
                ::NUMERIC / NULLIF(COUNT(user_summary.user_id), 0),
            6
        ) AS purchase_rate
    FROM activity_buckets
    CROSS JOIN total_users
    LEFT JOIN user_summary
        ON user_summary.total_actions >= activity_buckets.lower_bound
       AND (
            activity_buckets.upper_bound IS NULL
            OR user_summary.total_actions < activity_buckets.upper_bound
       )
    GROUP BY
        activity_buckets.bin_order,
        activity_buckets.bin_label,
        total_users.user_count
),
purchase_results AS (
    SELECT
        2 AS distribution_order,
        'Purchase Frequency'::TEXT AS distribution_type,
        purchase_buckets.bin_order,
        purchase_buckets.bin_label,
        COUNT(user_summary.user_id) AS user_count,
        ROUND(
            COUNT(user_summary.user_id)::NUMERIC
                / NULLIF(total_users.user_count, 0),
            6
        ) AS user_share,
        NULL::NUMERIC AS purchase_rate
    FROM purchase_buckets
    CROSS JOIN total_users
    LEFT JOIN user_summary
        ON user_summary.purchase_count >= purchase_buckets.lower_bound
       AND (
            purchase_buckets.upper_bound IS NULL
            OR user_summary.purchase_count < purchase_buckets.upper_bound
       )
    GROUP BY
        purchase_buckets.bin_order,
        purchase_buckets.bin_label,
        total_users.user_count
)
SELECT
    distribution_order,
    distribution_type,
    bin_order,
    bin_label,
    user_count,
    user_share,
    purchase_rate
FROM activity_results
UNION ALL
SELECT
    distribution_order,
    distribution_type,
    bin_order,
    bin_label,
    user_count,
    user_share,
    purchase_rate
FROM purchase_results
ORDER BY distribution_order, bin_order;
