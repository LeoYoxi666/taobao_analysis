from .config import (
    CART_BEHAVIOR,
    PURCHASE_BEHAVIOR,
    TOP_N,
    VIEW_BEHAVIOR
)


def display_dataset_summary(df):
    print(df.head())

    print("\nShape:")
    print(df.shape)

    print("\nColumns:")
    print(df.columns)

    print("\nBehavior counts:")
    print(df["behavior_type"].value_counts())
    print("\nUser count:")
    print(df["user_id"].nunique())

    print("\nItem count:")
    print(df["item_id"].nunique())

    print("\nCategory count:")
    print(df["item_category"].nunique())


def analyze_purchased_items(df):
    print(f"\nTop {TOP_N} purchased items:")

    purchase_data = df[df["behavior_type"] == PURCHASE_BEHAVIOR]

    top_items = (
        purchase_data["item_id"]
        .value_counts()
        .head(TOP_N)
    )

    print(top_items)

    return purchase_data


def analyze_purchased_categories(purchase_data):
    print(f"\nTop {TOP_N} purchased categories:")

    top_categories = (
        purchase_data["item_category"]
        .value_counts()
        .head(TOP_N)
    )

    print(top_categories)

    return top_categories


def calculate_behavior_distribution(df):
    print("\nBehavior distribution:")

    behavior_count = df["behavior_type"].value_counts()

    print(behavior_count)

    return behavior_count


def calculate_chronological_funnel(df):
    print("\nUser behaviour funnel:")

    # Identify the first view for each user
    view_times = (
        df[df["behavior_type"] == VIEW_BEHAVIOR]
        .groupby("user_id")["time"]
        .min()
    )

    # Find each user's first cart event chronologically after a view
    cart_events = df[df["behavior_type"] == CART_BEHAVIOR][
        ["user_id", "time"]
    ].copy()
    cart_events["view_time"] = cart_events["user_id"].map(view_times)

    cart_after_view_times = (
        cart_events[cart_events["time"] > cart_events["view_time"]]
        .groupby("user_id")["time"]
        .min()
    )

    # Find each user's first purchase chronologically after a valid cart event
    purchase_events = df[df["behavior_type"] == PURCHASE_BEHAVIOR][
        ["user_id", "time"]
    ].copy()
    purchase_events["cart_time"] = purchase_events["user_id"].map(
        cart_after_view_times
    )

    purchase_after_cart_times = (
        purchase_events[purchase_events["time"] > purchase_events["cart_time"]]
        .groupby("user_id")["time"]
        .min()
    )

    view_users = len(view_times)
    cart_after_view_users = len(cart_after_view_times)
    purchase_after_cart_users = len(purchase_after_cart_times)

    view_to_cart_rate = (
        cart_after_view_users / view_users if view_users else 0
    )
    cart_to_purchase_rate = (
        purchase_after_cart_users / cart_after_view_users
        if cart_after_view_users else 0
    )
    overall_purchase_rate = (
        purchase_after_cart_users / view_users if view_users else 0
    )

    print("View users:", view_users)
    print("Cart after view users:", cart_after_view_users)
    print("Purchase after cart users:", purchase_after_cart_users)

    print("View-to-cart conversion rate:", f"{view_to_cart_rate:.2%}")
    print("Cart-to-purchase conversion rate:", f"{cart_to_purchase_rate:.2%}")
    print("Overall purchase conversion rate:", f"{overall_purchase_rate:.2%}")

    return view_users, cart_after_view_users, purchase_after_cart_users


def calculate_hourly_trend(df):
    df["hour"] = df["time"].dt.hour

    hourly_action_counts = (
        df["hour"]
        .value_counts()
        .reindex(range(24), fill_value=0)
    )

    hourly_purchase_counts = (
        df[df["behavior_type"] == PURCHASE_BEHAVIOR]["hour"]
        .value_counts()
        .reindex(range(24), fill_value=0)
    )

    print("\nHourly user action counts:")
    print(hourly_action_counts)

    print("\nHourly purchase action counts:")
    print(hourly_purchase_counts)

    return hourly_action_counts, hourly_purchase_counts
