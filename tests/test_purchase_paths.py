"""验证用户购买路径的时间顺序与分类优先级。"""

import pandas as pd

from src.purchase_paths import analyze_purchase_behavior_paths


def _analyze_paths(rows):
    """把测试记录转换为路径分析所需的数据结构。"""

    df = pd.DataFrame(rows)
    df["time"] = pd.to_datetime(df["time"])
    purchase_data = df[df["behavior_type"] == 4]

    _, counts, percentages = analyze_purchase_behavior_paths(
        df,
        purchase_data
    )

    return counts, percentages


def test_view_to_purchase_path():
    """浏览后直接购买应归为 View -> Purchase。"""

    counts, percentages = _analyze_paths([
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 1,
            "time": "2024-01-01 09:00:00"
        },
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 4,
            "time": "2024-01-01 10:00:00"
        }
    ])

    assert counts["View -> Purchase"] == 1
    assert counts.sum() == 1
    assert percentages["View -> Purchase"] == 100.0


def test_view_to_cart_to_purchase_path():
    """浏览、加购、购买应识别为完整加购路径。"""

    counts, _ = _analyze_paths([
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 1,
            "time": "2024-01-01 09:00:00"
        },
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 3,
            "time": "2024-01-01 10:00:00"
        },
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 4,
            "time": "2024-01-01 11:00:00"
        }
    ])

    assert counts["View -> Cart -> Purchase"] == 1
    assert counts.sum() == 1


def test_purchase_without_prior_view_is_other():
    """购买前没有浏览记录时应归入 Other。"""

    counts, _ = _analyze_paths([
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 4,
            "time": "2024-01-01 09:00:00"
        }
    ])

    assert counts["Other"] == 1
    assert counts.sum() == 1


def test_repeated_behaviours_classify_each_purchase():
    """重复行为下的每次购买都应独立计入最具体路径。"""

    counts, percentages = _analyze_paths([
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 1,
            "time": "2024-01-01 09:00:00"
        },
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 1,
            "time": "2024-01-01 09:30:00"
        },
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 3,
            "time": "2024-01-01 10:00:00"
        },
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 3,
            "time": "2024-01-01 10:30:00"
        },
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 4,
            "time": "2024-01-01 11:00:00"
        },
        {
            "user_id": 1,
            "item_id": 100,
            "behavior_type": 4,
            "time": "2024-01-01 12:00:00"
        }
    ])

    assert counts["View -> Cart -> Purchase"] == 2
    assert counts.sum() == 2
    assert percentages["View -> Cart -> Purchase"] == 100.0
