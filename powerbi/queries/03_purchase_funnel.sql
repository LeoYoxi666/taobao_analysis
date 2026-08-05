-- Power BI dataset: chronological user funnel in long/table form.
-- Long form can be used directly by a Power BI Funnel visual.
WITH first_views AS (
    SELECT user_id, MIN(event_time) AS view_time
    FROM taobao.behaviour_events
    WHERE behaviour_type = 1
    GROUP BY user_id
),
first_carts_after_view AS (
    SELECT events.user_id, MIN(events.event_time) AS cart_time
    FROM taobao.behaviour_events AS events
    JOIN first_views
        ON first_views.user_id = events.user_id
       AND events.event_time > first_views.view_time
    WHERE events.behaviour_type = 3
    GROUP BY events.user_id
),
first_purchases_after_cart AS (
    SELECT events.user_id, MIN(events.event_time) AS purchase_time
    FROM taobao.behaviour_events AS events
    JOIN first_carts_after_view AS carts
        ON carts.user_id = events.user_id
       AND events.event_time > carts.cart_time
    WHERE events.behaviour_type = 4
    GROUP BY events.user_id
),
funnel_counts AS (
    SELECT
        (SELECT COUNT(*) FROM first_views) AS view_users,
        (SELECT COUNT(*) FROM first_carts_after_view)
            AS cart_after_view_users,
        (SELECT COUNT(*) FROM first_purchases_after_cart)
            AS purchase_after_cart_users
),
funnel_stages AS (
    SELECT
        1 AS stage_order,
        'View'::TEXT AS stage_name,
        view_users AS user_count,
        1.0::NUMERIC AS conversion_from_previous,
        1.0::NUMERIC AS conversion_from_view
    FROM funnel_counts

    UNION ALL

    SELECT
        2,
        'Cart after View',
        cart_after_view_users,
        cart_after_view_users::NUMERIC / NULLIF(view_users, 0),
        cart_after_view_users::NUMERIC / NULLIF(view_users, 0)
    FROM funnel_counts

    UNION ALL

    SELECT
        3,
        'Purchase after Cart',
        purchase_after_cart_users,
        purchase_after_cart_users::NUMERIC
            / NULLIF(cart_after_view_users, 0),
        purchase_after_cart_users::NUMERIC / NULLIF(view_users, 0)
    FROM funnel_counts
)
SELECT
    stage_order,
    stage_name,
    user_count,
    ROUND(conversion_from_previous, 6) AS conversion_from_previous,
    ROUND(conversion_from_view, 6) AS conversion_from_view
FROM funnel_stages
ORDER BY stage_order;
