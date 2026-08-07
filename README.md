# Taobao User Behaviour Analysis

## Overview

This project analyzes 12.26 million Taobao user-behaviour events with Python,
PostgreSQL, and Power BI. The Python analysis, data-quality checks,
visualizations, PostgreSQL database, full CSV import, SQL analyses, and Power BI
data exports are complete. Power BI dashboard creation is currently in
progress.

## Project Status

| Stage | Status |
| --- | --- |
| Python analysis, cleaning, and visualization | Complete |
| PostgreSQL schema and full-data import | Complete |
| Behaviour, funnel, product/category, and user SQL analysis | Complete |
| SQL validation and final analysis report | Complete |
| Power BI query and CSV export layer | Complete |
| Power BI dashboard | In progress |

The complete SQL findings are in
[`docs/sql_analysis_results.md`](docs/sql_analysis_results.md). Dashboard field
definitions and visual guidance are in
[`powerbi/README.md`](powerbi/README.md).

## Dataset

The processed dataset contains:

- 12,256,906 event records
- 10,000 users
- 2,876,947 items
- 8,916 categories

Columns:

- `time`
- `user_id`
- `item_id`
- `item_category`
- `behavior_type`

Behaviour codes are `1 = View`, `2 = Favorite`, `3 = Cart`, and
`4 = Purchase`.

The local CSV is approximately 492 MB and is excluded from version control.
Avoid loading it unless full-data analysis is intentionally required.

## Implemented Analysis

- Dataset summary and data-quality checks
- Behaviour distribution
- Purchased item and category rankings
- Chronological conversion funnel
- Hourly activity and purchase trends
- Purchase behaviour paths
- Percentile-based user segmentation

Python and SQL implementations use the same established rules. SQL outputs were
validated against the Python baseline, and duplicate source rows were retained
consistently in both workflows.

## Repository Structure

```text
src/        Python processing, analysis, segmentation, and visualization
tests/      Automated tests using small mock DataFrames
sql/        PostgreSQL schema, controlled import, and analysis queries
database/   Database architecture and operational guidance
docs/       Final SQL report and generated charts
powerbi/    Dashboard queries, validated CSV exports, and refresh script
notebooks/  Presentation notebook
```

For durable project assumptions and the current development stage, see
[`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md).

## Python Environment

From the project root:

```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
```

Run the analysis workflow:

```powershell
python -m src.main
```

Run the lightweight automated tests without loading the full CSV:

```powershell
python -m pytest -q
```

## PostgreSQL Layer

PostgreSQL 17 is set up, the normalized tables have been created, and the full
CSV has been imported into `taobao_analysis`. The completed SQL analyses cover:

- behaviour distribution and hourly activity;
- chronological funnel and purchase paths;
- purchased item and category rankings;
- user metrics and segmentation.

Database architecture, safe rebuild/import commands, expected validation
totals, and query execution commands are maintained in
[`database/README.md`](database/README.md).

## Power BI Dashboard

The database results have been exported into five dashboard-ready aggregate
tables in `powerbi/data/`:

- user behaviour overview
- hourly activity trend
- purchase funnel
- product/category ranking
- user segmentation

Dashboard creation is the active project stage. Use Import mode, apply the
documented data types and sort columns, and keep the aggregate tables
independent because they have different grains. Refresh exports from PostgreSQL
with:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\powerbi\refresh_exports.ps1
```

Do not manually edit generated CSV values. Full refresh, field, visual, and
layout instructions are in [`powerbi/README.md`](powerbi/README.md).

## Analysis Outputs

- [`docs/sql_analysis_results.md`](docs/sql_analysis_results.md): final SQL
  analysis, validation, interpretation, and limitations
- `docs/behavior_distribution.png`
- `docs/hourly_behavior_trend.png`
- `docs/purchase_behavior_paths.png`
- `docs/top10_purchased_categories.png`
- `docs/user_funnel.png`
- `docs/user_segmentation.png`

## Limitations

- Duplicate records remain pending a separate source-quality decision.
- The dataset has no price or quantity fields, so revenue and average order
  value cannot be calculated.
- Product and category names are unavailable; rankings use identifiers only.
- Demographic and campaign attributes are unavailable.
- Funnel results use project-specific chronological user-level rules and should
  not be treated as a session-based e-commerce funnel.

## Next Milestone

Complete and review the Power BI dashboard, record the export refresh date in
the report, and then document the saved report or publication location.
