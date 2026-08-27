# Taobao User Behavior Analysis

这是一个基于淘宝用户行为数据完成的端到端分析项目。项目使用 Python 进行数据处理和基础分析，使用 PostgreSQL 保存全量明细并复算指标，最后通过 Power BI 展示用户活跃、购买转化、复购结构、行为路径和品类偏好。

完整的业务分析、指标口径和 Power BI 页面说明见：[项目分析报告](docs/项目分析报告.md)。

## 项目概况

| 指标 | 数量 |
| --- | ---: |
| 行为记录 | 12,256,906 |
| 用户 | 10,000 |
| 商品 | 2,876,947 |
| 商品类别 | 8,916 |

数据包含 `time`、`user_id`、`item_id`、`item_category` 和 `behavior_type` 五个字段。行为编码为：`1` 浏览、`2` 收藏、`3` 加购、`4` 购买。

## 核心发现

- 浏览占全部行为的 94.24%，用户主要在 20—22 时活跃。
- 按时间顺序计算，浏览、加购到购买的整体转化率为 75.17%，主要流失发生在浏览到加购阶段。
- “浏览后直接购买”和“浏览—加购—购买”合计贡献 77.47% 的购买行为。
- 8,148 名用户购买过两次及以上，复购是这批用户的重要特征。
- 加购深度和用户活跃度与购买倾向明显正相关，但不能直接解释为因果关系。

## 技术实现

| 模块 | 作用 |
| --- | --- |
| Python / pandas | 数据读取、质量检查、行为分析、用户分群和静态图表 |
| PostgreSQL 17 | 全量明细存储、指标复算和聚合数据生成 |
| Power BI | 8 个交互页面，展示时段、趋势、活跃度、复购、漏斗、路径、行为深度和品类偏好 |
| pytest | 使用小型模拟数据验证核心逻辑，不加载完整 CSV |

Python 与 SQL 使用相同的漏斗、路径和用户分群规则，核心结果已经完成核对。Power BI 使用 SQL 生成的 12 个聚合数据集，不直接加载千万级明细。

## 项目结构

```text
src/        Python 数据处理、分析和可视化代码
tests/      核心逻辑测试
sql/        PostgreSQL 建表、导入和分析 SQL
database/   数据库架构与复现说明
powerbi/    聚合查询、CSV、刷新脚本和搭建指南
docs/       项目分析报告和结果图片
notebooks/  分析演示 Notebook
```

## 运行 Python 分析

```powershell
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
python -m src.main
```

运行测试：

```powershell
python -m pytest -q
```

本地原始 CSV 约 492 MB，已通过 `.gitignore` 排除。日常查看文档或运行测试时不需要加载完整数据。

## PostgreSQL

数据库层包括规范化表结构、受保护的全量导入流程和四组分析 SQL。当前数据库已经导入完成，不能直接重复执行全量导入脚本。

详细的建库、导入、校验和重建方法见：[数据库说明](database/README.md)。

## Power BI

刷新全部看板数据：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\powerbi\refresh_exports.ps1
```

刷新脚本会从 PostgreSQL 重新生成 12 个聚合 CSV，完成行数校验后再替换旧文件。不要手动修改 `powerbi/data/` 中的数据。

数据集说明和页面清单见：[Power BI 说明](powerbi/README.md)。具体搭建方法见：

- [Module 2 Dashboard Guide](powerbi/module_2_build_guide.md)
- [Module 4 Dashboard Guide](powerbi/module_4_build_guide.md)

## 主要文档

- [项目分析报告](docs/项目分析报告.md)：完整分析过程、结果、Power BI 页面和业务建议。
- [数据库说明](database/README.md)：数据库结构、导入保护、校验和复现命令。
- [Power BI 说明](powerbi/README.md)：聚合数据集、刷新方法、建模规则和页面清单。

## 分析限制

- 重复记录目前保留，需要确认数据生成规则后再决定是否去重。
- 数据没有价格、数量和订单金额，不能计算销售额、客单价或用户消费金额。
- 商品和类别只有编号，无法解释具体商品含义。
- 数据没有用户属性、活动标签和会话编号，不能进行人口画像、活动归因或页面跳出分析。

## 当前状态

Python、PostgreSQL、12 个 Power BI 聚合数据集、8 个看板页面和项目分析报告均已完成。后续工作主要是补充业务字段、统一看板主题、记录刷新日期，并根据需要发布 Power BI 报告。
