-- Power BI dataset: current-to-next behaviour transition matrix.
-- Exit means the final observed event for a user, not a session-level exit.
WITH sequenced_events AS (
    SELECT
        e.user_id,
        e.event_id,
        e.event_time,
        e.behaviour_type AS current_behaviour_type,
        LEAD(e.behaviour_type) OVER (
            PARTITION BY e.user_id
            ORDER BY e.event_time, e.event_id
        ) AS next_behaviour_type
    FROM taobao.behaviour_events AS e
),
transition_counts AS (
    SELECT
        current_behaviour_type,
        COALESCE(next_behaviour_type, 5) AS next_action_order,
        COUNT(*)::bigint AS transition_count
    FROM sequenced_events
    GROUP BY
        current_behaviour_type,
        COALESCE(next_behaviour_type, 5)
),
current_totals AS (
    SELECT
        current_behaviour_type,
        SUM(transition_count)::bigint AS current_total
    FROM transition_counts
    GROUP BY current_behaviour_type
),
next_actions AS (
    SELECT *
    FROM (VALUES
        (1, 'View'),
        (2, 'Favorite'),
        (3, 'Cart'),
        (4, 'Purchase'),
        (5, 'Exit')
    ) AS actions(next_action_order, next_action_name)
)
SELECT
    bt.behaviour_type AS current_behaviour_order,
    bt.behaviour_name AS current_behaviour_name,
    na.next_action_order,
    na.next_action_name,
    COALESCE(tc.transition_count, 0)::bigint AS transition_count,
    ROUND(
        COALESCE(tc.transition_count, 0)::numeric
        / NULLIF(ct.current_total, 0),
        6
    ) AS transition_probability
FROM taobao.behaviour_types AS bt
CROSS JOIN next_actions AS na
LEFT JOIN transition_counts AS tc
    ON tc.current_behaviour_type = bt.behaviour_type
   AND tc.next_action_order = na.next_action_order
LEFT JOIN current_totals AS ct
    ON ct.current_behaviour_type = bt.behaviour_type
ORDER BY
    bt.behaviour_type,
    na.next_action_order;
