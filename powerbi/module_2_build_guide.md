# Dashboard 1 - Module 2 Build Guide

This guide builds the **User Behaviour Timing and Distribution** section in
Power BI. Refresh the exports before importing the four new files. The query
results are deliberately independent aggregate tables; do not create
relationships among them.

## 1. Refresh and import

From the project root, run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\powerbi\refresh_exports.ps1
```

In Power BI Desktop, use **Get Data > Text/CSV** to import these files from
`powerbi/data/`:

- `weekday_hour_behaviour.csv`
- `weekday_hour_purchase_rate.csv`
- `daily_behaviour_trend.csv`
- `user_activity_distribution.csv`

Use Import mode. In Model view, delete or disable all automatically detected
relationships.

Apply these data types and formats:

| Table | Columns | Setting |
| --- | --- | --- |
| Weekday-hour behaviour | weekday_number, activity_hour, behaviour_type, action_count | Whole number |
| Weekday-hour purchase rate | weekday_number, activity_hour, view_user_count, purchase_user_count | Whole number |
| Weekday-hour purchase rate | purchase_rate | Percentage, 2 decimals |
| Daily behaviour trend | activity_date | Date |
| Daily behaviour trend | weekday_number, behaviour_type, action_count, view_user_count, purchase_user_count | Whole number |
| Daily behaviour trend | purchase_rate | Percentage, 2 decimals |
| User activity distribution | distribution_order, bin_order, user_count | Whole number |
| User activity distribution | user_share, purchase_rate | Percentage, 2 decimals |

Set `weekday_name` to **Sort by column** `weekday_number` in both weekday-hour
tables. Set `behaviour_name` to **Sort by column** `behaviour_type` in the
behaviour and daily tables. For each distribution visual, use the visual menu
to sort `bin_label` by `bin_order` ascending after applying its
`distribution_type` filter.

## 2. Create measures

Use the actual imported table names if Power BI adds a suffix.

```DAX
Daily View Actions =
CALCULATE(
    SUM('daily_behaviour_trend'[action_count]),
    'daily_behaviour_trend'[behaviour_name] = "View"
)

Daily Favorite Actions =
CALCULATE(
    SUM('daily_behaviour_trend'[action_count]),
    'daily_behaviour_trend'[behaviour_name] = "Favorite"
)

Daily Cart Actions =
CALCULATE(
    SUM('daily_behaviour_trend'[action_count]),
    'daily_behaviour_trend'[behaviour_name] = "Cart"
)

Daily Purchase Actions =
CALCULATE(
    SUM('daily_behaviour_trend'[action_count]),
    'daily_behaviour_trend'[behaviour_name] = "Purchase"
)

Daily Purchase Rate =
DIVIDE(
    SUM('daily_behaviour_trend'[purchase_user_count]),
    SUM('daily_behaviour_trend'[view_user_count])
)
```

`Daily Purchase Rate` is calculated from user counts rather than by summing
repeated percentage values. It means purchasing users divided by viewing users
on each date. It is a same-period propensity indicator, not a session funnel.

## 3. Create the five visuals

1. **Behaviour heatmap** - Matrix: rows `weekday_name`; columns
   `activity_hour`; values `Sum of action_count`. Add a `behaviour_name` slicer
   and set matrix background conditional formatting to a light-to-dark warm
   colour scale.
2. **Purchase-rate heatmap** - Matrix: rows `weekday_name`; columns
   `activity_hour`; values `Average of purchase_rate`. Format as a percentage
   and apply the same conditional-format scale. Add the definition to the
   title or subtitle: `Purchasing users / viewing users in the same time cell`.
3. **Daily behaviour and purchase-rate trend** - Line and clustered column
   chart: shared axis `activity_date`; column Y-axis the four daily action
   measures; line Y-axis `Daily Purchase Rate`. Put `day_type` in Tooltips.
4. **Activity distribution and purchase rate** - Line and clustered column
   chart filtered to `distribution_type = Activity`: shared axis `bin_label`;
   column Y-axis `Sum of user_count`; line Y-axis `Average of purchase_rate`.
5. **Purchase-frequency distribution** - Clustered column chart filtered to
   `distribution_type = Purchase Frequency`: X-axis `bin_label`; Y-axis
   `Sum of user_count`; put `user_share` in Tooltips.

The native Power BI visual does not consistently support a logarithmic
categorical X-axis. The precomputed 1, 2-3, 4-7, ... activity bins are
logarithmic, so retain their sort order and use them instead of a fake linear
axis.

## 4. Layout and review

Arrange the two heatmaps in the first row, the daily trend across the second
row, and the two distribution charts in the third row. Use warm colours for
high activity and high purchase rate, and keep labels and percentage precision
consistent. Add the export refresh date to a subtitle before sharing.

Validate that the behaviour heatmap has 7 rows and 24 columns, the trend has
four action series plus one rate series, and empty distribution bins remain
visible. Do not describe the rate visuals as a chronological conversion funnel:
the source has no session identifier.
