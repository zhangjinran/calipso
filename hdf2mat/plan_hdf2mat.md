# 树索引 MAT 数据库 — 可行性说明

## 现状描述

### 原始数据处理方式

CALIPSO_Code_new 项目的主流水线 `Main_CALIPSO_AL_AP_VFM.m` 每处理一个文件就调用一次 `Fun_getCALIPSO_L2()`，内部使用 `hdfread()` 读取 HDF4 EOS Swath 格式的三类数据：

| 数据类型 | 产品 | 文件路径 | 字段数 |
|----------|------|---------|--------|
| **APro** | 5km 气溶胶廓线 | `Z:\05kmAP\{年份}\{yyyy_mm_dd}\*.hdf` | 82 |
| **ALay** | 5km 气溶胶层 | `Z:\05kmAL\{年份}\{yyyy_mm_dd}\*.hdf` | 208 |
| **VFM** | 垂直特征掩膜 | `Z:\VFM\{年份}\{yyyy_mm_dd}\*.hdf` | 20 |

### Z 盘数据规模

| 项目 | 数值 |
|------|------|
| 数据年份 | 2007~2022（缺 2009），共 15 年 |
| 平均每年每类文件数 | ~10,200 |
| 总 HDF 文件数 | ~450,000 |
| 总 HDF 体积 | ~24 TB |
| 单文件平均大小 | 80~150 MB |

### hdf2mat 评估结论

已完成 1 天测试和 1 月验证：

| 指标 | 结果 |
|------|------|
| 字段完整性 | 99% 通过（仅 `Properties` 因 HDF4 维度表类型不支持而跳过） |
| 压缩比 | HDF 278 GB → MAT 38 GB（**13.6%**） |
| 读取速度 | hdfread 全部 SDS → load 全量 MAT，提速 **2~40 倍** |
| Vdata | MATLAB HDF4 V 接口（hdfh/hdfv）不可用，Vdata 未读取 |
| 转换失败率 | 3/2511 文件（0.12%），均为计时环节额外 hdfread 出错，非转换本身 |

### 当前 MAT 存储方式

```
hdf2mat/
├── data/
│   ├── month_test/          ← 1 月验证产出，2511 个散乱 MAT
│   ├── 05kmAP_2007-01-01_full.mat  ← 1 天测试产出
│   └── ...
├── scripts/
│   ├── run_day_test.m       ← 1 天测试脚本
│   ├── run_month_test.m     ← 1 月验证脚本
│   └── utils/
│       ├── hdf2mat_full.m   ← HDF → MAT 转换
│       └── verify_full.m    ← 完整性验证
├── result/
│   ├── results_day1.txt
│   └── results_month1.txt
└── work_log.md
```

### 存在的问题

1. **文件散乱**：所有 MAT 混在同一个目录，无组织
2. **无索引**：查找特定日期需要遍历文件名
3. **无增量更新**：新增数据需手动扫描
4. **Vdata 缺失**：MATLAB HDF4 接口不支持读取

---

## 改进方案

### 总体结构

```
CALIPSO_MAT_DB/                 ← MAT 数据库根目录
├── data/                       ← 树形数据目录
│   ├── 05kmAP/
│   │   ├── 2007/
│   │   │   ├── 2007_01_01.mat
│   │   │   ├── 2007_01_02.mat
│   │   │   └── ...
│   │   ├── 2008/
│   │   └── ...
│   ├── 05kmAL/
│   │   └── 2007/
│   └── VFM/
│       └── 2007/
├── database_index.mat           ← 索引账本（见下方）
├── logs/                        ← 运行日志
└── scripts/                     ← 转换/维护脚本
```

### HDF → MAT 内部结构

每个日 MAT 文件结构：

```matlab
% 2007_01_01.mat 内部
day =
  meta:  [struct]       ← 转换元数据
  files: {N×1 cell}     ← 当天所有 HDF 文件的数据

% meta 字段
day.meta.source_date    = '2007-01-01'
day.meta.source_number  = 29        % 当天 HDF 总数
day.meta.converted      = 29        % 成功转换数
day.meta.status         = 'complete'  % 'complete' | 'partial' | 'failed'
day.meta.convert_time   = 120.5      % 转换耗时(秒)
day.meta.hdf_size       = 157286400  % 原始 HDF 总大小

% files 结构
day.files{1}.filename   = 'CAL_LID_L2_05kmAPro-...2007-01-01T00-22-49ZN.hdf'
day.files{1}.Ext        = [N×M double]
day.files{1}.Back       = [N×M double]
day.files{2}.filename   = 'CAL_LID_L2_05kmAPro-...2007-01-01T01-09-14ZD.hdf'
day.files{2}.Ext        = ...
```

**相比 `file1`/`file2` 的好处：**
- `files{i}.filename` 直接看到来源 HDF 文件名
- `files{i}` 可以传到主函数，变量名不冲突
- 结构统一，后续批量处理方便

### database_index.mat

轻量索引表（几十 MB），不是数据仓库，是**账本**：

```matlab
index =
  entries: [N×1 struct]    ← 每条记录对应一个日 MAT

  % 每个记录的字段
  .date        = '2007-01-01'
  .type        = '05kmAP'
  .mat_path    = '05kmAP/2007/2007_01_01.mat'
  .status      = 'complete'   % 'complete' | 'partial' | 'failed'
  .source_num  = 29
  .converted   = 29
  .hdf_size_mb = 153570
  .mat_size_mb = 27180
  .convert_sec = 120.5
```

**解决的问题：**
```
❌ 目录树不能回答：
   "2007-2022 哪些日期转换失败？"
   "某月转换了多少文件？"
   "总体积多大？"

✅ database_index.mat 可以：
   一条命令查到所有失败的日期
   按年月分组统计
   检查数据完整性
```

### 增量更新带状态检测

原方案：`if MAT exists → skip`

改进后：

```matlab
if isfile(mat_path)
    day_data = load(mat_path, 'meta');
    if strcmp(day_data.meta.status, 'complete') ...
        && day_data.meta.converted == day_data.meta.source_number
        skip = true;     % 完整转换，跳过
    else
        redo = true;     % 部分转换或失败，重做
    end
end
```

防止"转换了 28/30 个文件就中断，生成的残片 MAT 被当作已完成"的情况。

### 目录结构变更

```
hdf2mat/                         ← 当前评估项目
├── plan_hdf2mat.md
├── work_log.md
├── scripts/
│   ├── batch_convert.m          ← 批量转换入口
│   ├── rebuild_index.m          ← 重建 database_index.mat
│   └── utils/
│       ├── hdf2mat_full.m
│       ├── verify_full.m
│       └── load_day_data.m

CALIPSO_MAT_DB/                  ← 实际生产数据库（与 hdf2mat 分开）
├── data/
│   ├── 05kmAP/2007/...
│   ├── 05kmAL/2007/...
│   └── VFM/2007/...
├── database_index.mat
└── logs/

## 1. 可行性分析

### 1.1 每天合并为一个 MAT

**现状：** 每个 HDF 文件对应一个 MAT（如 1 月 2511 个 MAT）。

**方案：** 每天同类型的所有 HDF 合并为一个 MAT（如 1 月 93 个 MAT，压缩 27 倍）。

**技术上可行吗？** 可行。MATLAB 的 `save -v7.3` 支持单个文件中存储多个变量，每个变量可以是一个数组或结构体。只需将同一天多个 HDF 文件的数据存入同一个结构体数组即可。

```matlab
% 存储结构示意
day = struct();
day.meta.source_date   = '2007-01-01';
day.meta.source_number = 29;
day.meta.converted     = 29;
day.meta.status        = 'complete';
day.files = cell(29, 1);
day.files{1} = struct('filename', 'CAL...ZN.hdf', 'Ext', [], 'Back', []);
save('2007_01_01.mat', 'day', '-v7.3');
```

**风险：** 单文件体积增大（APro 一天约 28 MB × 29 文件 = ~812 MB）。但 `-v7.3` 格式支持超大文件（>2 GB），可接受。如果单日超过 2 GB，拆为上午/下午两个 MAT。

### 1.2 主函数兼容性

**主函数逐文件循环：**
```matlab
for j = 1:size(File_select,2)
    filename = File_select(j).name;
    mycell{j} = Fun_getCALIPSO_L2(filename, ...);
end
```

**改成按日加载：**
```matlab
day_data = load('hdf2mat/data/05kmAP/2007/2007_01_01.mat');
% day_data 包含当天所有文件的数据
% 拆成逐文件格式传给主函数
```

有两种兼容方式：

| 方式 | 改动量 | 说明 |
|------|--------|------|
| **A) 保持逐文件接口** | 小 | 加载日 MAT 后拆成 cell，按原样喂给主函数 |
| **B) 改为批量接口** | 大 | 修改主函数一次性处理一天的数据，跳过逐文件循环 |

建议先走 **A 方案**，改动最小，验证通过后再考虑 B。

### 1.3 目录结构

```
hdf2mat/
├── data/
│   ├── 05kmAP/
│   │   ├── 2007/
│   │   │   ├── 2007_01_01.mat
│   │   │   ├── 2007_01_02.mat
│   │   │   └── ...
│   │   ├── 2008/
│   │   └── ...
│   ├── 05kmAL/
│   │   └── 2007/
│   └── VFM/
│       └── 2007/
├── scripts/
│   ├── batch_convert.m       ← 批量转换入口
│   ├── reorganize.m          ← 将现有 MAT 重组织为树结构
│   └── utils/
│       ├── hdf2mat_full.m
│       ├── verify_full.m
│       └── load_day_data.m   ← 按日期加载（主函数调用入口）
├── result/
├── work_log.md
└── plan_hdf2mat.md
```

**Windows 路径长度：** 最长路径为 `hdf2mat\data\05kmAP\2007\2007_01_01.mat`（约 50 字符），远低于 Windows 260 字符限制。

### 1.4 增量更新

新增 HDF 文件只需：
1. 检查对应日期的 MAT 是否存在
2. 不存在 → 转换
3. 放入正确的目录位置

无需更新任何索引文件。

## 2. 风险与限制

| 风险 | 影响 | 应对 |
|------|------|------|
| 单日 MAT 体积过大 | 加载慢、占用内存高 | 如果 > 2 GB，拆为半天两个 MAT |
| 主函数内变量名冲突 | 不同文件同名字段互相覆盖 | 使用 `day.files{i}` 结构体数组，不直接 eval |
| 增量更新误判 | 残片 MAT 被当作完整 | 检查 `meta.status == 'complete'` 再跳过 |
| index 与数据不一致 | 增删文件后 index 过期 | 定期运行 `rebuild_index.m` 重建 |

## 3. 实施步骤

1. 编写 `batch_convert.m`：扫描 Z 盘，按 `类型/年/日.mat` 逐日转换，每步写入 `meta` + `files{i}`
2. 编写 `rebuild_index.m`：遍历整个 `data/` 目录树，重建 `database_index.mat`
3. 编写 `load_day_data.m`：按日期加载 MAT，拆分为与主函数 `Fun_getCALIPSO_L2` 兼容的格式
4. 修改主函数调用点：替换 `hdfread` 调用为 `load_day_data`

## 4. 数据量估算

基于 1 月验证结果（APro 10,192 文件/年）推算：

| 类型 | 每文件 MAT | 每月 MAT | 每年 MAT | 2007~2022 合计 |
|------|-----------|---------|---------|---------------|
| **APro** | 28 MB | 23 GB | 287 GB | **~4.3 TB** |
| **ALay** | 14 MB | 12 GB | 146 GB | **~2.2 TB** |
| **VFM** | 4 MB | 3.4 GB | 41 GB | **~0.6 TB** |
| **合计** | **46 MB** | **38 GB** | **474 GB** | **~7.1 TB** |

对照：原始 HDF 约 24 TB，压缩比约 **30%**。

### 每日合并 MAT 体积

| 类型 | 单日合并 MAT | 说明 |
|------|-------------|------|
| **APro** | ~800 MB | 日合并后接近 1 GB |
| **ALay** | ~400 MB | 在安全范围内 |
| **VFM** | ~115 MB | 极小 |

> 如果单日 APro 超 2 GB，可拆为上午/下午两个 MAT。

## 5. 结论

**可行，改动量可控，风险低。** 树结构负责数据定位，`database_index.mat` 负责账本查询，两者互补，适合长期维护。
