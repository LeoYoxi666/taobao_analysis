# PostgreSQL Setup and Verification Guide

This guide sets up the PostgreSQL layer for the Taobao User Behaviour Analysis
project on Windows. It keeps the existing Python analysis unchanged.

> **Large-file safety:** Do not run `sql/import_data.sql` until you intentionally
> choose to import the 492 MB CSV. Schema creation and empty-database query
> verification do not read the CSV.

## 1. Installation Requirements

Install a supported 64-bit PostgreSQL release. PostgreSQL 16 or newer is
recommended for this project. The official Windows installer is available at:

- <https://www.postgresql.org/download/windows/>

The standard Windows installer includes:

- PostgreSQL Server;
- PostgreSQL command-line tools, including `psql`, `createdb`, and
  `pg_isready`;
- pgAdmin, which is optional for this command-line workflow;
- StackBuilder, which is not required for this project.

During installation:

1. Install the PostgreSQL Server and Command Line Tools components.
2. Keep the default port `5432` unless it is already in use.
3. Set and securely record the password for the `postgres` administrator role.
4. Keep UTF-8 as the database encoding.
5. Allow several gigabytes of free disk space for the staging table, normalized
   event table, and indexes. Ten gigabytes of free space is a safe working
   target for this project.

The current project environment was checked on 5 August 2026 and did not have
PostgreSQL, `psql`, or Docker installed. Installation is therefore required
before the database commands below can be executed.

### Verify the installation

Open a new PowerShell window after installation and run:

```powershell
psql --version
createdb --version
pg_isready -h localhost -p 5432
```

Expected results:

- `psql` and `createdb` print their PostgreSQL version.
- `pg_isready` reports that `localhost:5432` is accepting connections.

If PowerShell cannot find the commands, temporarily add the PostgreSQL binary
directory to the current shell. Replace `<version>` with the installed major
version:

```powershell
$env:Path += ";C:\Program Files\PostgreSQL\<version>\bin"
psql --version
```

For a permanent fix, add that `bin` directory to the Windows user or system
`Path`, then open a new PowerShell window.

## 2. Create the Database and Application Role

Run the following command and enter the administrator password chosen during
installation:

```powershell
psql -h localhost -p 5432 -U postgres -d postgres
```

At the `postgres=#` prompt, create a project-specific login. `\password` asks
for the password interactively so it is not stored in shell history:

```sql
CREATE ROLE taobao_app WITH LOGIN;
\password taobao_app
CREATE DATABASE taobao_analysis OWNER taobao_app ENCODING 'UTF8';
\q
```

Verify that the new role can connect:

```powershell
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -c "SELECT current_database(), current_user;"
```

Expected values:

```text
current_database | taobao_analysis
current_user     | taobao_app
```

## 3. Create the Tables

Move to the project root:

```powershell
Set-Location C:\Users\WY\Desktop\taobao_analysis
```

Create the `taobao` schema, lookup tables, dimension tables, event table,
staging table, constraints, and indexes:

```powershell
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/create_tables.sql
```

`ON_ERROR_STOP=1` makes `psql` stop immediately if a statement fails.

### Verify the schema

List the created tables:

```powershell
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -c "\dt taobao.*"
```

The list should contain:

- `behaviour_events`
- `behaviour_types`
- `categories`
- `items`
- `staging_user_behaviour`
- `users`

Verify the four behaviour lookup values:

```powershell
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -c "SELECT * FROM taobao.behaviour_types ORDER BY behaviour_type;"
```

Expected mapping:

| behaviour_type | behaviour_name |
| ---: | --- |
| 1 | View |
| 2 | Favorite |
| 3 | Cart |
| 4 | Purchase |

## 4. Verify the SQL Files Before Import

All analysis files can run against the empty schema. This is a safe way to
confirm table names, permissions, and SQL syntax without touching the CSV:

```powershell
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/behaviour_analysis.sql
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/product_analysis.sql
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/funnel_analysis.sql
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/user_analysis.sql
```

Before import, zero counts, empty product rankings, and `NULL` percentages are
expected. Any SQL error is not expected and should be resolved before loading
the large dataset.

## 5. CSV Import — Manual Confirmation Required

> **Stop here unless the 492 MB import is intentionally approved.** The
> following command reads `data/user_behavior_processed.csv` and may take time
> depending on disk and CPU performance. It is never run by schema creation or
> by the Python test suite.

Before import, confirm that the target tables are empty:

```powershell
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -c "SELECT COUNT(*) AS event_rows FROM taobao.behaviour_events; SELECT COUNT(*) AS staging_rows FROM taobao.staging_user_behaviour;"
```

Both values must be zero. From the project root, the manual import command is:

```powershell
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/import_data.sql
```

The import script:

1. refuses to run if staging or event data already exists;
2. streams the local CSV with client-side `\copy` instead of pandas;
3. validates behaviour codes;
4. validates that each item maps to only one category;
5. populates users, categories, items, and behaviour events;
6. preserves duplicate source rows;
7. updates PostgreSQL table statistics;
8. prints row counts and the duplicate-row count.

Do not close the terminal merely because the import has not printed recent
output. To inspect a running import from a second PowerShell window, use:

```powershell
psql -h localhost -p 5432 -U postgres -d postgres -c "SELECT pid, datname, state, wait_event_type, wait_event, query_start FROM pg_stat_activity WHERE datname = 'taobao_analysis';"
```

## 6. Verify the Imported Data

After a successful manual import, connect interactively:

```powershell
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis
```

Run the following checks:

```sql
SELECT COUNT(*) AS event_rows FROM taobao.behaviour_events;
SELECT COUNT(*) AS users FROM taobao.users;
SELECT COUNT(*) AS items FROM taobao.items;
SELECT COUNT(*) AS categories FROM taobao.categories;

SELECT behaviour_type, COUNT(*) AS action_count
FROM taobao.behaviour_events
GROUP BY behaviour_type
ORDER BY behaviour_type;

\q
```

Verified project totals are:

| Check | Expected value |
| --- | ---: |
| Event rows | 12,256,906 |
| Users | 10,000 |
| Items | 2,876,947 |
| Categories | 8,916 |

If these totals differ, stop before treating SQL results as verified. Do not
delete or deduplicate rows automatically.

## 7. Execute and Verify the Analysis Queries

Run each analysis file from the project root:

```powershell
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/behaviour_analysis.sql
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/product_analysis.sql
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/funnel_analysis.sql
psql -h localhost -p 5432 -U taobao_app -d taobao_analysis -v ON_ERROR_STOP=1 -f sql/user_analysis.sql
```

Use these existing Python results as regression checks.

### Funnel

| Metric | Expected value |
| --- | ---: |
| View users | 10,000 |
| Cart after view users | 8,538 |
| Purchase after cart users | 7,517 |
| View-to-cart conversion | 85.38% |
| Cart-to-purchase conversion | 88.04% |
| Overall conversion | 75.17% |

### Purchase paths

| Path | Purchases | Percentage |
| --- | ---: | ---: |
| View -> Purchase | 52,784 | 43.91% |
| View -> Cart -> Purchase | 40,335 | 33.56% |
| View -> Favorite -> Purchase | 4,781 | 3.98% |
| View -> Favorite -> Cart -> Purchase | 3,097 | 2.58% |
| Other | 19,208 | 15.98% |

### User segmentation

| Segment | Users | Percentage |
| --- | ---: | ---: |
| High-Frequency Buyer | 1,815 | 18.15% |
| No Purchase | 1,114 | 11.14% |
| High Activity Low Purchase | 954 | 9.54% |
| Regular Buyer | 6,117 | 61.17% |

The behaviour distribution, hourly counts, and top product/category counts
should also be compared with the current Python output before the SQL layer is
used as a replacement data source.

## 8. Troubleshooting

### `psql` or `createdb` is not recognized

- Open a new PowerShell window after installation.
- Confirm that `C:\Program Files\PostgreSQL\<version>\bin` exists.
- Add that directory to `Path` or invoke `psql.exe` with its full path.

### Connection refused or `no response`

Check the Windows service:

```powershell
Get-Service -Name 'postgresql*'
```

If it is stopped, open PowerShell as Administrator and start the exact service
name returned by the previous command:

```powershell
Start-Service -Name '<postgresql-service-name>'
```

Then rerun:

```powershell
pg_isready -h localhost -p 5432
```

### Password authentication failed

- Confirm whether the command uses `postgres` or `taobao_app`.
- Use the password assigned to that PostgreSQL role, not the Windows password.
- Reset the project role password while connected as an administrator:

```sql
\password taobao_app
```

### `database "taobao_analysis" already exists`

Do not drop it automatically. Connect to it and check whether the `taobao`
schema and tables are already present. Reuse it only if it is the intended
project database.

### `permission denied for schema taobao`

Confirm that `taobao_app` owns `taobao_analysis`. From an administrator session:

```sql
ALTER DATABASE taobao_analysis OWNER TO taobao_app;
```

If the schema was created by another role, connect to `taobao_analysis` as the
administrator and run:

```sql
ALTER SCHEMA taobao OWNER TO taobao_app;
```

### `\copy`: file not found

- Run the import command from
  `C:\Users\WY\Desktop\taobao_analysis`.
- Confirm that `data/user_behavior_processed.csv` exists.
- Do not open or preview the file merely to test the path.

### Import reports unsupported behaviour codes

The SQL layer accepts only the existing mapping `1` through `4`. Do not bypass
the validation. Investigate the source or import configuration first.

### Import reports one item in multiple categories

The normalized item schema assumes one category per item. Do not select an
arbitrary category. Investigate the affected item-category relationships before
changing the schema or resuming import.

### Invalid timestamp syntax

The source `time` values must be convertible to PostgreSQL `TIMESTAMP WITHOUT
TIME ZONE`. A conversion error rolls back the import transaction. Investigate
the invalid source format before retrying.

### Disk space error

The database temporarily stores staging data in addition to the normalized
tables and indexes. Check available space:

```powershell
Get-PSDrive -Name C
```

Free additional space before retrying. Do not partially delete PostgreSQL data
files by hand.

### Analysis files return no rows

This is expected before CSV import. After import, confirm that
`taobao.behaviour_events` contains rows and that the command connects to the
`taobao_analysis` database.

### Import refuses because tables are not empty

This protection prevents accidental duplicate full imports. Do not truncate or
drop tables unless you deliberately choose to rebuild the database and have
confirmed the exact target.

## Official References

- PostgreSQL Windows installer:
  <https://www.postgresql.org/download/windows/>
- Creating a database with `createdb`:
  <https://www.postgresql.org/docs/current/app-createdb.html>
- PostgreSQL `psql` and client-side `\copy`:
  <https://www.postgresql.org/docs/current/app-psql.html>

Power BI setup is intentionally outside the scope of this stage.
