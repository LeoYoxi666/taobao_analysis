# Taobao User Behaviour Analysis Project Context

## Purpose

This document is the durable project context for future development and AI
assistance. It records the current stage, established analytical rules, trusted
artifacts, and constraints. Detailed findings belong in the final analysis
report rather than being duplicated here.

The project analyzes Taobao user behaviour through a Python/pandas workflow, a
PostgreSQL analytics layer, and a Power BI reporting layer.

## Current Stage

| Workstream | Status |
| --- | --- |
| Python data loading and analysis | Complete |
| Data cleaning and quality checks | Complete |
| Python visualizations | Complete |
| Automated tests | Implemented |
| PostgreSQL 17 setup and schema creation | Complete |
| Full CSV import | Complete |
| SQL behaviour analysis | Complete |
| SQL purchase funnel and path analysis | Complete |
| SQL product/category analysis | Complete |
| SQL user analysis and segmentation | Complete |
| SQL result validation and final report | Complete |
| Power BI aggregate exports | Complete |
| Dashboard 1 - Module 2 | Complete |
| Dashboard 1 - Module 4 | Complete |
| Power BI dashboard creation | In progress |

Dashboard 1 Modules 2 and 4 are built from the validated exports in
`powerbi/data/`. Remaining dashboard work should reuse the existing data layer
unless a requirement exposes a genuine data gap.

## Dataset

The local source is `data/user_behavior_processed.csv`.

| Measure | Verified value |
| --- | ---: |
| Event records | 12,256,906 |
| Users | 10,000 |
| Items | 2,876,947 |
| Categories | 8,916 |

The CSV is approximately 492 MB. Do not load it for routine inspection,
documentation work, or unit tests.

Source columns:

- `time`
- `user_id`
- `item_id`
- `item_category`
- `behavior_type`

Behaviour codes are `1 = View`, `2 = Favorite`, `3 = Cart`, and
`4 = Purchase`.

## Trusted Project Artifacts

- `src/`: Python data processing, analysis, segmentation, purchase paths, and
  visualization modules.
- `tests/`: lightweight tests using mock DataFrames; they do not require the
  full CSV.
- `sql/create_tables.sql`: PostgreSQL schema, constraints, and indexes.
- `sql/import_data.sql`: guarded full-data import and validation workflow.
- `sql/behaviour_analysis.sql`: behaviour distribution and hourly activity.
- `sql/funnel_analysis.sql`: chronological funnel and purchase paths.
- `sql/product_analysis.sql`: purchased item and category rankings.
- `sql/user_analysis.sql`: user metrics and percentile-based segmentation.
- `docs/sql_analysis_results.md`: final validated SQL analysis and findings.
- `docs/*.png`: completed analysis charts.
- `powerbi/queries/`: read-only dashboard export queries.
- `powerbi/data/`: 12 validated aggregate CSV datasets.
- `powerbi/refresh_exports.ps1`: guarded PostgreSQL-to-CSV refresh workflow.

## Established Analytical Rules

- Duplicate source events are reported and retained. Do not deduplicate without
  a separate source-quality decision.
- Funnel stages are chronological: Cart must occur after View, and Purchase
  must occur after a valid Cart.
- Purchase paths are evaluated per user-item history and ordered by event time
  with the database event ID as the tie-breaker.
- User segmentation uses continuous 80th-percentile thresholds for activity
  and purchase frequency, following the existing segment priority.
- Python results are the original baseline; the completed SQL outputs were
  validated against them.
- The dataset has no price, quantity, product name, category name, demographic,
  or campaign fields. Do not make revenue or demographic claims.

## PostgreSQL State

PostgreSQL 17 is installed, the `taobao_analysis` database is populated, and
the analysis queries have completed successfully. All project objects are in
the `taobao` schema:

- `users`
- `categories`
- `items`
- `behaviour_types`
- `behaviour_events`
- `staging_user_behaviour`

The full import must not be rerun against populated tables. The import script
intentionally refuses to append when staging or event data already exists.
Credentials, database files, and dumps must not be committed.

## Power BI State

Five core aggregate datasets are ready for dashboard use:

- `user_behaviour_overview.csv`
- `hourly_activity_trend.csv`
- `purchase_funnel.csv`
- `product_category_ranking.csv`
- `user_segmentation.csv`

Dashboard 1, Module 2 has four additional SQL-backed exports ready for refresh:

- `weekday_hour_behaviour.csv`
- `weekday_hour_purchase_rate.csv`
- `daily_behaviour_trend.csv`
- `user_activity_distribution.csv`

Dashboard 1, Module 4 has three additional SQL-backed exports:

- `behaviour_transition_matrix.csv`
- `behaviour_depth_conversion.csv`
- `activity_category_preference.csv`

Modules 2 and 4 have been assembled in the local Power BI report. The report
location and publication status are not yet documented in the repository.

These tables use different analytical grains and should remain independent in
Power BI unless a deliberate model redesign is made. Identifiers must be stored
as text, share/conversion fields formatted as percentages, and explicit sort
columns applied as documented in `powerbi/README.md`.

Generated CSV values must not be edited manually. Update the corresponding
read-only query and rerun `powerbi/refresh_exports.ps1` so PostgreSQL remains
the source of truth.

## Working Rules for Future Assistance

- Preserve the completed Python and SQL logic unless a change is explicitly
  requested and regression-checked.
- Do not load the large CSV unnecessarily.
- Do not duplicate analysis functions or move orchestration logic back into
  `src/main.py`.
- Do not rerun the database import without confirming an empty intended target.
- Do not commit secrets, local database files, dumps, or Power BI cache files.
- Keep detailed findings in `docs/sql_analysis_results.md`, database operations
  in `database/README.md`, and dashboard instructions in `powerbi/README.md`.
- Update this document when the project changes stage.

## Next Milestone

Review Modules 2 and 4, complete any remaining dashboard modules, and add the
export refresh date. After review, record the PBIX location and publication
status here and in the root README.
