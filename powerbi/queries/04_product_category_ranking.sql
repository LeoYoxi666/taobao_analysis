-- Power BI dataset: Top 10 purchased items and Top 10 categories.
-- entity_id is exported as text so Power BI treats identifiers as labels.
WITH item_counts AS (
    SELECT item_id, COUNT(*) AS purchase_count
    FROM taobao.behaviour_events
    WHERE behaviour_type = 4
    GROUP BY item_id
),
top_items AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY purchase_count DESC, item_id
        ) AS purchase_rank,
        item_id::TEXT AS entity_id,
        purchase_count
    FROM item_counts
    ORDER BY purchase_count DESC, item_id
    LIMIT 10
),
category_counts AS (
    SELECT items.category_id, COUNT(*) AS purchase_count
    FROM taobao.behaviour_events AS events
    JOIN taobao.items AS items
        ON items.item_id = events.item_id
    WHERE events.behaviour_type = 4
    GROUP BY items.category_id
),
top_categories AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY purchase_count DESC, category_id
        ) AS purchase_rank,
        category_id::TEXT AS entity_id,
        purchase_count
    FROM category_counts
    ORDER BY purchase_count DESC, category_id
    LIMIT 10
)
SELECT
    'Item'::TEXT AS ranking_type,
    purchase_rank,
    entity_id,
    purchase_count
FROM top_items

UNION ALL

SELECT
    'Category',
    purchase_rank,
    entity_id,
    purchase_count
FROM top_categories
ORDER BY ranking_type, purchase_rank;
