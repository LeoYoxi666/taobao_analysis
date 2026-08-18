"""验证用户分群结果的分类规则、互斥性和完整性。"""

import pandas as pd
import pytest

from src.user_segmentation import (
    USER_SEGMENT_ORDER,
    analyze_user_segmentation
)


@pytest.fixture(scope="module")
def segmentation_results():
    """构造能够覆盖四类用户分群的测试数据。"""

    rows = []

    # 用户 1：购买次数高；用户 2：活跃度高但购买次数低。
    rows.extend(
        {
            "user_id": 1,
            "behavior_type": 4,
            "time": pd.Timestamp("2024-01-01") + pd.Timedelta(hours=hour)
        }
        for hour in range(5)
    )
    rows.extend(
        {
            "user_id": 2,
            "behavior_type": 1,
            "time": pd.Timestamp("2024-01-02") + pd.Timedelta(minutes=minute)
        }
        for minute in range(9)
    )
    rows.append({
        "user_id": 2,
        "behavior_type": 4,
        "time": pd.Timestamp("2024-01-02 01:00:00")
    })
    # 用户 3：普通购买用户；用户 4：无购买用户。
    rows.extend([
        {
            "user_id": 3,
            "behavior_type": 1,
            "time": pd.Timestamp("2024-01-03 09:00:00")
        },
        {
            "user_id": 3,
            "behavior_type": 4,
            "time": pd.Timestamp("2024-01-03 10:00:00")
        },
        {
            "user_id": 4,
            "behavior_type": 1,
            "time": pd.Timestamp("2024-01-04 09:00:00")
        }
    ])

    return analyze_user_segmentation(pd.DataFrame(rows))


def test_each_user_segment_is_classified(segmentation_results):
    """四类测试用户应分别命中预期群体。"""

    user_summary, _, _ = segmentation_results

    expected_segments = {
        1: "High-Frequency Buyer",
        2: "High Activity Low Purchase",
        3: "Regular Buyer",
        4: "No Purchase"
    }

    assert user_summary["segment"].to_dict() == expected_segments


def test_all_users_belong_to_exactly_one_segment(segmentation_results):
    """每位用户必须且只能属于一个有效群体。"""

    user_summary, segment_counts, _ = segmentation_results

    assert not user_summary["segment"].isna().any()
    assert user_summary["segment"].isin(USER_SEGMENT_ORDER).all()
    assert segment_counts.sum() == user_summary.index.nunique()
    assert (segment_counts == 1).all()


def test_segment_percentages_sum_to_approximately_100(
    segmentation_results
):
    """各群体占比总和应约等于 100%。"""

    _, _, segment_percentages = segmentation_results

    assert segment_percentages.sum() == pytest.approx(100.0)
