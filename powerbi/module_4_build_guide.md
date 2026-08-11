# 看板一 · 模块四搭建指南

## 页面标题

**模块四：用户转化路径与行为偏好分析**

最终页面名称：

1. `模块四-购买转化漏斗`
2. `模块四-行为路径`
3. `模块四-行为深度`
4. `模块四-品类偏好`

## 导入数据

在 Power BI Desktop 中依次选择：**主页 → 获取数据 → 文本/CSV**，导入：

- `powerbi/data/purchase_funnel.csv`
- `powerbi/data/behaviour_transition_matrix.csv`
- `powerbi/data/behaviour_depth_conversion.csv`
- `powerbi/data/activity_category_preference.csv`

## 第 1 页：转化漏斗

视觉对象选择 **漏斗图**：

- 类别：`stage_name`
- 值：`user_count`
- 可选工具提示：`conversion_from_previous`、`conversion_from_view`

先在数据视图中选中 `stage_name`，使用 **列工具 → 按列排序 → stage_order**。
值区域只保留 `user_count`，不要把转化率放入值区域。

## 第 2 页：用户行为跳转概率

视觉对象选择 **矩阵**：

- 行：`current_behaviour_name`
- 列：`next_action_name`
- 值：`transition_probability`
- 可选工具提示：`transition_count`

条件格式选择 **背景色 → 渐变**：

- 最小值：`#FFF3E0`
- 中间值：`#FB8C00`
- 最大值：`#B71C1C`

将 `transition_probability` 设置为百分比、保留 2 位小数。
关闭行小计和列小计，避免把不同起始行为的概率相加。

## 第 3 页：行为深度与购买率

视觉对象选择 **折线图和簇状柱形图**：

- X 轴：`depth_bin_label`
- 列 Y 轴：`user_count`
- 行 Y 轴：`purchase_rate`
- 工具提示：`purchase_user_count`

添加 **切片器**，字段使用 `behaviour_name`。

`user_count` 的汇总方式必须选择 **求和**，不能选择 **计数**。切片器一次选择
一个行为，避免把不同类型的购买率相加。

先在数据视图中选中 `depth_bin_label`，使用 **列工具 → 按列排序 → depth_bin_order**。

## 第 4 页：不同活跃度用户的品类偏好 Top 5

视觉对象选择 **表**：

- `activity_segment`
- `preference_rank`
- `category_id`
- `interaction_count`
- `interaction_share`

将 `interaction_share` 设置为百分比、保留 2 位小数。按 `activity_segment_order`、`preference_rank` 升序展示。

在表视觉对象中，`preference_rank`、`category_id` 和 `interaction_share`
使用 **不汇总**；`interaction_count` 使用 **求和**。关闭底部总计。

## 口径说明

- `Exit` 表示该用户数据序列中的最后一次行为，不等同于严格的会话退出。
- 当前源数据只有 `category_id`，没有品类中文名称，因此品类偏好页展示品类编号。
