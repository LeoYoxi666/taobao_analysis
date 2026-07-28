# Taobao User Behavior Analysis Project Context

## Project Goal

This project analyzes Taobao user behavior data using Python.

Dataset:
- user_behavior_processed.csv
- Around 12.25 million rows
- Do not load the CSV automatically unless necessary.

## Current Project Structure

src/
├── main.py
├── config.py
├── data_processing.py
├── analysis.py
├── purchase_paths.py
├── user_segmentation.py
└── visualization.py


## Completed Features

The following features are already implemented:

1. Data loading
- Load processed CSV
- Dataset summary
- Column inspection

2. Data quality analysis
- Missing value checking
- Duplicate checking

3. Basic behavior analysis
- Behavior distribution
- User count
- Item count
- Category count

4. Product analysis
- Top purchased items
- Top purchased categories

5. User funnel analysis
- View
- Cart
- Purchase
- Conversion rates

6. Time analysis
- Hourly user activity
- Hourly purchase activity

7. Purchase behavior path analysis

Examples:
- View → Purchase
- View → Cart → Purchase
- View → Favorite → Purchase

8. User segmentation

Current segments:

- High-Frequency Buyer
- No Purchase
- High Activity Low Purchase
- Regular Buyer


## Current Results

Total users:

10000

User segmentation:

High-Frequency Buyer:
1815 users

No Purchase:
1114 users

High Activity Low Purchase:
954 users

Regular Buyer:
6117 users


## Engineering Improvements Already Completed

- Configuration moved into config.py
- Analysis functions separated into modules
- Visualization separated
- main.py only controls workflow
- Avoid duplicated calculations
- Use python -m src.main to run


## Important Rules

Do not:
- Load the 492MB CSV unnecessarily
- Rewrite existing completed analysis
- Duplicate functions
- Put all code back into main.py


## Current Completion

Approximately 90%.

Remaining tasks:

1. Add automated tests
2. Improve README documentation
3. Add final analysis conclusions
4. Prepare final report


## Next Recommended Step

Before adding new features:
Review current project quality and create automated tests.

Focus on:
- user segmentation tests
- funnel calculation tests
- purchase path tests
- data processing tests