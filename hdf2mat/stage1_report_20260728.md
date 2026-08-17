# hdf2mat 阶段 1 单日迁移报告（CP1）

**日期：** 2026-07-28（实际执行 2026-08-02）
**回归日期：** 2007-01-01
**方案：** `F:\CALIPSO_Code_new\plan\hdf2mat_execution_plan.md` v1.0 §6

---

## 1. 单日转换（生产库脚本，已修复）

| 产品 | HDF 源 | MAT 文件 | 转换 | status | 耗时 |
|------|:------:|---------|:-----:|:------:|:----:|
| 05kmAP | 29 | `Z:\CALIPSO_MAT_DB\data\05kmAP\2007\2007_01_01.mat` (817.9 MB) | 29/29 | complete | 284.6 s |
| 05kmAL | 29 | `Z:\CALIPSO_MAT_DB\data\05kmAL\2007\2007_01_01.mat` (411.6 MB) | 29/29 | complete | 172.1 s |
| VFM | 29 | `Z:\CALIPSO_MAT_DB\data\VFM\2007\2007_01_01.mat` (119.9 MB) | 29/29 | complete | 75.6 s |

**hdf2mat_day.m 修复（方案 §6 第 2/3 点）：**
- ✅ 索引去重：重复执行 87 → 87 条，不无限追加
- ✅ status 真实：complete/partial/failed 按 success/n_total 写入（不再无条件 complete）
- ✅ 失败文件保留 day.files 槽位（含 convert_error），不丢文件不错位

## 2. 字段验证（verify_day）

| 产品 | 结果 |
|------|:----:|
| 05kmAP | 29/29 通过 |
| 05kmAL | 29/29 通过 |
| VFM | 29/29 通过 |

（verify_single_hdf 转置容差 + 数值容差 1e-12；87 个文件全部字段一致）

## 3. 主函数对拍（test_main_day v2，完整 87 文件）

- **数据层：87/87 文件通过**（ALay 29 + APro 29 + VFM 29，逐文件 compare_single，共同字段零差异）
- **计算管道（首文件）：AOD / FREQ / Classified AOD 全部零差异**（矩阵与计数矩阵 max diff=0）
- 总耗时 241.7 s

**主函数 fail 根因（已修复）：**
1. `convert_single_hdf.m` 的 `sd.getInfo` 参数顺序错误 → 转置从未生效 → MAT 为 HDF 原始方向 `[特征×廓线]`，而 `readHDF` 输出 `[廓线×特征]` → 方向不一致
2. `filter_mat_like_getCALIPSO_L2.m`（旧版）未转置、未按纬度截取 HA/LTA 算 `Fun_Change_num`、APro/VFM 未用 `profile_start_and_length`、缺派生短名（TAOD/SAOD/COD/Altitudes_Profile）与 fileName
3. `test_main_day.m`（旧版）只测每类第一个文件（违方案 §6"完整 87 文件对拍"）

**已修复文件（均备份于 `F:\AER_RETRA_CASE\calipso_mat_db_backup_20260728\`）：**
- `convert\hdf2mat_day.m`：索引去重 + status 真实 + 失败槽位
- `utils\filter_mat_like_getCALIPSO_L2.m`（v4.1）：方向转置 + psl 参数 + 纬度截取 + Fun_Change_num 裁剪 + 派生短名 + fileName + Altitudes_Profile
- `test\test_main_day.m`（v2）：完整 87 文件对拍 + run_pipe 矩阵比较

## 4. 索引状态（database_index.mat）

| 项 | 值 |
|----|----|
| 总记录 | 87（AP 29 + AL 29 + VF 29） |
| convert_status | complete=87, failed=0 |
| verify_status | pass=87, fail=0 |
| main_test_status | **pass=87, fail=0**（原全 fail 已修复） |
| 文件名重复 | 0 |
| 查询 | date=87、product(VFM)=29、verify_pass=87 均正常 |

## 5. 磁盘

- Z 盘空闲 7,446.7 GB（开始）→ 7,446.5 GB（结束，单日 MAT 增加 ~1.35 GB）
- 单日 MAT 体积：AP 817.9 + AL 411.6 + VF 119.9 = 1,349.4 MB

## 6. 结论

**阶段 1（单日完整生产闭环）通过。** 转换、验证、主函数对拍、索引一致性全部符合方案 §6 通过条件。`main_test_status` 由全 fail 转为全 pass，主函数 fail 根因已定位并修复（适配器方向/裁剪/字段映射问题，非数据问题）。

**待负责人决定（CP1 后）：**
1. 是否进入阶段 2（2008-01 试点）？
2. 阶段 1 发现的 `convert_single_hdf.m` getInfo 参数顺序 bug 是否修复并重转全量？（当前适配器已绕过该 bug，MAT 方向保持 HDF 原始；若修复 convert 需重转全部 MAT，改动大，建议保持现状）
