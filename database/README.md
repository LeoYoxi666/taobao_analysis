# PostgreSQL Database Layer

This directory documents the PostgreSQL database layer for the Taobao User
Behaviour Analysis project. The SQL implementation runs alongside the existing
Python and pandas workflow; it does not replace or change the verified Python
analysis.

For the complete Windows installation, database creation, empty-database
verification, manual CSV import, and troubleshooting workflow, see
[`setup.md`](setup.md).

## Why PostgreSQL

PostgreSQL is used because the project contains more than 12 million behaviour
events and requires chronological window calculations, continuous percentile
thresholds, indexed joins, and future Power BI access. SQLite would be suitable
for a portable local prototype, but PostgreSQL provides a stronger long-term
analytics and BI layer.

## Schema

All database objects are created in the `taobao` schema.

| Table | Purpose | Primary key | Main relationships |
| --- | --- | --- | --- |
| `users` | One row per observed user | `user_id` | One user has many behaviour events |
| `categories` | One row per observed item category | `category_id` | One category has many items |
| `items` | One row per observed item | `item_id` | Each item belongs to one category and has many events |
| `behaviour_types` | Lookup for View, Favorite, Cart, and Purchase | `behaviour_type` | One type has many events |
| `behaviour_events` | Chronological user-item event fact table | `event_id` | References users, items, and behaviour types |
| `staging_user_behaviour` | Exact landing structure for the source CSV | `staging_id` | Used only for controlled import and validation |

The `event_time` column uses `TIMESTAMP WITHOUT TIME ZONE` so its semantics match
the current naive pandas datetime values. Duplicate source rows are retained.
The surrogate `event_id` provides a stable tie-breaker when timestamps are
identical.

## SQL Files

- `sql/create_tables.sql`: Creates the schema, lookup and core tables,
  constraints, comments, and analytical indexes.
- `sql/import_data.sql`: Streams the CSV into the staging table with `psql`
  `\copy`, validates the values, populates normalized tables, and prints import
  checks.
- `sql/behaviour_analysis.sql`: Behaviour distribution and hourly activity.
- `sql/product_analysis.sql`: Top purchased items and categories.
- `sql/funnel_analysis.sql`: Chronological conversion funnel and purchase paths.
- `sql/user_analysis.sql`: User-level metrics and percentile-based segmentation.

## Create the Database

Install PostgreSQL and make sure `createdb` and `psql` are available. From the
project root, create a local database and run the schema file:

```powershell
createdb -U postgres taobao_analysis
psql -U postgres -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/create_tables.sql
```

Use your own PostgreSQL role instead of `postgres` when appropriate. Do not put
database passwords in the repository.

## Import the Data

The import is deliberately separate from schema creation. It is the only step
that reads the large CSV, so run it manually only when the database is ready:

```powershell
psql -U postgres -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/import_data.sql
```

Important import behaviour:

- Run the command from the repository root because the client-side `\copy`
  path is `data/user_behavior_processed.csv`.
- The file is streamed by `psql`; pandas is not involved.
- The script refuses to append when staging or event tables already contain
  rows, preventing an accidental duplicate full import.
- It validates that behaviour codes are between 1 and 4.
- It validates the one-item-to-one-category assumption before normalizing the
  item table.
- It preserves duplicate event rows and reports their count instead of deleting
  them.

After import, compare the printed values with the verified project totals:

| Check | Expected value |
| --- | ---: |
| Event rows | 12,256,906 |
| Users | 10,000 |
| Items | 2,876,947 |
| Categories | 8,916 |

## Run the Analysis Queries

Each analysis file can be executed independently:

```powershell
psql -U postgres -d taobao_analysis -f sql/behaviour_analysis.sql
psql -U postgres -d taobao_analysis -f sql/product_analysis.sql
psql -U postgres -d taobao_analysis -f sql/funnel_analysis.sql
psql -U postgres -d taobao_analysis -f sql/user_analysis.sql
```

The SQL intentionally follows the current Python rules:

- Funnel cart events must occur strictly after a user's first view, and
  purchases must occur strictly after the valid cart.
- Purchase paths are ordered by `event_time` and then `event_id`, retain
  repeated behaviours, and classify every purchase event.
- User segmentation uses continuous 80th-percentile activity and purchase
  thresholds with the same segment priority as the Python module.

## Python Integration

The current Python pipeline continues to read the CSV and remains the verified
baseline. A later integration can add a separate database connection module
using a PostgreSQL driver or SQLAlchemy, then return SQL result sets as pandas
DataFrames. That connection should be optional and should not rewrite the
existing analysis functions until SQL outputs have been checked against the
verified Python results.

Store connection settings in environment variables, for example:

```text
TAOBAO_DB_HOST=localhost
TAOBAO_DB_PORT=5432
TAOBAO_DB_NAME=taobao_analysis
TAOBAO_DB_USER=your_user
TAOBAO_DB_PASSWORD=your_password
```

Do not commit real credentials, database files, or database dumps.

## Power BI Preparation

Power BI can connect directly to PostgreSQL. For the first dashboard, use the
aggregated query results rather than importing the entire event table. The
recommended next database step is to expose the validated analyses as views or
materialized views and grant Power BI a read-only database role.

Suggested Power BI datasets are:

- behaviour distribution;
- hourly action and purchase counts;
- funnel counts and conversion percentages;
- purchase path counts and percentages;
- user segment counts and percentages;
- top purchased items and categories.
