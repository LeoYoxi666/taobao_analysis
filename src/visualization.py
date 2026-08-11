"""Render the static charts used by the analysis report."""

import os
import matplotlib.pyplot as plt

from .config import (
    BEHAVIOR_DISTRIBUTION_FIGURE_SIZE,
    BEHAVIOR_DISTRIBUTION_PATH,
    FIGURE_SIZE,
    HOURLY_TREND_FIGURE_SIZE,
    HOURLY_TREND_PATH,
    PURCHASE_PATH_PATH,
    TOP_CATEGORIES_PATH,
    TOP_N,
    USER_FUNNEL_PATH,
    USER_SEGMENTATION_PATH
)


def plot_purchased_category_chart(top_categories):
    if not os.path.exists(TOP_CATEGORIES_PATH):
        plt.figure(figsize=FIGURE_SIZE)

        ax = plt.barh(top_categories.index.astype(str), top_categories.values)

        for bar, value in zip(ax, top_categories.values):
            plt.text(
                value,
                bar.get_y() + bar.get_height() / 2,
                f"{value:,}",
                ha="left",
                va="center",
                fontsize=9
            )

        plt.title(f"Top {TOP_N} Purchased Categories")
        plt.xlabel("Number of Purchases")
        plt.ylabel("Category ID")

        plt.gca().invert_yaxis()

        plt.tight_layout()

        plt.savefig(TOP_CATEGORIES_PATH)


def plot_behavior_distribution_chart(behavior_count):
    plt.figure(figsize=BEHAVIOR_DISTRIBUTION_FIGURE_SIZE)

    ax = behavior_count.plot(kind="bar", logy=False)

    for i, value in enumerate(behavior_count):
        plt.text(
            i,
            value,
            f"{value:,}",
            ha="center",
            va="bottom",
            fontsize=9
        )

    plt.title("User Behavior Distribution")
    plt.xlabel("Behavior Type")
    plt.ylabel("Number of Actions")

    plt.xticks(rotation=0)

    plt.tight_layout()

    print("Saving figure...")
    plt.savefig(BEHAVIOR_DISTRIBUTION_PATH)


def plot_user_funnel_chart(
    view_users,
    cart_after_view_users,
    purchase_after_cart_users
):
    funnel_labels = ["View", "Cart after View", "Purchase after Cart"]
    funnel_counts = [
        view_users,
        cart_after_view_users,
        purchase_after_cart_users
    ]

    plt.figure(figsize=FIGURE_SIZE)

    ax = plt.barh(funnel_labels, funnel_counts)

    for bar, value in zip(ax, funnel_counts):
        plt.text(
            value,
            bar.get_y() + bar.get_height() / 2,
            f"{value:,}",
            ha="left",
            va="center",
            fontsize=9
        )

    plt.title("User Behaviour Funnel")
    plt.xlabel("Number of Users")
    plt.ylabel("Funnel Stage")

    plt.gca().invert_yaxis()

    plt.tight_layout()

    plt.savefig(USER_FUNNEL_PATH)


def plot_hourly_trend_chart(
    hourly_action_counts,
    hourly_purchase_counts
):
    plt.figure(figsize=HOURLY_TREND_FIGURE_SIZE)

    plt.plot(
        hourly_action_counts.index,
        hourly_action_counts.values,
        marker="o",
        label="Total User Actions"
    )

    plt.plot(
        hourly_purchase_counts.index,
        hourly_purchase_counts.values,
        marker="o",
        label="Purchase Actions"
    )

    plt.title("Hourly User Behaviour Trend")
    plt.xlabel("Hour")
    plt.ylabel("Number of Actions")

    plt.xticks(range(24))
    plt.legend()

    plt.tight_layout()

    plt.savefig(HOURLY_TREND_PATH)


def plot_purchase_behavior_path_chart(
    purchase_path_labels,
    purchase_path_counts,
    purchase_path_percentages
):
    plt.figure(figsize=FIGURE_SIZE)

    ax = plt.barh(purchase_path_labels, purchase_path_counts.values)

    for bar, count, percentage in zip(
        ax,
        purchase_path_counts.values,
        purchase_path_percentages.values
    ):
        plt.text(
            count,
            bar.get_y() + bar.get_height() / 2,
            f"{count:,} ({percentage:.2f}%)",
            ha="left",
            va="center",
            fontsize=9
        )

    plt.title("Purchase Behavior Paths")
    plt.xlabel("Number of Purchases")
    plt.ylabel("Purchase Path")

    plt.gca().invert_yaxis()

    plt.tight_layout()

    plt.savefig(PURCHASE_PATH_PATH)


def plot_user_segmentation_chart(
    segment_counts,
    segment_percentages
):
    plt.figure(figsize=FIGURE_SIZE)

    bars = plt.bar(segment_counts.index, segment_counts.values)

    for bar, count, percentage in zip(
        bars,
        segment_counts.values,
        segment_percentages.values
    ):
        plt.text(
            bar.get_x() + bar.get_width() / 2,
            count,
            f"{count:,} ({percentage:.2f}%)",
            ha="center",
            va="bottom",
            fontsize=9
        )

    plt.title("User Segmentation")
    plt.xlabel("User Segment")
    plt.ylabel("Number of Users")

    plt.xticks(rotation=15, ha="right")

    plt.tight_layout()

    plt.savefig(USER_SEGMENTATION_PATH)
