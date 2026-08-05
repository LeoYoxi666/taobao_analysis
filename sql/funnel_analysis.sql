-- Chronological conversion funnel
-- This reproduces the existing Python rules exactly:
--   1. first view per user;
--   2. first cart strictly after that view;
--   3. first purchase strictly after that valid cart.
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
        (SELECT COUNT(*) FROM first_carts_after_view) AS cart_after_view_users,
        (SELECT COUNT(*) FROM first_purchases_after_cart) AS purchase_after_cart_users
)
SELECT
    view_users,
    cart_after_view_users,
    purchase_after_cart_users,
    ROUND(
        cart_after_view_users * 100.0 / NULLIF(view_users, 0),
        2
    ) AS view_to_cart_percentage,
    ROUND(
        purchase_after_cart_users * 100.0
            / NULLIF(cart_after_view_users, 0),
        2
    ) AS cart_to_purchase_percentage,
    ROUND(
        purchase_after_cart_users * 100.0 / NULLIF(view_users, 0),
        2
    ) AS overall_conversion_percentage
FROM funnel_counts;

-- Chronological purchase behaviour paths
-- Every purchase event is classified, not merely every user-item pair.
-- event_id breaks ties for identical timestamps and repeated behaviours are
-- retained. The CASE order matches the precedence in src/purchase_paths.py.
WITH purchase_pairs AS (
    SELECT DISTINCT user_id, item_id
    FROM taobao.behaviour_events
    WHERE behaviour_type = 4
),
eligible_events AS (
    SELECT
        events.event_id,
        events.event_time,
        events.user_id,
        events.item_id,
        events.behaviour_type,
        MAX(CASE WHEN events.behaviour_type = 1 THEN 1 ELSE 0 END) OVER (
            PARTITION BY events.user_id, events.item_id
            ORDER BY events.event_time, events.event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_view
    FROM taobao.behaviour_events AS events
    JOIN purchase_pairs
        ON purchase_pairs.user_id = events.user_id
       AND purchase_pairs.item_id = events.item_id
),
qualified_steps AS (
    SELECT
        *,
        CASE
            WHEN behaviour_type = 2 AND COALESCE(prior_view, 0) = 1
                THEN 1 ELSE 0
        END AS view_then_favorite,
        CASE
            WHEN behaviour_type = 3 AND COALESCE(prior_view, 0) = 1
                THEN 1 ELSE 0
        END AS view_then_cart
    FROM eligible_events
),
steps_with_prior_favorite AS (
    SELECT
        *,
        MAX(view_then_favorite) OVER (
            PARTITION BY user_id, item_id
            ORDER BY event_time, event_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS prior_view_then_favorite
    FROM qualified_steps
),
extended_steps AS (
    SELECT
        *,
        CASE
            WHEN behaviour_type = 3
             AND COALESCE(prior_view_then_favorite, 0) = 1
                THEN 1 ELSE 0
        END AS view_then_favorite_then_cart
    FROM steps_with_prior_favorite
),
purchase_states AS (
    SELECT
        *,
        MAX(view_then_favorite) OVER path_history AS prior_favorite_path,
        MAX(view_then_cart) OVER path_history AS prior_cart_path,
        MAX(view_then_favorite_then_cart) OVER path_history
            AS prior_favorite_cart_path
    FROM extended_steps
    WINDOW path_history AS (
        PARTITION BY user_id, item_id
        ORDER BY event_time, event_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    )
),
classified_purchases AS (
    SELECT
        CASE
            WHEN COALESCE(prior_favorite_cart_path, 0) = 1
                THEN 'View -> Favorite -> Cart -> Purchase'
            WHEN COALESCE(prior_cart_path, 0) = 1
                THEN 'View -> Cart -> Purchase'
            WHEN COALESCE(prior_favorite_path, 0) = 1
                THEN 'View -> Favorite -> Purchase'
            WHEN COALESCE(prior_view, 0) = 1
                THEN 'View -> Purchase'
            ELSE 'Other'
        END AS path_type
    FROM purchase_states
    WHERE behaviour_type = 4
),
path_order AS (
    SELECT *
    FROM (
        VALUES
            (1, 'View -> Purchase'),
            (2, 'View -> Cart -> Purchase'),
            (3, 'View -> Favorite -> Purchase'),
            (4, 'View -> Favorite -> Cart -> Purchase'),
            (5, 'Other')
    ) AS paths(sort_order, path_type)
),
path_counts AS (
    SELECT path_type, COUNT(*) AS purchase_count
    FROM classified_purchases
    GROUP BY path_type
)
SELECT
    path_order.path_type,
    COALESCE(path_counts.purchase_count, 0) AS purchase_count,
    ROUND(
        COALESCE(path_counts.purchase_count, 0) * 100.0
            / NULLIF(SUM(COALESCE(path_counts.purchase_count, 0)) OVER (), 0),
        2
    ) AS percentage_of_purchases
FROM path_order
LEFT JOIN path_counts USING (path_type)
ORDER BY path_order.sort_order;
