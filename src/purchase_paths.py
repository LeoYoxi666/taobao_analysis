import pandas as pd

from .config import (
    CART_BEHAVIOR,
    FAVORITE_BEHAVIOR,
    PURCHASE_BEHAVIOR,
    VIEW_BEHAVIOR
)


def analyze_purchase_behavior_paths(df, purchase_data):
    purchase_path_labels = [
        "View -> Purchase",
        "View -> Cart -> Purchase",
        "View -> Favorite -> Purchase",
        "View -> Favorite -> Cart -> Purchase",
        "Other"
    ]

    # Optimize by keeping only user-item pairs that contain a purchase
    purchase_pairs = (
        purchase_data[["user_id", "item_id"]]
        .drop_duplicates()
    )

    purchase_path_data = (
        df[["user_id", "item_id", "behavior_type", "time"]]
        .merge(
            purchase_pairs,
            on=["user_id", "item_id"],
            how="inner",
            sort=False
        )
        .sort_values(["user_id", "item_id", "time"], kind="mergesort")
    )

    # Use vectorized cumulative states instead of iterating over pandas groups
    purchase_path_groups = purchase_path_data.groupby(
        ["user_id", "item_id"],
        sort=False,
        dropna=False
    ).ngroup()

    path_behaviors = purchase_path_data["behavior_type"]
    is_view = path_behaviors == VIEW_BEHAVIOR
    is_favorite = path_behaviors == FAVORITE_BEHAVIOR
    is_cart = path_behaviors == CART_BEHAVIOR
    is_purchase = path_behaviors == PURCHASE_BEHAVIOR

    view_seen = is_view.groupby(
        purchase_path_groups,
        sort=False
    ).cummax()
    view_before = view_seen.groupby(
        purchase_path_groups,
        sort=False
    ).shift(fill_value=False)

    view_favorite_seen = (
        is_favorite & view_before
    ).groupby(
        purchase_path_groups,
        sort=False
    ).cummax()
    view_favorite_before = view_favorite_seen.groupby(
        purchase_path_groups,
        sort=False
    ).shift(fill_value=False)

    view_cart_seen = (
        is_cart & view_before
    ).groupby(
        purchase_path_groups,
        sort=False
    ).cummax()

    view_favorite_cart_seen = (
        is_cart & view_favorite_before
    ).groupby(
        purchase_path_groups,
        sort=False
    ).cummax()

    # Apply the original path precedence with vectorized assignments
    classified_purchase_paths = pd.Series(
        "Other",
        index=purchase_path_data.index
    )
    classified_purchase_paths.loc[
        is_purchase & view_seen
    ] = "View -> Purchase"
    classified_purchase_paths.loc[
        is_purchase & view_favorite_seen
    ] = "View -> Favorite -> Purchase"
    classified_purchase_paths.loc[
        is_purchase & view_cart_seen
    ] = "View -> Cart -> Purchase"
    classified_purchase_paths.loc[
        is_purchase & view_favorite_cart_seen
    ] = "View -> Favorite -> Cart -> Purchase"

    purchase_path_counts = (
        classified_purchase_paths[is_purchase]
        .value_counts()
        .reindex(purchase_path_labels, fill_value=0)
    )
    total_path_purchases = purchase_path_counts.sum()

    if total_path_purchases:
        purchase_path_percentages = (
            purchase_path_counts / total_path_purchases * 100
        )
    else:
        purchase_path_percentages = purchase_path_counts.astype(float)

    purchase_path_summary = pd.DataFrame({
        "Number of Purchases": purchase_path_counts,
        "Percentage of Purchases": purchase_path_percentages
    })
    purchase_path_summary.index.name = "Path Type"

    print("\nPurchase behavior paths:")
    print(
        purchase_path_summary.to_string(
            formatters={
                "Percentage of Purchases": lambda value: f"{value:.2f}%"
            }
        )
    )

    return (
        purchase_path_labels,
        purchase_path_counts,
        purchase_path_percentages
    )
