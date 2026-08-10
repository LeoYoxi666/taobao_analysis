WITH user_activity AS (
    SELECT
        e.user_id,
        COUNT(*)::bigint AS total_actions
    FROM taobao.behaviour_events AS e
    GROUP BY e.user_id
),
activity_segments AS (
    SELECT
        ua.user_id,
        NTILE(3) OVER (ORDER BY ua.total_actions, ua.user_id) AS activity_segment_order
    FROM user_activity AS ua
),
segment_category AS (
    SELECT
        s.activity_segment_order,
        i.category_id,
        COUNT(*)::bigint AS interaction_count,
        COUNT(DISTINCT e.user_id)::bigint AS user_count
    FROM activity_segments AS s
    JOIN taobao.behaviour_events AS e
        ON e.user_id = s.user_id
    JOIN taobao.items AS i
        ON i.item_id = e.item_id
    GROUP BY
        s.activity_segment_order,
        i.category_id
),
segment_totals AS (
    SELECT
        activity_segment_order,
        SUM(interaction_count)::bigint AS segment_interactions
    FROM segment_category
    GROUP BY activity_segment_order
),
ranked AS (
    SELECT
        sc.*,
        ROW_NUMBER() OVER (
            PARTITION BY sc.activity_segment_order
            ORDER BY sc.interaction_count DESC, sc.category_id
        ) AS preference_rank
    FROM segment_category AS sc
)
SELECT
    r.activity_segment_order,
    CASE r.activity_segment_order
        WHEN 1 THEN 'Low Activity'
        WHEN 2 THEN 'Medium Activity'
        WHEN 3 THEN 'High Activity'
    END AS activity_segment,
    r.preference_rank,
    r.category_id::text AS category_id,
    r.interaction_count,
    r.user_count,
    ROUND(
        r.interaction_count::numeric / NULLIF(st.segment_interactions, 0),
        6
    ) AS interaction_share
FROM ranked AS r
JOIN segment_totals AS st
    ON st.activity_segment_order = r.activity_segment_order
WHERE r.preference_rank <= 5
ORDER BY
    r.activity_segment_order,
    r.preference_rank;
