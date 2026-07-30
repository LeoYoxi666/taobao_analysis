import pandas as pd

from src.analysis import (
    analyze_purchased_categories,
    analyze_purchased_items,
    calculate_behavior_distribution
)


def test_calculate_behavior_distribution_counts_each_behavior():
    df = pd.DataFrame({
        "behavior_type": [1, 1, 2, 3, 4, 4, 4]
    })

    behavior_counts = calculate_behavior_distribution(df)

    assert behavior_counts.to_dict() == {
        4: 3,
        1: 2,
        2: 1,
        3: 1
    }


def test_analyze_purchased_items_returns_only_purchase_rows():
    df = pd.DataFrame({
        "item_id": [10, 10, 20, 20, 20, 30],
        "item_category": [1, 1, 2, 2, 2, 3],
        "behavior_type": [4, 1, 4, 4, 4, 2]
    })

    purchase_data = analyze_purchased_items(df)

    expected = df.loc[[0, 2, 3, 4]]
    pd.testing.assert_frame_equal(purchase_data, expected)
    assert purchase_data["item_id"].value_counts().to_dict() == {
        20: 3,
        10: 1
    }


def test_analyze_purchased_categories_counts_purchase_categories():
    purchase_data = pd.DataFrame({
        "item_id": [10, 20, 21, 22, 30],
        "item_category": [1, 2, 2, 2, 3],
        "behavior_type": [4, 4, 4, 4, 4]
    })

    top_categories = analyze_purchased_categories(purchase_data)

    assert top_categories.to_dict() == {
        2: 3,
        1: 1,
        3: 1
    }
