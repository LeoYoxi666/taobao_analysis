# Taobao User Behaviour Analysis

## Overview

This project analyzes 12.26 million Taobao user-behaviour events with Python,
PostgreSQL, and Power BI. The Python and PostgreSQL analysis layers are
complete, all 12 dashboard datasets are exported, and Dashboard 1 Modules 2
and 4 have been built in Power BI. The remaining dashboard work is still in
progress.

## Project Status

| Stage | Status |
| --- | --- |
| Python analysis, cleaning, and visualization | Complete |
| PostgreSQL schema and full-data import | Complete |
| Behaviour, funnel, product/category, and user SQL analysis | Complete |
| SQL validation and final analysis report | Complete |
| Power BI query and CSV export layer | Complete |
| Power BI dashboard data layer (12 exports) | Complete |
| Dashboard 1 - Modules 2 and 4 | Complete |
| Remaining Power BI dashboard work | In progress |

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

The database results are exported into 12 dashboard-ready aggregate tables in
`powerbi/data/`: five core datasets, four Module 2 datasets, and three Module 4
datasets. Keep these aggregate tables independent in Power BI because they use
different analytical grains. Refresh every export from PostgreSQL with:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\powerbi\refresh_exports.ps1
```

Do not manually edit generated CSV values. Current dataset definitions,
refresh checks, page names, and links to the two build guides are in
[`powerbi/README.md`](powerbi/README.md).

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

Review the completed Modules 2 and 4, finish any remaining dashboard modules,
record the export refresh date, and document the saved PBIX or publication
location.
