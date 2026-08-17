# CHANGELOG

## [1.0.0] — 初始版本

### 项目结构
- `Main_CALIPSO_AL_AP_VFM.m`：主控流水线（文件遍历 → 数据读取 → AOD 计算 → 格点统计 → 趋势分析 → 绘图）
- `8 Draw AOD/`：核心流水线 — AOD 计算、格点化、分类统计、频率统计、区间累积、时间序列、趋势分析、成图
- `1 Read_Pretreatment/`：HDF 读取、文件遍历、筛选条件
- 其余目录：可视化支持（VFM 渲染、层剖面图、相态分类）或测试脚本

### 核心功能
- 批量读取 CALIPSO ALay/APro/VFM HDF 文件
- AOD 格点化累积（`calculate_aod`）
- 气溶胶发生频率统计（`calculate_freq`）
- 分类 AOD（人为/自然/总量）统计（`calculate_classified_aod`）
- 时间序列存储与趋势分析（`ts_append_block`、`ts_run_analysis`）
- 格点图、频率图、分类 AOD 图绘制

## [1.1.0] — 最近更新

### 修改
- **季节空间趋势**：`8 Draw AOD/plot_spatial_trend.m` 改为先计算全部 slope/p 值再绘图，支持季度分解（春/夏/秋/冬）和点击出折线图
- **趋势分析**：`8 Draw AOD/ts_run_analysis.m` 增加 p 值输出，增强统计显著性判断
- **函数文档**：新增 `function_summary.md` 记录核心函数原理
- **项目说明**：新增 `REASONIX.md` 记录项目结构、流水线、注意事项
