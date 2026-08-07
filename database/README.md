# PostgreSQL Database Layer

## Current Status

The PostgreSQL stage is complete. PostgreSQL 17 is installed, the
`taobao_analysis` database and `taobao` schema have been created, the full CSV
has been imported successfully, and all four SQL analysis files have been run.
The results were validated against the established Python outputs and are
documented in
[`../docs/sql_analysis_results.md`](../docs/sql_analysis_results.md).

This file contains the durable database architecture, safe rebuild procedure,
and validation rules.

## Schema

| Table | Purpose | Primary key |
| --- | --- | --- |
| `taobao.users` | One row per observed user | `user_id` |
| `taobao.categories` | One row per item category | `category_id` |
| `taobao.items` | One row per item linked to its category | `item_id` |
| `taobao.behaviour_types` | View, Favorite, Cart, and Purchase lookup | `behaviour_type` |
| `taobao.behaviour_events` | Chronological user-item event fact table | `event_id` |
| `taobao.staging_user_behaviour` | Controlled CSV landing table | `staging_id` |

`event_time` uses `TIMESTAMP WITHOUT TIME ZONE` to match the existing naive
pandas timestamps. Duplicate source rows are retained. `event_id` provides a
stable tie-breaker for events with identical timestamps.

## SQL Files

- `sql/create_tables.sql`: creates the schema, lookup and core tables,
  constraints, comments, and analytical indexes.
- `sql/import_data.sql`: streams and validates the CSV, then populates the
  normalized tables.
- `sql/behaviour_analysis.sql`: behaviour distribution and hourly activity.
- `sql/funnel_analysis.sql`: chronological funnel and purchase paths.
- `sql/product_analysis.sql`: purchased item and category rankings.
- `sql/user_analysis.sql`: user metrics and percentile-based segmentation.

## Existing Database

The current database is already populated. Do not rerun
`sql/import_data.sql`: it intentionally refuses to append when staging or event
tables contain rows, preventing an accidental duplicate full import.

Run completed analyses independently when results need to be checked:

```powershell
psql -U postgres -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/behaviour_analysis.sql
psql -U postgres -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/funnel_analysis.sql
psql -U postgres -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/product_analysis.sql
psql -U postgres -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/user_analysis.sql
```

Use the appropriate local PostgreSQL role if it is not `postgres`.

## Rebuild Procedure

Use this procedure only for a new empty database or a deliberately approved
rebuild. PostgreSQL client tools (`createdb`, `psql`, and `pg_isready`) must be
installed and available on `Path`. PostgreSQL installation documentation is
available from the
[official Windows download page](https://www.postgresql.org/download/windows/).

From the repository root:

```powershell
createdb -U postgres taobao_analysis
psql -U postgres -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/create_tables.sql
psql -U postgres -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/import_data.sql
```

Important import behavior:

- The command must run from the repository root because `\copy` reads
  `data/user_behavior_processed.csv`.
- Import is manual and separate from schema creation.
- The source is streamed with `psql`; pandas is not involved.
- Behaviour codes must be between 1 and 4.
- Each item must map to exactly one category.
- Duplicate event rows are preserved and reported, not deleted.
- Table statistics are updated after import.

The import reads approximately 492 MB and requires additional space for the
staging table, normalized tables, and indexes. Do not interrupt it merely
because recent output has not appeared.

## Validation

After an import, these totals must match before analysis results are accepted:

| Check | Expected value |
| --- | ---: |
| Event rows | 12,256,906 |
| Users | 10,000 |
| Items | 2,876,947 |
| Categories | 8,916 |

Basic verification commands:

```powershell
psql -U postgres -d taobao_analysis -c "\dt taobao.*"
psql -U postgres -d taobao_analysis -c "SELECT COUNT(*) FROM taobao.behaviour_events;"
psql -U postgres -d taobao_analysis -c "SELECT * FROM taobao.behaviour_types ORDER BY behaviour_type;"
```

The lookup must contain `1 = View`, `2 = Favorite`, `3 = Cart`, and
`4 = Purchase`. Stop and investigate if totals or mappings differ; do not
silently truncate, deduplicate, or re-import.

## Analytical Consistency

The SQL layer preserves the established Python rules:

- Cart must occur strictly after a user's first View, and Purchase must occur
  strictly after the valid Cart.
- Purchase paths are ordered by `event_time` and `event_id`, retain repeated
  behaviours, and classify every purchase event.
- Segmentation uses continuous 80th-percentile activity and purchase thresholds
  with the same segment priority as Python.

## Power BI Handoff

The completed SQL results feed five read-only export queries in
`../powerbi/queries/`. The checked-in aggregates and guarded refresh workflow
are documented in [`../powerbi/README.md`](../powerbi/README.md). Dashboard
creation is currently in progress.

For a deployed dashboard, use a dedicated read-only reporting role rather than
an administrator account. Never commit database passwords, connection secrets,
database files, or dumps.
