import math

import pandas as pd

from .config import (
    CART_BEHAVIOR,
    FAVORITE_BEHAVIOR,
    HIGH_ACTIVITY_QUANTILE,
    HIGH_PURCHASE_QUANTILE,
    PURCHASE_BEHAVIOR,
    VIEW_BEHAVIOR
)


USER_SEGMENT_ORDER = [
    "High-Frequency Buyer",
    "No Purchase",
    "High Activity Low Purchase",
    "Regular Buyer"
]


def analyze_user_segmentation(df):
    total_actions = df.groupby(
        "user_id",
        sort=False
    ).size()

    behavior_counts = (
        df.groupby(
            ["user_id", "behavior_type"],
            sort=False,
            observed=True
        )
        .size()
        .unstack("behavior_type", fill_value=0)
        .reindex(total_actions.index, fill_value=0)
    )

    active_days = (
        df["time"]
        .dt.normalize()
        .groupby(df["user_id"], sort=False)
        .nunique()
    )

    user_summary = total_actions.rename("total_actions").to_frame()
    user_summary.index.name = "user_id"
    user_summary["view_count"] = behavior_counts.get(VIEW_BEHAVIOR, 0)
    user_summary["favorite_count"] = behavior_counts.get(
        FAVORITE_BEHAVIOR,
        0
    )
    user_summary["cart_count"] = behavior_counts.get(CART_BEHAVIOR, 0)
    user_summary["purchase_count"] = behavior_counts.get(
        PURCHASE_BEHAVIOR,
        0
    )
    user_summary["active_days"] = active_days.reindex(
        user_summary.index,
        fill_value=0
    )

    high_activity_threshold = user_summary["total_actions"].quantile(
        HIGH_ACTIVITY_QUANTILE
    )

    purchasing_users = user_summary["purchase_count"] > 0
    high_purchase_threshold = user_summary.loc[
        purchasing_users,
        "purchase_count"
    ].quantile(HIGH_PURCHASE_QUANTILE)

    high_frequency_buyers = (
        user_summary["purchase_count"] >= high_purchase_threshold
    )
    no_purchase_users = user_summary["purchase_count"] == 0
    high_activity_low_purchase_users = (
        purchasing_users
        & (user_summary["purchase_count"] < high_purchase_threshold)
        & (user_summary["total_actions"] >= high_activity_threshold)
    )

    user_summary["segment"] = "Regular Buyer"
    user_summary.loc[
        high_activity_low_purchase_users,
        "segment"
    ] = "High Activity Low Purchase"
    user_summary.loc[no_purchase_users, "segment"] = "No Purchase"
    user_summary.loc[
        high_frequency_buyers,
        "segment"
    ] = "High-Frequency Buyer"

    segment_counts = (
        user_summary["segment"]
        .value_counts()
        .reindex(USER_SEGMENT_ORDER, fill_value=0)
    )
    total_users = len(user_summary)

    if total_users:
        segment_percentages = segment_counts / total_users * 100
    else:
        segment_percentages = segment_counts.astype(float)

    assert segment_counts.sum() == total_users, (
        "Segment user counts do not add up to the total number of users."
    )

    expected_percentage_total = 100.0 if total_users else 0.0
    assert math.isclose(
        segment_percentages.sum(),
        expected_percentage_total,
        abs_tol=0.01
    ), "Segment percentages do not add up to approximately 100%."

    segment_summary = pd.DataFrame({
        "Number of Users": segment_counts,
        "Percentage of Users": segment_percentages
    })
    segment_summary.index.name = "User Segment"

    print("\nUser segmentation:")
    print(f"High activity threshold: {high_activity_threshold:.2f}")
    print(
        "High-frequency purchase threshold: "
        f"{high_purchase_threshold:.2f}"
    )
    print(
        segment_summary.to_string(
            formatters={
                "Percentage of Users": lambda value: f"{value:.2f}%"
            }
        )
    )

    return user_summary, segment_counts, segment_percentages
