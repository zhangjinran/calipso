# hdf2mat 阶段 0 清单与开工确认报告（CP0）

**生成时间：** 2026-07-28
**方案：** `F:\CALIPSO_Code_new\plan\hdf2mat_execution_plan.md` v1.0
**执行者：** AutoResearch 执行代理

---

## 1. 数据源清单（Z 盘 2007-2022）

| 产品 | 路径 | 年份数 | 日期目录 | HDF 文件数 | HDF 体积 |
|------|------|:------:|:--------:|:----------:|:--------:|
| 05kmAP (APro) | `Z:\05kmAP\` | 16 | 5459 | **152,745** | 22,572 GB |
| 05kmAL (ALay) | `Z:\05kmAL\` | 16 | 4955 | **139,938** | 11,150 GB |
| VFM | `Z:\VFM\` | 16 | 4992 | **139,550** | 11,647 GB |
| **合计** | | | **15,406** | **432,233** | **45,369 GB (≈45.4 TB)** |

明细见 `inventory_20260728.csv`（15,406 行日期级记录，含 hdf_count 与 total_bytes）。

## 2. 逐年日期目录数（应 vs 实）

| 年份 | 应 | AP | AL | VF | 年份 | 应 | AP | AL | VF |
|:----:|:--:|:--:|:--:|:--:|:----:|:--:|:--:|:--:|:--:|
| 2007 | 365 | 363 | 363 | 362 | 2015 | 365 | 348 | 348 | 348 |
| 2008 | 366 | 346 | 346 | 346 | 2016 | 366 | 313 | 313 | 313 |
| 2009 | 365 | 340 | 340 | 340 | 2017 | 365 | 330 | 330 | 330 |
| 2010 | 365 | 362 | 362 | 362 | 2018 | 365 | 342 | 347 | 347 |
| 2011 | 365 | 337 | 336 | 336 | 2019 | 365 | 362 | 362 | 362 |
| 2012 | 366 | 327 | 327 | **105** | 2020 | 366 | 350 | **74** | **221** |
| 2013 | 365 | 341 | 341 | 341 | 2021 | 365 | 348 | 310 | 229 |
| 2014 | 365 | 343 | **149** | 343 | 2022 | 365 | 307 | 307 | 307 |

**严重缺日年份（与方案 §2 提示一致）：**
- **VFM 2012：仅 105/366 天**（缺 5~12 月，261 天）
- **ALay 2014：仅 149/365 天**（缺 6/18~12/31，216 天）
- **ALay 2020：仅 74/366 天**（缺 292 天）
- **VFM 2020 / 2021：221 / 229 天**（缺 145 / 136 天）
- ALay 2021 缺 55 天、2022 三类均缺 58 天

累计缺失：05kmAP 385 天、05kmAL 889 天、VFM 852 天（相对全年应有天数）。
产品间不同步日期（某产品有、另一产品无）：2012 VFM 222 天、2014 ALay 194 天、2020 AP/AL/VF 大规模不同步、2021 三类不同步、2018-12-07~11 VF 独有 5 天、2011-06-06 AP 独有 1 天、2007-03-01 AL 独有 1 天。完整清单见 `stage0_missing_by_year_20260728.csv`。

## 3. 单日文件数异常（<25 个 HDF/日）

共 **1049 个日期目录**单日 HDF < 25（正常约 29~30），三类产品低文件日高度重合（同日期），属数据源覆盖不全而非下载缺失。最低至 1 个文件/日（如 2011-11-26、2013-06-17、2015-12-14、2016-11-02、2019-12-23、2021-03-14）。这些日期将按 partial 处理。

## 4. 环境与脚本核对（阶段 0 动作 3/6）

- **MATLAB：** `E:\tool\matlab2025a\bin\matlab.exe`（R2025a），可运行
- **config.m：** `HDF_ROOT=Z:\`、`MAT_ROOT=Z:\CALIPSO_MAT_DB`、`YEARS=2007:2022`、产品 `{05kmAP,05kmAL,VFM}` —— 与实际数据一致 ✅
- **生产库脚本语法检查：** convert×2、database×5、verify×2 全部 `OK`；test/test_main_day.m 有 end 匹配类 WARN（性能类，需阶段 1 运行验证）；verify 系列有预分配类 WARN（性能类，不影响正确性）
- **MAT_PATH_FMT 解析：** `Z:\CALIPSO_MAT_DB\data\05kmAP\2007\2007_01_01.mat` ✅
- **现有生产库索引：** `database_index.mat` 存在，**87 条记录**（AP 29 + AL 29 + VF 29，均 2007-01-01），全部 `convert_status=complete`、**全部 `main_test_status=fail`**（与方案基线一致），文件名无重复
- **现有 MAT：** `data\` 下 3 个日 MAT（2007_01_01：AP 817.9 MB、AL 411.6 MB、VF 119.9 MB）——注意：**日合并 MAT 体积显著大于评估期单文件 MAT**（评估 APro 27 MB/文件 → 日 MAT 817.9 MB = 29 文件之和），压缩比评估需以日 MAT 为准重新核实

## 5. 体积与耗时估算（阶段 0 动作 4）

按 2007-01 评估压缩比（AP 17.2%、AL 16.6%、VF 4.5%）与速度（2511 文件 3.9 h）：

| 产品 | HDF 体积 | 估算 MAT 体积 |
|------|:--------:|:------------:|
| 05kmAP | 22,572 GB | 3,882 GB |
| 05kmAL | 11,150 GB | 1,851 GB |
| VFM | 11,647 GB | 524 GB |
| **合计** | **45,369 GB** | **6,257 GB** |

- **磁盘：** `Z:\CALIPSO_MAT_DB` 所在 Z 盘空闲 **7,446.7 GB**；估算 MAT 占 **84%**，余量仅 **1,189 GB（≈16%）** → ⚠️ **磁盘空间偏紧**，属于方案 §4 停止规则项，需负责人决策（是否换盘/分批/是否含 2009 后缩减范围）
- **耗时：** 纯转换 432,233 文件 × 5.59 s ≈ **671 小时 ≈ 28 天**；加验证/索引/重试（×1.5）≈ **42 天**

## 6. 阶段 0 结论

- 只读清单完成：`inventory_20260728.csv`、`stage0_missing_by_year_20260728.csv`、本报告
- 本阶段**未转换任何数据、未删除/移动任何 HDF**（符合方案 §5 动作 5）
- 旧材料"缺 2009"假设**不成立**：2009 目录三类均存在（340 天），以新清单为准
- 已发现需负责人决策事项：见下

## 7. CP1 预备诊断：主函数 fail 的代码级观察（只读，未运行测试）

在等待 CP0 期间做了纯只读的代码审查，为 CP1 定位主函数 `fail` 原因做准备（**未运行 test_main_day、未写索引、未改代码**）：

1. **测试覆盖不足（最可疑）**：`test\test_main_day.m` 的 `extract_hdf_mycell`（L96/110/122）与 `extract_mat_mycell`（L149）**只读每类第一个文件**（`f(1).name` / `d.files{1}`），而方案 §6 明确要求"完整 87 文件主函数对拍，不能只测每类第一个文件"。单文件采样无法代表全天 29 文件，`main_test_status=fail` 可能源于此设计缺陷而非数据问题。
2. **run_pipe 结构**：L271-279 存在 if/end 缩进混乱（`if evalin('caller','exist(''sm'',''var'')')` → `if evalin('caller','~isempty(fieldnames(L2_APro_ref))')` 嵌套，内部 evalin 语句未缩进但**语法合法**）。`checkcode` 报 L271/L272 "可能缺少匹配 END" 提示；MATLAB 显式 `addpath(genpath('calipso_mat_db_scripts'))` 后 `nargin('test_main_day')=1` 解析通过。
3. **L2_APro_ref 未定义风险**：`run_pipe` L272 检查 `fieldnames(L2_APro_ref)`，但若 HDF 读取失败则 `ref_cell{5}` 为空，`names` 循环不会 `assignin` 该变量 → `evalin` 报未定义 → 被 catch 吞掉（只跳过 Classified AOD，不置 fail）。
4. **字段适配器依赖**：`utils\filter_mat_like_getCALIPSO_L2.m` 依赖 `Fun_Change_num`（主函数目录）在路径上，含硬编码例外字段与重命名映射（Latitude→Lat 等），需在阶段 1 验证与 `Fun_getCALIPSO_L2` 输出逐字段一致。
5. **验证方式**：`verify_single_hdf.m` 有预分配类 WARN（性能类），`compare_single` 允许转置比较（`size(v1')==size(v2)`），数值容差 1e-10。

**结论**：主函数 fail 大概率是"测试脚本只测首文件 + 字段适配器未完全覆盖"的组合，需阶段 1 实际运行完整 87 文件对拍后确认。此诊断不影响阶段 0 结论。

### 7.1 只读对拍实测（2026-07-28，未写索引/未改文件）

用 `verify_single_hdf` 同款逻辑（转置容差 + 数值容差 1e-12）对 2007-01-01 **全部 87 文件**做 HDF↔MAT 只读对拍：

| 产品 | 文件通过 | 字段对比 | 字段失败 |
|------|:--------:|:--------:|:--------:|
| 05kmAP | 29/29 | 2349 | **0** |
| 05kmAL | 29/29 | 6003 | **0** |
| VFM | 29/29 | 551 | **0** |

**结论（证据级）**：MAT 数据与源 HDF 逐字段完全一致（含转置与 1e-12 容差），**转换层数据正确性得到证实**。主函数 `fail` 根因不在数据转换，而在测试脚本设计（只测首文件）、字段适配器（`filter_mat_like_getCALIPSO_L2` 的例外字段/重命名映射）、或计算管道（`run_pipe` 嵌套结构、`L2_APro_ref` 未定义风险）层面。

### 7.2 只读复现 test_main_day 数据层对比（2026-07-28，未写索引/未改文件）

内联 `test_main_day.m` 的 HDF 参照提取（`Fun_getCALIPSO_L2`）+ MAT 提取（`filter_mat_like_getCALIPSO_L2`）+ 逐字段对比（`compare_single` 同款），去掉 `db_update`/`logger` 后实际运行：

| 项 | HDF 参照 | MAT 适配 | 结果 |
|----|:---:|:---:|------|
| ALay 字段数 | 62 | 210 | 共同 56，其中 **53 个数值差异** |
| APro 字段数 | 33 | 84 | 共同 22，尺寸差异如 `Aerosol_Layer_Fraction [880 399] vs [399 898]` |
| VFM 字段数 | 6 | 22 | 共同 5，`Feature_Classification_Flags [880 5515] vs [5515 898]`、`Lat [880 1] vs [1 898]` |

**主函数 fail 根因（实测确认，三层）：**
1. **数据方向（转置）不匹配**：`convert_single_hdf` 对 2D 字段转置存储，`filter_mat_like_getCALIPSO_L2` 未能将部分字段转回主函数方向（APro `[880 399] vs [399 898]`、VFM `[880 5515] vs [5515 898]` 即证据）。
2. **廓线裁剪不一致**：HDF 侧 `Fun_getCALIPSO_L2` 内部裁到 880；MAT 侧 `Fun_Change_num` 从 898 裁到 880，但 `Lat/Lon` 等字段未同步（VFM `profile_number` 差 18、`profile_start_end` 差 12）。
3. **字段集不齐**：MAT 适配保留全字段（210/84/22），主函数只消费子集（62/33/6）；适配器缺 APro 侧 `Altitudes_Profile`、`alpha_O3_interpolation_*`、`beta_m_interpolation_*` 等 11 个 HDF 独有字段映射。

## 7.3 主函数读取逻辑深度分析（2026-07-28，纯只读）

对 `Fun_getCALIPSO_L2.m`（1875 行，9 个产品分支）、`readHDF.m`、`Fun_Change_num.m` 做代码级分析，**修正了 §7.2 的部分归因并给出精确修复方向**：

### 7.3.1 数据方向（§7.2 归因①确认，且发现更深的矛盾）
- `readHDF.m:191-193`：2D 数据一律转置 → 主函数输出 = `[廓线 × 层]`（行=廓线）。
- 三重证据：`lat_whole(:,1)/(:,3)`（:32-33）、`Lat(1,1)` 匹配（:75-77）、`top_right_80km(i,j)` i=廓线（:57-63）。
- **方向矛盾**：存量 MAT 库（旧 hdf2mat_full 生成）= `[层×廓线]`；当前 `convert_single_hdf.m:33-34` 转置存储 = `[廓线×层]`；`filter_mat_like_getCALIPSO_L2.m` 假设 `[features×profiles]` 且全程不转置（:33-46）。三者互相矛盾 → **修复必须先确定基准方向**（建议：以主函数 `[廓线×层]` 为基准，重建 MAT 时用当前 convert_single_hdf 的方向，filter 相应加转置）。

### 7.3.2 廓线裁剪符号陷阱（§7.2 归因②细化）
- ALay 分支 `indA = indA + change_num(1)`（:65，前裁）；**APro/VFM/CLay/MLay 分支 `indA = indA - before_cut`（:444/791/1110/1354/1545，符号相反，前扩）**。
- `Fun_Change_num` 输出 `change_num(1)=mod(Row_Start,16)-1∈[0,15]`、`change_num(2)=mod(m-c1,16)`；实测 `[-14,-4]`，`898→880`。
- `filter_mat_like_getCALIPSO_L2.m:130` 用了 ALay 的 `+trim_s` 符号，对 APro/VFM 错误 → 修复需按产品分支区分符号。
- 另有 psl 语义不一致：ALay 当 psl(2)=末廓线（:46-47），其余分支当条数（:448/1114/1549）；`test_main_day.m:102` 传条数。

### 7.3.3 缺失字段映射（§7.2 归因③完整化）
| 主函数字段 | 来源 | 适配器缺失原因 |
|---|---|---|
| `Altitudes_Profile` | metadata (APro :1248) | convert 不读 Vdata；rename_map 无此映射 |
| `beta_m_interpolation_532/1064` | Molecular_Number_Density × 截面 (APro :1236-1237) | filter 不计算派生 |
| `alpha_O3_interpolation_532/1064` | Ozone_Number_Density × 截面 (:1238-1239) | filter 不计算派生 |
| `horizontal_resolution_Initial_detection_surface` / `detection_frequency_5km` | Surface_Elevation_Detection_Frequency 位解码 (ALay :108-114) | filter 不派生 |
| `Column_COD` / `Column_COD_532` | 重命名自 Column_Optical_Depth_Cloud_532 (:148→327 / :1149→1250) | **rename_map 缺此映射** |
| `fileName` | 主函数输出 | convert 存小写 `filename`（:19），无映射 |
| `lidar_Data_Altitude` | metadata (ALay :94) | convert 不读 Vdata |
| -9999→NaN | APro Molecular/Ozone (:1220/1225) | convert 未做 |

### 7.3.4 其他发现
- `ss*` 字段（ALay :279-296）按廓线维×15 读取，filter 直接透传（:81-84）导致尺寸不符。
- 纬度边界：filter 用 `>=/<=`（:51-56），主函数用 `>/<`（:36-40）+ round(...,4) → 边界上差 1 条。
- `Day_Night_Flag` **主函数不存在**，仅 filter 生成（:157-161）——非主函数消费项，可忽略。

### 7.3.5 AER_RETRA_CASE 主流水线适配预备（阶段 6 依据）
`master_Chapter5_Fig5_1.m`（2007-01-01~2008-01-01，全球 5°×5°，只用 05kmAP）：
- **只用 7 个 SDS 字段 + 1 个 metadata**：Extinction_Coefficient_532、Total_Backscatter_Coefficient_532、Particulate_Depolarization_Ratio_Profile_532、Atmospheric_Volume_Description、Longitude、Latitude、Profile_Time、metadata `Lidar_Data_Altitudes`。
- 字段名零差异（makeValidName 后不变）；主流水线自带方向守卫 `if size(Ext,1)==399, Ext=Ext'; end`（master:140-143）**恰好适配 MAT 方向**。
- **最大缺口**：`Lidar_Data_Altitudes` 来自 /metadata（Vdata），`convert_single_hdf` 不读 → 适配器须补此字段（建议 convert 阶段写入 MAT）。
- **build_log 缓存风险**：`find_cached_run`（master:715-791）按 date_start/date_end 或 input_files 匹配，无 TTL/版本校验 → 数据源切换后会命中旧 HDF 缓存；阶段 6 须把"数据源类型 + MAT 库索引签名"加入匹配键（方案 §11 要求）。
- 产出：`output_integrated/build_log.mat`、`cache/*.mat`、`results/Figure_5_1.png`。

### 7.4 修复方案只读验证（2026-07-28，决定性）

在内存中实现 §7.3 的修复方向（MAT 按参照廓线窗口截取廓线维 + 2D 转置回 `[廓线×特征]`），对 2007-01-01 三类 `files{1}` 与 `Fun_getCALIPSO_L2` HDF 参照对比：

| 产品 | 参照字段 | 修复版字段 | 共同 | 数值差异 | 尺寸差异 | 参照独有 |
|------|:---:|:---:|:---:|:---:|:---:|------|
| APro | 33 | 82 | 18 | **0** | **0** | 15（Altitudes_Profile、beta_m/alpha_O3_interpolation_*、fileName、Column_COD_532、SAOD/TAOD 等） |
| ALay | 62 | 208 | 51 | **0** | 4 | 11（Column_COD、SAOD/TAOD、lidar_Data_Altitude、fileName 等） |
| VFM | 6 | 20 | 1（FCF） | **0** | **0** | 5（Lat、Lon、fileName、profile_number、profile_start_end） |

**结论（修复方案验证成立）：**
1. 方向修复正确：MAT `[特征×廓线]` 截取后转置 `[廓线×特征]`，与主函数方向一致，**共同字段数值全部一致**（APro Extinction_Coefficient_532 等、VFM Feature_Classification_Flags [880×5515]）。
2. 廓线窗口匹配：VFM/APro 用 ALay psl=[1121,880] → `profile_start_end=[1121,2000]` 与参照完全一致（原 filter 差 18 条廓线的问题消除）。
3. 剩余差异全部为**元数据/派生字段**（§7.3 已列：Altitudes_Profile、interpolation 系列、Column_COD 映射、fileName 大小写、Lat/Lon reshape、profile_number/start_end）——修复版适配器补这些映射后即可通过主函数对拍。
4. VFM 分支需传 psl（精确纬度匹配 `find(lat_whole==lat_lim)` 仅当纬度恰好命中时可用，:1492-1493）——测试脚本需按主函数顺序（ALay→APro/VFM 传 psl）。

**CP1 修复清单（待负责人批准阶段 1 后实施）：**
- 重写 `utils\filter_mat_like_getCALIPSO_L2.m`：按廓线窗口截取廓线维 → 2D/3D 转置回 `[廓线×特征]` → 补字段映射（Altitudes_Profile、Column_COD(_532)、fileName、Lat/Lon reshape、profile_number/start_end）→ 补派生字段（beta_m/alpha_O3_interpolation、-9999→NaN）。
- 修正 `test\test_main_day.m`：按主函数顺序传 psl；支持完整 87 文件对拍（当前只测首文件，违方案 §6）。

## 8. 等待 CP0 确认

### 8.1 负责人已确认的决策（2026-07-28）

| 决策项 | 负责人决定 |
|--------|-----------|
| 阶段 1 | **暂缓**，先看报告（`F:\CALIPSO_Code_new\hdf2mat\stage0_report_20260728.md`） |
| MAT 落盘位置 | `Z:\CALIPSO_MAT_DB`，**分批转换**（每批核对空间） |
| 年份范围 | **全量 2007-2022（含 2009）** |
| 缺失日期 | 负责人表示可尝试补数据；已生成补数据清单 `stage0_missing_dates_for_download_20260728.txt` |

### 8.2 缺失日期清单（供补数据使用）

`stage0_missing_dates_for_download_20260728.txt`（`F:\AER_RETRA_CASE\数据完整性报告\` 备份）按"年份+缺失模式"分类：

- **第一部分：产品间不同步缺失（860 天）——其他产品有数据，大概率可补**
  - 缺 AL（仅 ALay 缺，AP/VF 有）：373 天（2014 年 194 天、2020 年 145 天、2021 年 34 天）
  - 缺 VF（仅 VFM 缺，AP/AL 有）：338 天（**2012 年 222 天**为主）
  - 缺 AL+VF（仅 APro 有）：139 天（2020 年 134 天）
  - 缺 AP：8 天；缺 AP+AL：2 天
- **第二部分：整日缺失（375 天）——三类都无，可能卫星无数据**

交叉核对：清单与累计缺失天数完全一致（AP 385 / AL 889 / VF 852）。`stage0_all_missing_days_20260728.csv` 为逐日明细（5844 行）。

### 8.3 待负责人确认的剩余决策

| 决策项 | 状态 |
|--------|------|
| HDF 保留策略 | 未确认（方案默认全程保留，CP6 前不删） |
| 主函数切换范围 | 未确认（先频率链路？） |
| 低文件日处理（1049 个 <25 文件日） | 未确认（按 partial？） |
| 阶段 1 启动 | 待报告审阅后决定 |
