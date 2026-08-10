WITH user_behaviour_summary AS (
    SELECT
        e.user_id,
        COUNT(*) FILTER (WHERE e.behaviour_type = 1)::integer AS view_count,
        COUNT(*) FILTER (WHERE e.behaviour_type = 2)::integer AS favorite_count,
        COUNT(*) FILTER (WHERE e.behaviour_type = 3)::integer AS cart_count,
        COUNT(*) FILTER (WHERE e.behaviour_type = 4)::integer AS purchase_count
    FROM taobao.behaviour_events AS e
    GROUP BY e.user_id
),
behaviour_depth AS (
    SELECT
        s.user_id,
        v.behaviour_type,
        v.behaviour_name,
        v.behaviour_count,
        (s.purchase_count > 0) AS purchased
    FROM user_behaviour_summary AS s
    CROSS JOIN LATERAL (VALUES
        (1, 'View', s.view_count),
        (2, 'Favorite', s.favorite_count),
        (3, 'Cart', s.cart_count)
    ) AS v(behaviour_type, behaviour_name, behaviour_count)
),
depth_bins AS (
    SELECT *
    FROM (VALUES
        (1, '0',     0,          0),
        (2, '1',     1,          1),
        (3, '2-3',   2,          3),
        (4, '4-7',   4,          7),
        (5, '8-15',  8,         15),
        (6, '16-31', 16,        31),
        (7, '32-63', 32,        63),
        (8, '64+',   64, 2147483647)
    ) AS bins(depth_bin_order, depth_bin_label, minimum_count, maximum_count)
),
behaviours AS (
    SELECT *
    FROM (VALUES
        (1, 'View'),
        (2, 'Favorite'),
        (3, 'Cart')
    ) AS b(behaviour_type, behaviour_name)
),
aggregated AS (
    SELECT
        bd.behaviour_type,
        db.depth_bin_order,
        COUNT(*)::bigint AS user_count,
        COUNT(*) FILTER (WHERE bd.purchased)::bigint AS purchase_user_count
    FROM behaviour_depth AS bd
    JOIN depth_bins AS db
        ON bd.behaviour_count BETWEEN db.minimum_count AND db.maximum_count
    GROUP BY
        bd.behaviour_type,
        db.depth_bin_order
)
SELECT
    b.behaviour_type,
    b.behaviour_name,
    db.depth_bin_order,
    db.depth_bin_label,
    COALESCE(a.user_count, 0)::bigint AS user_count,
    COALESCE(a.purchase_user_count, 0)::bigint AS purchase_user_count,
    ROUND(
        COALESCE(a.purchase_user_count, 0)::numeric
        / NULLIF(a.user_count, 0),
        6
    ) AS purchase_rate
FROM behaviours AS b
CROSS JOIN depth_bins AS db
LEFT JOIN aggregated AS a
    ON a.behaviour_type = b.behaviour_type
   AND a.depth_bin_order = db.depth_bin_order
ORDER BY
    b.behaviour_type,
    db.depth_bin_order;
