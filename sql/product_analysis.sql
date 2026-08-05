-- Top purchased items
-- Behaviour type 4 is Purchase, matching PURCHASE_BEHAVIOR in src/config.py.
SELECT
    item_id,
    COUNT(*) AS purchase_count
FROM taobao.behaviour_events
WHERE behaviour_type = 4
GROUP BY item_id
ORDER BY purchase_count DESC, item_id
LIMIT 10;

-- Top purchased categories
-- Category is obtained through the normalized item-to-category relationship.
SELECT
    items.category_id,
    COUNT(*) AS purchase_count
FROM taobao.behaviour_events AS events
JOIN taobao.items AS items
    ON items.item_id = events.item_id
WHERE events.behaviour_type = 4
GROUP BY items.category_id
ORDER BY purchase_count DESC, items.category_id
LIMIT 10;
