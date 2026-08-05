# Taobao User Behaviour Analysis

## Project Overview

This project analyzes Taobao user behaviour data using Python and pandas. It
examines customer activity, product interactions, conversion performance,
purchase paths, hourly trends, and user segments.

## Dataset

The processed dataset contains:

- 12,256,906 records
- 10,000 users
- 2,876,947 items
- 8,916 categories

The dataset columns are:

- `time`
- `user_id`
- `item_id`
- `item_category`
- `behavior_type`

The `behavior_type` values represent:

| Value | Behaviour |
| ---: | --- |
| 1 | View |
| 2 | Favorite |
| 3 | Cart |
| 4 | Purchase |

## Project Structure

- `src/config.py`: Stores the dataset path, behaviour constants, percentile
  settings, chart paths, and visualization settings.
- `src/data_processing.py`: Loads the processed dataset, converts the time
  column to datetime, and performs data-quality checks.
- `src/analysis.py`: Provides the dataset summary, product analysis, behaviour
  distribution, chronological funnel, and hourly trend calculations.
- `src/purchase_paths.py`: Classifies chronological purchase paths for each
  user-item pair.
- `src/user_segmentation.py`: Builds user-level activity summaries and assigns
  each user to a percentile-based segment.
- `src/visualization.py`: Creates and saves all project charts.
- `src/main.py`: Orchestrates the analysis workflow.
- `database/`: Documents PostgreSQL setup, import, and integration guidance.
- `sql/`: Contains the database schema, controlled import workflow, and SQL
  versions of the existing analyses.
- `docs/`: Contains the generated PNG charts.
- `tests/`: Contains automated tests using small mock pandas DataFrames.

## Implemented Analysis

- Dataset summary
- Missing-value and duplicate checks
- Behaviour distribution
- Top purchased items
- Top purchased categories
- Chronological conversion funnel
- Hourly activity trend
- Purchase behaviour path analysis
- User segmentation

## Main Results

### Chronological Conversion Funnel

| Funnel metric | Result |
| --- | ---: |
| View users | 10,000 |
| Cart after view users | 8,538 |
| Purchase after cart users | 7,517 |
| View-to-cart conversion | 85.38% |
| Cart-to-purchase conversion | 88.04% |
| Overall conversion | 75.17% |

### User Segmentation

| User segment | Users | Percentage |
| --- | ---: | ---: |
| High-Frequency Buyer | 1,815 | 18.15% |
| No Purchase | 1,114 | 11.14% |
| High Activity Low Purchase | 954 | 9.54% |
| Regular Buyer | 6,117 | 61.17% |

### Purchase Behaviour Paths

| Purchase path | Purchases | Percentage |
| --- | ---: | ---: |
| View -> Purchase | 52,784 | 43.91% |
| View -> Cart -> Purchase | 40,335 | 33.56% |
| View -> Favorite -> Purchase | 4,781 | 3.98% |
| View -> Favorite -> Cart -> Purchase | 3,097 | 2.58% |
| Other | 19,208 | 15.98% |

## Installation

From the project root, create and activate a virtual environment, then install
the required packages:

```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
```

## How to Run

Run the project as a Python module from the project root:

```powershell
python -m src.main
```

## SQL Database Layer

The project includes an optional PostgreSQL layer alongside the existing Python
and pandas workflow. PostgreSQL was selected for its support for indexed
analytics over the 12-million-row event table, chronological window queries,
continuous percentile calculations, and direct integration with BI tools.

The normalized schema contains:

- `taobao.users`: one row per user;
- `taobao.categories`: one row per item category;
- `taobao.items`: one row per item, linked to its category;
- `taobao.behaviour_types`: View, Favorite, Cart, and Purchase lookup values;
- `taobao.behaviour_events`: the chronological user-item event fact table;
- `taobao.staging_user_behaviour`: the controlled CSV import table.

SQL files reproduce the existing behaviour distribution, hourly activity,
product rankings, chronological funnel, purchase paths, and user segmentation.
For example, after creating and importing a local PostgreSQL database, run:

```powershell
psql -U postgres -d taobao_analysis -f sql/behaviour_analysis.sql
psql -U postgres -d taobao_analysis -f sql/funnel_analysis.sql
psql -U postgres -d taobao_analysis -f sql/product_analysis.sql
psql -U postgres -d taobao_analysis -f sql/user_analysis.sql
```

The SQL layer currently runs independently, leaving all verified Python logic
unchanged. A future database connection module can execute these queries and
return their results as pandas DataFrames after the SQL and Python outputs have
been validated against each other. Full setup and import instructions are in
[`database/README.md`](database/README.md).

## Output Charts

The current generated charts in `docs/` are:

- `docs/behavior_distribution.png`
- `docs/hourly_behavior_trend.png`
- `docs/purchase_behavior_paths.png`
- `docs/top10_purchased_categories.png`
- `docs/user_funnel.png`
- `docs/user_segmentation.png`

## Notes and Limitations

- The processed CSV is approximately 492 MB and should not be loaded
  unnecessarily.
- Duplicate rows were detected during data-quality analysis but are not
  automatically deleted.
- Purchase paths are classified chronologically for each user-item pair.
- User segments use percentile-based thresholds for activity and purchase
  frequency.
- The dataset has no price field, so revenue cannot be calculated.

## Future Improvements

- Add automated tests.
- Further validate duplicate records before deciding whether to remove them.
- Add further user-value analysis.
- Prepare a final report.
