"""加载处理后的行为数据，并执行基础质量检查。"""

import pandas as pd

from .config import DATA_FILE_PATH


def load_data():
    """从配置路径读取行为数据。"""

    df = pd.read_csv(DATA_FILE_PATH)

    print("Data loaded successfully!")

    return df


def prepare_datetime(df):
    """将 time 列原地转换为时间类型。"""

    df["time"] = pd.to_datetime(df["time"])


def check_data_quality(df):
    """输出各字段缺失值数量和完全重复行数量。"""

    print("\nMissing values:")
    print(df.isnull().sum())

    print("\nDuplicate rows:")
    print(df.duplicated().sum())
