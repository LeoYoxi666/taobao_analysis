import pandas as pd

from .config import DATA_FILE_PATH


def load_data():
    df = pd.read_csv(DATA_FILE_PATH)

    print("Data loaded successfully!")

    return df


def prepare_datetime(df):
    df["time"] = pd.to_datetime(df["time"])


def check_data_quality(df):
    print("\nMissing values:")
    print(df.isnull().sum())

    print("\nDuplicate rows:")
    print(df.duplicated().sum())
