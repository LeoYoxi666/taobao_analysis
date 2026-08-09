# Power BI Data Preparation

This folder contains read-only PostgreSQL queries and CSV extracts designed for
the Taobao User Behaviour Analysis dashboard. It does not change the database
schema or the existing Python analysis.

## Current Stage

Data preparation is complete: the five core exports have been generated from
the validated PostgreSQL analyses and passed the checks listed below. Power BI
dashboard creation is now in progress. Module 2 also has four additional
export queries ready to refresh before it is built. A finished report file is
not yet tracked in this repository.

## Folder Structure

```text
powerbi/
├── README.md
├── refresh_exports.ps1
├── queries/
│   ├── 01_user_behaviour_overview.sql
│   ├── 02_hourly_activity_trend.sql
│   ├── 03_purchase_funnel.sql
│   ├── 04_product_category_ranking.sql
│   └── 05_user_segmentation.sql
└── data/
    ├── user_behaviour_overview.csv
    ├── hourly_activity_trend.csv
    ├── purchase_funnel.csv
    ├── product_category_ranking.csv
    └── user_segmentation.csv
```

## Refresh the CSV Exports

The checked-in summary values are based on the verified SQL analysis report.
Run the refresh script when the SQL source changes or before validating a
dashboard release so all five CSV files—including the exact hourly values and
Top 10 item ranking—come directly from PostgreSQL.

From the project root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\powerbi\refresh_exports.ps1
```

The script:

- prompts once for the selected PostgreSQL user's password if `PGPASSWORD` is
  not already set;
- does not display or save the password;
- forces PostgreSQL transactions to be read-only;
- exports with PostgreSQL 17 `psql --csv`;
- validates the expected row count of every dataset;
- removes the temporary password environment variable after completion.

Optional connection parameters can be supplied when needed:

```powershell
.\powerbi\refresh_exports.ps1 `
    -DatabaseHost localhost `
    -Port 5432 `
    -Database taobao_analysis `
    -User postgres
```

Do not manually edit generated CSV values. Change the corresponding query and
refresh the exports so PostgreSQL remains the source of truth.

## Dashboard 1, Module 2 Exports

The four files below support the user behaviour timing and distribution module.
They are refreshed by the same script as the core exports and intentionally
remain independent aggregate tables.

| File | Rows | Purpose |
| --- | ---: | --- |
| `weekday_hour_behaviour.csv` | 672 | 7 weekdays x 24 hours x 4 behaviour types for the selectable activity heatmap |
| `weekday_hour_purchase_rate.csv` | 168 | 7 weekdays x 24 hours for the purchase-rate heatmap |
| `daily_behaviour_trend.csv` | 124 | 31 days x 4 behaviour types in the current snapshot for the daily combo chart |
| `user_activity_distribution.csv` | 22 | 14 logarithmic activity bins plus 8 purchase-frequency bins |

The rate in the weekday-hour and daily exports is `distinct purchasing users /
distinct viewing users` within the same time cell. It is a same-period
propensity indicator, not a chronological session-conversion funnel. See
[`module_2_build_guide.md`](module_2_build_guide.md) for the complete import,
measure, visual, and review instructions.

## Dataset and Visual Mapping

### `user_behaviour_overview.csv`

One row for each configured behaviour type.

| Column | Type | Meaning |
| --- | --- | --- |
| `behaviour_type` | Whole number | Stable code and display order: 1–4 |
| `behaviour_name` | Text | View, Favorite, Cart, or Purchase |
| `action_count` | Whole number | Number of event rows for the behaviour |
| `action_share` | Decimal number | Share of all events, stored from 0 to 1 |

Recommended Power BI visuals:

- Clustered bar chart: `behaviour_name` on Axis and `action_count` as Value.
- Donut chart: `behaviour_name` as Legend and `action_count` as Value.
- Card: Sum of `action_count` for the total number of events.

Format `action_share` as Percentage with two decimal places. Sort the behaviour
name by `behaviour_type` when the logical View-to-Purchase order is required.

### `hourly_activity_trend.csv`

Exactly 24 rows, one for each hour of the day.

| Column | Type | Meaning |
| --- | --- | --- |
| `activity_hour` | Whole number | Hour from 0 to 23 |
| `total_actions` | Whole number | All recorded actions during the hour |
| `purchase_actions` | Whole number | Purchase actions during the hour |

Recommended Power BI visual:

- Line and clustered column chart: `activity_hour` on the shared X-axis,
  `total_actions` as column values, and `purchase_actions` as line values.

The two measures have very different scales, so use a secondary Y-axis for
purchase actions. Sort ascending by `activity_hour` and display all 24 values.

### `purchase_funnel.csv`

Three chronological user-level stages in long form.

| Column | Type | Meaning |
| --- | --- | --- |
| `stage_order` | Whole number | Required funnel sort order |
| `stage_name` | Text | View, Cart after View, Purchase after Cart |
| `user_count` | Whole number | Users reaching the stage chronologically |
| `conversion_from_previous` | Decimal number | Conversion from the preceding stage |
| `conversion_from_view` | Decimal number | Cumulative conversion from View |

Recommended Power BI visuals:

- Funnel chart: `stage_name` as Category and `user_count` as Value.
- KPI cards: View-to-Cart, Cart-to-Purchase, and overall conversion.

Sort `stage_name` by `stage_order`. Format both conversion fields as Percentage
with two decimal places.

### `product_category_ranking.csv`

Top 10 purchased items and Top 10 purchased categories in one consistent table.

| Column | Type | Meaning |
| --- | --- | --- |
| `ranking_type` | Text | `Item` or `Category` |
| `purchase_rank` | Whole number | Rank within the selected type |
| `entity_id` | Text | Item or category identifier |
| `purchase_count` | Whole number | Purchase events for the identifier |

Recommended Power BI visuals:

- Horizontal bar chart: `entity_id` on the Y-axis and `purchase_count` on the
  X-axis.
- Slicer: `ranking_type`, allowing users to switch between items and categories.
- Table: `purchase_rank`, `entity_id`, and `purchase_count` for exact values.

Set `entity_id` to Text and choose **Do not summarize**. Sort the visual by
`purchase_count` descending or `purchase_rank` ascending.

### `user_segmentation.csv`

One row for each mutually exclusive user segment.

| Column | Type | Meaning |
| --- | --- | --- |
| `segment_order` | Whole number | Stable business display order |
| `user_segment` | Text | Segment label |
| `user_count` | Whole number | Users assigned to the segment |
| `user_share` | Decimal number | Share of all users, stored from 0 to 1 |

Recommended Power BI visuals:

- Clustered bar chart: `user_segment` on Axis and `user_count` as Value.
- Donut chart: `user_segment` as Legend and `user_count` as Value.
- Card: Sum of `user_count`, which should equal 10,000.

Sort `user_segment` by `segment_order`. Format `user_share` as Percentage with
two decimal places.

## Power BI Import Settings

Use **Get Data → Text/CSV** and import each file from `powerbi/data/`. These are
already aggregated dashboard tables, so Import mode is recommended.

After import:

1. Apply the data types listed above.
2. Store identifiers as Text rather than numeric measures.
3. Format share and conversion columns as percentages.
4. Configure the explicit sort columns before creating visuals.
5. Disable automatic relationships between these aggregate tables. They use
   different analytical grains and can be displayed independently.
6. Record the CSV refresh date in the dashboard subtitle or an information card.

## Suggested Dashboard Layout

1. **Overview:** total events, total users, behaviour distribution, and key
   conversion cards.
2. **Activity:** 24-hour total and purchase activity trend.
3. **Conversion:** chronological funnel and conversion KPI cards.
4. **Products:** item/category ranking with a type slicer.
5. **Users:** segment distribution and segment descriptions.

The dataset has no price field, product names, category names, or demographic
attributes. The dashboard should therefore avoid revenue claims and describe
items/categories using their identifiers.

## Current Snapshot Status

All five CSV datasets were refreshed directly from PostgreSQL on 5 August 2026
and passed the row-count and cross-dataset validation checks:

| Dataset | Rows | Validation |
| --- | ---: | --- |
| User behaviour overview | 4 | Actions total 12,256,906 |
| Hourly activity trend | 24 | Actions total 12,256,906; purchases total 120,205 |
| Purchase funnel | 3 | View users 10,000; final-stage users 7,517 |
| Product/category ranking | 20 | 10 items and 10 categories |
| User segmentation | 4 | Users total 10,000 |

The current local installation authenticates with the `postgres` role, so that
is the refresh script default. For a deployed dashboard, create a dedicated
read-only reporting role and pass its name with `-User` instead of using an
administrator account.
