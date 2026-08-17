# HDF→MAT 续作计划

## 决策
继续已有工作，不重新从零开始。已有 stage0/stage1 转换和验证结果表明全量转换方案可行；当前中断点主要在树形数据库、索引、增量更新和主函数接入。

## 依据

- `hdf2mat/work_log.md`
- `hdf2mat/stage0_report_20260728.md`
- `hdf2mat/stage1_report_20260728.md`
- `hdf2mat/plan_hdf2mat.md`
- `plan/hdf2mat_execution_plan.md`
- `plan/calipso_mat_db/CALIPSO_MAT_DB_plan.md`

## 续作步骤

1. 复核现有转换产物和失败文件，不重复转换已验证的完整文件。
2. 完成 `产品/年份/日期` 树形目录和 `database_index.mat`。
3. 实现 complete/partial/failed 状态和增量更新。
4. 实现 `load_day_data`，先保持主函数逐文件接口。
5. 只在缓存模式结果通过一致性验证后，替换主函数 HDF 读取。

## 重新开始的条件

只有在现有 MAT 产物无法追溯来源、字段验证无法复现或目录损坏时，才重新执行对应日期/产品，不做全量重跑。
