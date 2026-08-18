"""按既定顺序执行完整分析与图表生成流程。"""

from .analysis import (
    analyze_purchased_categories,
    analyze_purchased_items,
    calculate_behavior_distribution,
    calculate_chronological_funnel,
    calculate_hourly_trend,
    display_dataset_summary
)
from .data_processing import (
    check_data_quality,
    load_data,
    prepare_datetime
)
from .purchase_paths import analyze_purchase_behavior_paths
from .user_segmentation import analyze_user_segmentation
from .visualization import (
    plot_behavior_distribution_chart,
    plot_hourly_trend_chart,
    plot_purchase_behavior_path_chart,
    plot_purchased_category_chart,
    plot_user_funnel_chart,
    plot_user_segmentation_chart
)


def main():
    """串联数据读取、质量检查、分析和可视化。"""

    # 基础概览与购买品类分析
    df = load_data()
    display_dataset_summary(df)

    purchase_data = analyze_purchased_items(df)
    top_categories = analyze_purchased_categories(purchase_data)
    plot_purchased_category_chart(top_categories)

    behavior_count = calculate_behavior_distribution(df)
    plot_behavior_distribution_chart(behavior_count)

    # 时间字段必须先转换，才能执行漏斗、趋势和用户分群分析。
    check_data_quality(df)
    prepare_datetime(df)

    funnel_counts = calculate_chronological_funnel(df)
    plot_user_funnel_chart(*funnel_counts)

    hourly_counts = calculate_hourly_trend(df)
    plot_hourly_trend_chart(*hourly_counts)

    # 用户分群与购买路径属于综合分析结果。
    user_segmentation_results = analyze_user_segmentation(df)
    plot_user_segmentation_chart(*user_segmentation_results[1:])

    purchase_path_results = analyze_purchase_behavior_paths(
        df,
        purchase_data
    )
    plot_purchase_behavior_path_chart(*purchase_path_results)


if __name__ == "__main__":
    main()
