# Power BI Dashboard Data Layer

This folder contains the read-only PostgreSQL export queries, validated CSV
outputs, refresh script, and build guides used by the Taobao dashboard. The
queries do not change the database schema or source data.

## Current status

- 12 query-backed CSV datasets are available in `powerbi/data/`.
- Dashboard 1 Module 2 and Module 4 are built in a local Power BI report.
- The local PBIX is kept outside the repository; the eight page screenshots
  and analysis are included in `../docs/项目分析报告.md`.
- The dashboard has not been published from this repository.

## Folder structure

```text
powerbi/
|-- README.md
|-- refresh_exports.ps1
|-- module_2_build_guide.md
|-- module_4_build_guide.md
|-- queries/                 # 01-12 read-only PostgreSQL queries
`-- data/                    # 12 validated CSV exports
```

## Refresh all exports

From the project root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\powerbi\refresh_exports.ps1
```

The script prompts once for the PostgreSQL password when `PGPASSWORD` is not
set, forces queries into read-only mode, writes to temporary files, validates
row counts, and only then replaces the published CSVs. It removes temporary
credentials and files on completion.

Optional connection parameters:

```powershell
.\powerbi\refresh_exports.ps1 `
    -DatabaseHost localhost `
    -Port 5432 `
    -Database taobao_analysis `
    -User postgres
```

Do not manually edit generated CSV values. Update the corresponding SQL query
and rerun the script so PostgreSQL remains the source of truth.

## Export inventory

| Group | CSV | Rows | Purpose |
| --- | --- | ---: | --- |
| Core | `user_behaviour_overview.csv` | 4 | Behaviour totals and shares |
| Core | `hourly_activity_trend.csv` | 24 | Hourly actions and purchases |
| Core | `purchase_funnel.csv` | 3 | Chronological user funnel |
| Core | `product_category_ranking.csv` | 20 | Top items and categories |
| Core | `user_segmentation.csv` | 4 | Mutually exclusive user segments |
| Module 2 | `weekday_hour_behaviour.csv` | 672 | Weekday-hour behaviour heatmap |
| Module 2 | `weekday_hour_purchase_rate.csv` | 168 | Weekday-hour purchase-rate heatmap |
| Module 2 | `daily_behaviour_trend.csv` | 124 | Daily actions and purchase rate |
| Module 2 | `user_activity_distribution.csv` | 22 | Activity and purchase-frequency bins |
| Module 4 | `behaviour_transition_matrix.csv` | 20 | Current-to-next behaviour probabilities |
| Module 4 | `behaviour_depth_conversion.csv` | 24 | Behaviour depth and user purchase rate |
| Module 4 | `activity_category_preference.csv` | 15 | Top 5 categories by activity tier |

## Power BI import rules

Use **主页 → 获取数据 → 文本/CSV** and Import mode. The exports have different
grains, so keep them independent unless a deliberate model redesign is made.
Remove automatically detected relationships.

Apply these sort columns:

| Display column | Sort column |
| --- | --- |
| `behaviour_name` | `behaviour_type` |
| `stage_name` | `stage_order` |
| `weekday_name` | `weekday_number` |
| `bin_label` | `bin_order` |
| `current_behaviour_name` | `current_behaviour_order` |
| `next_action_name` | `next_action_order` |
| `depth_bin_label` | `depth_bin_order` |
| `activity_segment` | `activity_segment_order` |

Format share, rate, conversion, and probability columns as Percentage with two
decimal places. Treat item and category identifiers as labels rather than
measures. In table visuals, use **不汇总** for rank and identifier columns.

## Completed dashboard pages

Module 2:

1. `模块二-用户行为时段与购买率热力分析`
2. `模块二-每日行为趋势与购买率`
3. `模块二-用户活跃度分布与购买率`
4. `模块二-用户购买次数分布（复购结构）`

Module 4:

1. `模块四-购买转化漏斗`
2. `模块四-行为路径`
3. `模块四-行为深度`
4. `模块四-品类偏好`

Detailed field placement and review checks are in
[`module_2_build_guide.md`](module_2_build_guide.md) and
[`module_4_build_guide.md`](module_4_build_guide.md).

The final screenshots, findings, and business interpretation are in the
[`project analysis report`](../docs/项目分析报告.md).

## Metric cautions

- Weekday-hour and daily purchase rates are purchasing users divided by
  viewing users in the same time cell; they are not chronological funnels.
- The funnel requires View, then a later Cart, then a later Purchase.
- Transition `Exit` means the last observed event for a user, not a session
  exit.
- The dataset has no product or category names, prices, quantities,
  demographics, campaign attributes, or session identifier.
