from unittest.mock import patch

import pandas as pd

from src.config import DATA_FILE_PATH
from src.data_processing import (
    check_data_quality,
    load_data,
    prepare_datetime
)


def test_load_data_uses_configured_path_without_reading_real_csv():
    expected = pd.DataFrame({
        "user_id": [1, 2],
        "behavior_type": [1, 4]
    })

    with patch(
        "src.data_processing.pd.read_csv",
        return_value=expected
    ) as mocked_read_csv:
        result = load_data()

    mocked_read_csv.assert_called_once_with(DATA_FILE_PATH)
    pd.testing.assert_frame_equal(result, expected)


def test_prepare_datetime_converts_time_column():
    df = pd.DataFrame({
        "time": ["2024-01-01 09:30:00", "2024-01-02 18:45:00"]
    })

    prepare_datetime(df)

    assert pd.api.types.is_datetime64_any_dtype(df["time"])
    assert df["time"].tolist() == [
        pd.Timestamp("2024-01-01 09:30:00"),
        pd.Timestamp("2024-01-02 18:45:00")
    ]


def test_check_data_quality_reports_missing_values_and_duplicates(capsys):
    df = pd.DataFrame({
        "user_id": [1, 1, 2],
        "item_id": [10, 10, None]
    })

    check_data_quality(df)

    output = capsys.readouterr().out
    assert "Missing values:" in output
    assert df.isnull().sum().to_string() in output
    assert "Duplicate rows:\n1" in output
