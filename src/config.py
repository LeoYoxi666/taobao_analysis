"""集中管理输入输出路径、行为编码和图表参数。"""

# 数据输入
DATA_FILE_PATH = "data/user_behavior_processed.csv"

# 图表输出路径
BEHAVIOR_DISTRIBUTION_PATH = "docs/behavior_distribution.png"
USER_FUNNEL_PATH = "docs/user_funnel.png"
TOP_CATEGORIES_PATH = "docs/top10_purchased_categories.png"
HOURLY_TREND_PATH = "docs/hourly_behavior_trend.png"
PURCHASE_PATH_PATH = "docs/purchase_behavior_paths.png"
USER_SEGMENTATION_PATH = "docs/user_segmentation.png"

# 用户行为编码
VIEW_BEHAVIOR = 1
FAVORITE_BEHAVIOR = 2
CART_BEHAVIOR = 3
PURCHASE_BEHAVIOR = 4

# 分析与图表参数
TOP_N = 10
HIGH_ACTIVITY_QUANTILE = 0.80
HIGH_PURCHASE_QUANTILE = 0.80
FIGURE_SIZE = (9, 5)
BEHAVIOR_DISTRIBUTION_FIGURE_SIZE = (8, 5)
HOURLY_TREND_FIGURE_SIZE = (10, 5)
