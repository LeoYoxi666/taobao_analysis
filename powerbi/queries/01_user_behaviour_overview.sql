-- Power BI dataset: user behaviour overview.
-- action_share is a decimal fraction so Power BI can format it as Percentage.
WITH behaviour_counts AS (
    SELECT behaviour_type, COUNT(*) AS action_count
    FROM taobao.behaviour_events
    GROUP BY behaviour_type
)
SELECT
    types.behaviour_type,
    types.behaviour_name,
    COALESCE(behaviour_counts.action_count, 0) AS action_count,
    ROUND(
        COALESCE(behaviour_counts.action_count, 0)::NUMERIC
            / NULLIF(
                SUM(COALESCE(behaviour_counts.action_count, 0)) OVER (),
                0
            ),
        6
    ) AS action_share
FROM taobao.behaviour_types AS types
LEFT JOIN behaviour_counts
    ON behaviour_counts.behaviour_type = types.behaviour_type
ORDER BY types.behaviour_type;
