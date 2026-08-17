# CALIPSO MAT 数据库建设方案

## 核心原则

### 迁移而非复制

磁盘空间不足以同时保存 HDF（~24 TB）+ MAT（~7 TB）。因此必须：

```
HDF → 转换 → MAT → 字段验证 → 主程序验证 → 生成报告 → 人工确认 → 删除 HDF → 释放空间 → 继续下一批
```

### 三类数据同步

APro / ALay / VFM 三种产品的 HDF→MAT 转换必须同步进行：

```
某一天三类数据全部转换完成 → 全部验证通过 → 同一批删除 HDF
```

不允许出现"某天只剩 APro 的 HDF，ALay 和 VFM 已删"的情况。

### 先验证后删除

删除 HDF 是一个不可逆操作。必须在每个阶段通过完整验证后，才允许进入删除环节。

---

## 总体架构

```
CALIPSO_MAT_DB/                          ← 数据库根目录（建议放在空间充足的盘）
├── data/                                ← MAT 数据文件（树形索引）
│   ├── 05kmAP/
│   │   ├── 2007/
│   │   │   ├── 2007_01_01.mat
│   │   │   ├── 2007_01_02.mat
│   │   │   └── ...
│   │   ├── 2008/
│   │   └── ...
│   ├── 05kmAL/
│   │   └── ...
│   └── VFM/
│       └── ...
│
├── database/                            ← 索引与元数据
│   └── database_index.mat               ← 文件级索引账本
│
├── logs/                                ← 运行日志
│   ├── convert_log/                     ← 转换日志（逐日）
│   ├── verify_log/                      ← 验证日志（逐日）
│   ├── migration_report/                ← 迁移报告（逐月）
│   └── error_log/                       ← 异常记录
│
├── scripts/                             ← 脚本目录
│   ├── config/
│   │   └── config.m                    ← 全局配置（路径、产品列表）
│   ├── migration/
│   │   ├── batch_convert_month.m        ← 月批量转换
│   │   ├── batch_convert_year.m         ← 年批量转换
│   │   ├── batch_convert_all.m          ← 全量转换
│   │   └── delete_hdf.m                ← HDF 删除（条件检查 + 人工确认）
│   ├── convert/
│   │   ├── hdf2mat_day.m               ← 日转换核心（读取当天 HDF → 合并为 1 个 MAT）
│   │   └── convert_single_hdf.m        ← 单文件 HDF → struct（提取自评估版 hdf2mat_full.m）
│   ├── verify/
│   │   ├── verify_day.m                ← 日验证（循环调用 verify_single_hdf + 更新 index）
│   │   ├── verify_month.m              ← 月验证（汇总统计）
│   │   └── verify_single_hdf.m         ← 单文件字段对比（提取自评估版 verify_full.m）
│   ├── database/
│   │   ├── db_load.m                   ← 加载 database_index.mat
│   │   ├── db_save.m                   ← 保存 database_index.mat
│   │   ├── db_add.m                    ← 添加一条记录
│   │   ├── db_update.m                 ← 更新某条记录的字段
│   │   └── db_query.m                  ← 条件查询
│   ├── test/
│   │   └── test_main_day.m             ← 单日主程序兼容性测试
│   └── utils/
│       ├── disk_monitor.m              ← 磁盘空间监控（转换前检查 + 转换后记录）
│       └── logger.m                    ← 统一日志写入（文本 + CSV）
│
└── docs/
    └── schema.md                        ← 数据结构说明
```

### 根目录位置

建议将 `CALIPSO_MAT_DB/` 放在与 HDF 不同的磁盘上，避免 I/O 争抢。例如：

| 项目 | 建议位置 |
|------|---------|
| 原始 HDF | Z:\ |
| MAT 数据库 | 另一块磁盘（如 F:\ 或外置盘） |
| 评估项目 | F:\CALIPSO_Code_new\hdf2mat\ |

---

## MAT 文件内部结构

### 命名规范

```
{产品}_{日期}.mat

示例:
  05kmAP_2007-01-01.mat
  05kmAL_2007-01-01.mat
  VFM_2007-01-01.mat
```

### 内部变量

```matlab
% 2007_01_01.mat 内部
day =

  meta:  [struct]          ← 转换元数据
  files: {N×1 cell}        ← 当天所有 HDF 文件的数据
```

`meta` 字段：

```matlab
day.meta.source_date      = '2007-01-01'
day.meta.source_number    = 29          % 当天 HDF 总数
day.meta.converted        = 29          % 成功转换数
day.meta.status           = 'complete'  % 'complete' | 'partial' | 'failed'
day.meta.convert_time_sec = 120.5       % 转换耗时
day.meta.hdf_size_bytes   = 157286400   % 原始 HDF 总大小
day.meta.mat_size_bytes   = 27180000    % MAT 文件大小
```

`files` 结构：

```matlab
day.files{1}.filename   = 'CAL_LID_L2_05kmAPro-...2007-01-01T00-22-49ZN.hdf'
day.files{1}.Ext        = [N×399 double]    % 消光系数
day.files{1}.Back       = [N×399 double]    % 后向散射
day.files{1}.Depol      = [N×399 double]    % 退偏比
day.files{1}.AVD        = [N×399 uint16]    % 大气体积描述
day.files{1}.Lon        = [N×1 double]      % 经度
day.files{1}.Lat        = [N×1 double]      % 纬度
day.files{1}.Time       = [N×1 double]      % 时间
day.files{1}.Alt        = [399×1 double]    % 高度轴
% ... 其他 SDS 字段
```

### save/load 方式

```matlab
% 保存
save('05kmAP_2007-01-01.mat', 'day', '-v7.3');

% 加载
d = load('05kmAP_2007-01-01.mat');
d.day.meta.status          % → 'complete'
d.day.files{1}.filename    % → 原始 HDF 文件名
```

---

## database_index.mat 结构

### 文件级记录

每条记录对应一个 HDF 文件：

```matlab
index.entries = [N×1 struct]

% 每条记录的字段:
.filename       = 'CAL_LID_L2_05kmAPro-...2007-01-01T00-22-49ZN.hdf'
.date           = '2007-01-01'
.product        = '05kmAP'
.mat_path       = '05kmAP/2007/2007_01_01.mat'
.file_index     = 1              % 在 MAT day.files{} 中的位置

.convert_status = 'complete'     % 'waiting' | 'converting' | 'complete' | 'failed'
.verify_status  = 'pass'         % 'none' | 'pass' | 'fail'
.main_test_status = 'none'        % 'none' | 'pass' | 'fail'
.delete_status  = 'deleted'      % 'keep' | 'waiting' | 'deleted'

.hdf_size       = 5242880        % 原始 HDF 大小（字节）
.mat_size       = 937200         % MAT 中该文件数据大小（字节）
.convert_time   = 3.5            % 转换耗时（秒）
.error_message  = ''             % 失败原因
```

### 状态流转

```
convert_status:
  waiting ──→ converting ──→ complete ──→ (验证后)
                    │                       verify_status='pass'
                    ↓
                  failed  ← 记录 error_message

verify_status:
  none ──→ pass ──→ (主程序测试)
         →                ↓
         fail         main_test_status
  (记录到 error_log)       │
                      pass ──→ (delete 条件满足)
                         →
                         fail
                      (记录到 error_log)

delete_status:
  keep ──→ waiting ──→ (月报告 + 人工确认) ──→ deleted
```

### 示例数据

| 文件名 | 日期 | 产品 | convert | verify | main_test | delete |
|--------|------|------|---------|--------|-----------|--------|
| CAL...00-22-49ZN.hdf | 2007-01-01 | 05kmAP | complete | pass | pass | deleted |
| CAL...01-09-14ZD.hdf | 2007-01-01 | 05kmAP | complete | pass | pass | deleted |
| CAL...01-09-14ZD.hdf | 2007-01-01 | 05kmAL | failed | none | none | keep |
| CAL...02-01-45ZN.hdf | 2007-01-01 | VFM | complete | pass | fail | keep |

---

## 验证清单

### 必须检查项（硬要求）

| 检查项 | 方法 | 失败处理 |
|--------|------|---------|
| **文件数量** | HDF 数 == MAT `files{}` 数 | 标记 partial，不允许删除 |
| **字段数量** | HDF SDS 数 == MAT 对应字段数 | 记录缺少的字段名 |
| **字段尺寸** | `size(HDF_val) == size(MAT_val)` | 逐字段报告 |
| **随机值抽样** | 随机取 3 个坐标点，`abs(HDF - MAT) < 1e-12` | 精度超标则 fail |
| **MAT 可加载** | `load(mat_path)` 不报错 | 标记 corrupted |
| **主函数兼容** | MAT 数据跑通主函数入口 | 检查接口匹配 |

### 建议检查项

| 检查项 | 方法 | 说明 |
|--------|------|------|
| 存储 checksum | 保存 HDF 文件 MD5 到 index | 证明 MAT 的来源可追溯 |
| 磁盘空间监控 | 转换前后记录剩余空间 | 防止跑了一半空间不足 |

---

## 脚本架构

### 目录结构

```
scripts/
├── config/
│   └── config.m                    ← 全局配置
├── migration/                       ← 迁移流程控制
│   ├── batch_convert_month.m
│   ├── batch_convert_year.m
│   ├── batch_convert_all.m
│   └── delete_hdf.m
├── convert/                         ← HDF → MAT 转换
│   ├── hdf2mat_day.m               ← 日转换核心
│   └── convert_single_hdf.m        ← 单文件读取
├── verify/                          ← 验证
│   ├── verify_day.m
│   ├── verify_month.m
│   └── verify_single_hdf.m
├── database/                        ← 索引管理
│   ├── db_load.m
│   ├── db_save.m
│   ├── db_add.m
│   ├── db_update.m
│   └── db_query.m
├── test/
│   └── test_main_day.m             ← 主程序兼容测试
└── utils/
    ├── disk_monitor.m               ← 磁盘监控
    └── logger.m                     ← 日志工具
```

### 调用链

```
batch_convert_month
  ├── config()
  ├── disk_monitor('pre')
  ├── hdf2mat_day                   (convert/)
  │     └── convert_single_hdf      (读取 1 个 HDF → struct)
  ├── verify_day                     (verify/)
  │     └── verify_single_hdf       (对比 1 个 HDF vs MAT)
  ├── test_main_day                  (test/)
  ├── db_*                           (database/)
  ├── disk_monitor('post')
  └── logger                         (utils/)
```

### 三层架构

```
月控制层 (migration/)          ← 流程控制，不涉及文件级别操作
    ↓ 循环每天、每产品
日任务层 (convert/ + verify/ + test/)  ← 协调多个文件
    ↓ 循环每个文件
单文件层 (convert_single_hdf / verify_single_hdf)  ← 纯数据读写
```

---

## 各脚本详细设计

### `config/config.m`

所有脚本通过 `CFG = config()` 获取配置，不硬编码路径。

```matlab
function CFG = config()
    CFG.HDF_ROOT     = 'Z:\';
    CFG.MAT_ROOT     = 'Z:\CALIPSO_MAT_DB';
    CFG.PRODUCTS     = {'05kmAP', '05kmAL', 'VFM'};
    CFG.YEARS        = 2007:2022;   % 程序自动跳过无数据的年份
    CFG.LOG_DIR      = fullfile(CFG.MAT_ROOT, 'logs');
end
```

---

### `convert/convert_single_hdf.m`

从评估版 `hdf2mat_full.m` 提取 SDS 读取核心，只做一件事：1 个 HDF → struct。

```matlab
function data = convert_single_hdf(hdf_path)
    % 输入: HDF 文件路径
    % 输出: struct，含 .filename, .Ext, .Back, .Depol, .AVD, .Lon, .Lat, .Time, .Alt ...
    %
    % 核心逻辑:
    %   sd.start → sd.fileInfo → 逐 SDS 用 sd.readData 读取
    %   sd.readData 失败的字段用 hdfread 兜底
    %   Vdata 跳过（评估确认无可用的 MATLAB HDF4 V 接口）
end
```

---

### `convert/hdf2mat_day.m`（核心新增）

输入日期 + 产品，读取当天所有 HDF，合并为 1 个日 MAT，更新 index。

```matlab
function [success, fail] = hdf2mat_day(date_str, product)
    CFG = config();
    hdf_list = dir(fullfile(CFG.HDF_ROOT, product, year, day_folder, '*.hdf'));

    day.meta.source_date   = date_str;
    day.meta.source_number = length(hdf_list);
    day.meta.status        = 'converting';
    day.files = cell(length(hdf_list), 1);

    for i = 1:length(hdf_list)
        try
            day.files{i} = convert_single_hdf(fullfile(hdf_folder, hdf_name));
            day.files{i}.filename = hdf_name;
            db_add(记录);  success++;
        catch ME
            db_add(记录 + error_message);  fail++;
        end
    end

    save(mat_path, 'day', '-v7.3');
    day.meta.status = 'complete';
    day.meta.converted = success;
    save(mat_path, 'day', '-v7.3');  % 只重写 meta
    logger('convert', date_str, product, success, fail);
end
```

---

### `verify/verify_single_hdf.m`

从评估版 `verify_full.m` 提取核心，只做一件事：对比 1 个 HDF 与 MAT 的字段。

```matlab
function [pass, details] = verify_single_hdf(hdf_path, mat_data)
    % 验证项:
    %   ① 字段数量一致
    %   ② 字段尺寸一致
    %   ③ 随机 3 点值比较，abs(差) < 1e-12
end
```

---

### `verify/verify_day.m`

```matlab
function all_pass = verify_day(date_str, product)
    day = load(mat_path);
    hdf_count = length(dir(...));
    all_pass = (hdf_count == length(day.files));

    for i = 1:length(day.files)
        result = verify_single_hdf(hdf_path, day.files{i});
        db_update(记录);
        if ~result.pass; all_pass = false; end
    end
    logger('verify', date_str, product, all_pass);
end
```

---

### `test/test_main_day.m`

与月转换解耦的独立测试脚本。

```matlab
function pass = test_main_day(date_str)
    % 1. 加载三类数据的日 MAT
    % 2. 替换 Fun_getCALIPSO_L2 为 load_day_data
    % 3. 运行主函数处理当天数据
    % 4. 检查结果（不崩溃 + 输出合理）
    % 5. 更新 index.main_test_status
end
```

---

### `database/` 模块（5 个文件）

所有脚本通过这组接口访问 `database_index.mat`，不直接操作 `.mat` 文件。

```matlab
% db_load.m
function idx = db_load()
    % 加载 database_index.mat，不存在则返回空结构
end

% db_save.m
function db_save(idx)
    % 写回 database_index.mat
end

% db_add.m
function db_add(record)
    % 添加一条新记录（对应 1 个 HDF 文件）
end

% db_update.m
function db_update(filename, field, value)
    % 更新某条记录的某个字段
    % 例: db_update('CAL...hdf', 'verify_status', 'pass')
end

% db_query.m
function results = db_query(condition)
    % 条件查询
    % 例: db_query('date==2007-01-01 & product==05kmAP')
end
```

---

### `utils/disk_monitor.m`（增强版）

```matlab
function [enough] = disk_monitor(mode, estimated_size)
    % mode = 'pre':  检查剩余空间 > estimated_size，不足则停止
    % mode = 'post': 记录转换前后空间变化

    % 日志格式:
    %   2026-07-26 15:00 | PRE  | 剩余 3.2 TB | 预计 38 GB | 通过
    %   2026-07-26 18:00 | POST | 转换前 3.2T | 转换后 12.8T | +9.6T
end
```

### `utils/logger.m`

```matlab
function logger(category, varargin)
    % 写入 logs/category/yyyy_mm.log
    % 格式: 时间戳 | 日期 | 产品 | 状态 | 详情
end
```

### `migration/delete_hdf.m`

```matlab
function delete_hdf(date_str, product)
    % 必须满足全部条件:
    %   ✅ mat_file_exist == true          ← 新增：MAT 文件存在
    %   ✅ verify_status == 'pass'  (全部)
    %   ✅ main_test_status == 'pass' (全部)
    %   ✅ 月迁移报告已生成
    %   ✅ 人工确认
end
```

### `migration/batch_convert_month.m`

```matlab
function batch_convert_month(year, month)
    for each day in month:
        for each product in [05kmAP, 05kmAL, VFM]:
            disk_monitor('pre', estimated_size)
            hdf2mat_day(date, product)
            verify_day(date, product)
        end
        test_main_day(date)                    % 三类完成后才跑主程序验证
    end
    verify_month(year, month)
    generate_month_report(year, month)
    % 人工确认后调用 delete_hdf
end
```

### 评估版脚本

评估版脚本（`hdf2mat/scripts/utils/` 下的 `hdf2mat_full.m`、`verify_full.m`）**保留不动**，作为 `convert_single_hdf.m` 和 `verify_single_hdf.m` 的核心逻辑参考。生产版独立放在 `CALIPSO_MAT_DB/scripts/` 下。

---

## 阶段执行计划

### 阶段 0：基础设施建设

**目标：** 在任何正式转换之前，建立完整的纠错和记录体系。

#### 0.1 搭建目录结构

创建 `CALIPSO_MAT_DB/` 及其子目录（data / database / logs / scripts / docs）。

#### 0.2 编写核心脚本

| 脚本 | 功能 | 依赖 |
|------|------|------|
| `config.m` | 全局配置 | 新建 |
| `convert_single_hdf.m` | 1 个 HDF → struct | 从 `hdf2mat_full.m` 提取核心 |
| `hdf2mat_day.m` | 日合并转换 | 新建 |
| `verify_single_hdf.m` | 1 个文件字段对比 | 从 `verify_full.m` 提取核心 |
| `verify_day.m` | 日验证 | 新建 |
| `verify_month.m` | 月汇总验证 | 新建 |
| `test_main_day.m` | 主程序兼容测试 | 新建 |
| `db_load.m` / `db_save.m` / `db_add.m` / `db_update.m` / `db_query.m` | 索引管理模块 | 新建 |
| `disk_monitor.m` | 磁盘监控 | 新建 |
| `logger.m` | 日志工具 | 新建 |
| `delete_hdf.m` | 条件性 HDF 删除 | 新建 |
| `batch_convert_month.m` | 月批量转换 | 新建 |
| `batch_convert_all.m` | 全量转换入口 | 新建 |

#### 0.3 编写数据结构文档

在 `docs/schema.md` 中记录 MAT 内部结构、database_index 字段定义、状态流转图。

#### 0.4 定义 database_index.mat 初始格式

预生成空的 `database_index.mat`（`index.entries = struct([])`）。

---

### 阶段 1：单日闭环验证

**目标：** 证明 1 天的 HDF → MAT → 主函数的完整链路正确，并验证删除机制安全。

#### 1.1 选择测试数据

```
日期: 2007-01-01
产品: 05kmAP + 05kmAL + VFM
文件: 三类数据同一天的 HDF 文件
```

#### 1.2 转换一天数据

对三类数据分别执行：

```
Z:\05kmAP\2007\2007_01_01\ 的 29 个 HDF
  → CALIPSO_MAT_DB/data/05kmAP/2007/2007_01_01.mat

Z:\05kmAL\2007\2007_01_01\ 的 29 个 HDF
  → CALIPSO_MAT_DB/data/05kmAL/2007/2007_01_01.mat

Z:\VFM\2007\2007_01_01\ 的 29 个 HDF
  → CALIPSO_MAT_DB/data/VFM/2007/2007_01_01.mat
```

每个 MAT 内部均含 `day.meta` + `day.files{}`。

#### 1.3 完整验证

执行验证清单中所有必须检查项：

```
✅ 文件数量一致（HDF 87 个 → MAT 87 条记录）
✅ 字段数量一致（APro 82 / ALay 208 / VFM 20）
✅ 字段尺寸一致
✅ 随机值抽样通过
✅ MAT 可正常加载
```

#### 1.4 更新 database_index

将三类数据共 87 条文件级记录写入 `database_index.mat`：

```matlab
index.entries(1).filename       = 'CAL...ZN.hdf'
index.entries(1).convert_status = 'complete'
index.entries(1).verify_status  = 'pass'
index.entries(1).delete_status  = 'waiting'
```

#### 1.5 主程序验证

使用 MAT 数据替换主函数的 HDF 读取入口，运行主程序处理当天的数据。确认：

```
✅ 主程序正常启动
✅ 不再调用 hdfread
✅ 输出结果与 HDF 版本一致或合理
✅ 无变量冲突或兼容性错误
```

验证通过后，将 `index.main_test_status` 设为 `'pass'`。

#### 1.6 生成单日迁移报告

```matlab
logs/migration_report/2007_01_01_report.txt
```

内容：

```
CALIPSO MAT Database — 日迁移报告
日期: 2007-01-01
================================
HDF 文件总数:  87
APro:         29
ALay:         29
VFM:          29

转换成功:     87
转换失败:     0
验证通过:     87
验证失败:     0

MAT 总大小:   1.3 GB
HDF 总大小:   9.5 GB

删除 HDF:     是
```

#### 1.7 删除 HDF

三类数据的 HDF 全部删除。删除前确认所有条件满足：

```
✅ file_count == mat_count
✅ verify_status == 'pass' (全部文件)
✅ main_test_status == 'pass' (全部文件)
✅ 迁移报告已生成
✅ 人工确认
```

#### 1.8 验收标准

| 项目 | 要求 |
|------|------|
| MAT 成功生成 | 3 个 MAT |
| 字段完整 | 全部字段通过 isequal |
| 主程序运行 | 加载 MAT 后正常工作 |
| 无 HDF 读取 | 主程序不依赖 hdfread |
| HDF 删除确认 | 87 个 HDF 全部标记 deleted |

---

### 阶段 2：单月迁移验证

**目标：** 验证多日期、大批量下的稳定性和迁移闭环。

#### 2.1 范围

```
月份: 2007-01
规模: ~2,511 个 HDF / ~3 种产品 / 31 天
之前阶段已处理 1 天，本月剩余 30 天
```

#### 2.2 逐日转换

逐日处理三类数据，并行转换（按日）：

```
for each day in 2007-01-02 ~ 2007-01-31:
    for each product in [05kmAP, 05kmAL, VFM]:
        hdf2mat_day(date, product)      ← 生产版日转换
        verify_day(date, product)       ← 生产版日验证
        update database_index
```

#### 2.3 日验证

每天转换完成后立即执行验证清单。

#### 2.4 月验证

全部 31 天完成后，执行额外检查：

```
✅ database_index 记录数 == 所有文件数
✅ convert_status == 'complete' 比率 > 99.5%
✅ verify_status == 'pass' 比率 > 99%
✅ 无未处理的 waiting 记录
```

#### 2.5 生成月迁移报告

```matlab
logs/migration_report/2007_01_migration_report.txt
```

内容：

```
CALIPSO MAT Database — 月迁移报告
周期: 2007-01
================================
HDF 总数:      2,511
APro:            838
ALay:            838
VFM:             835

转换成功:      2,508
转换失败:          3
验证通过:      2,508
验证失败:          0

MAT 总大小:    38 GB
HDF 总大小:   278 GB

删除 HDF:       是
删除时间:       [timestamp]
```

#### 2.6 删除整月 HDF

只有满足以下全部条件才允许删除：

```
✅ mat_file_exist == true              ← 新增
✅ verified_count == total_hdf_count
✅ main_test_status == 'pass'（全部产品或抽样）
✅ 月迁移报告已生成
✅ 人工确认
```

#### 2.7 验收标准

| 项目 | 要求 |
|------|------|
| 转换成功率 | > 99.5% |
| 验证通过率 | > 99% |
| 中断恢复 | 模拟中断后能从中断点继续 |
| 主程序兼容 | 整月数据跑通主程序 |
| HDF 删除 | 全部标记 deleted |

---

### 阶段 3：单年压力验证

**目标：** 验证长期运行能力、中断恢复、磁盘空间管理。

#### 3.1 范围

```
年份: 2007
规模: ~10,200 HDF / 产品 / 全年
```

#### 3.2 逐月迁移

按阶段 2 的方式逐月执行，每月生成一份月迁移报告。

#### 3.3 中断恢复测试

模拟转换到 6 月中旬时中断。重新启动后：

```matlab
% 程序检查 database_index
% 1-5 月: verified + deleted → 跳过
% 6 月 1-15 日: complete + pass → skip
% 6 月 15 日以后: waiting → 继续转换
```

#### 3.4 磁盘空间监控

每转换一个月后记录磁盘空间变化：

```matlab
logs/disk_space.log

2007-01: 转换前 3.0TB, 转换后 3.2TB (+200GB freed)
2007-02: 转换前 3.2TB, 转换后 3.4TB (+200GB freed)
```

#### 3.5 验收标准

| 项目 | 要求 |
|------|------|
| 全年转换 | 完成 12 个月 |
| 无人值守 | 中断恢复后自动继续 |
| 磁盘空间 | 逐月释放，总释放量 ≈ HDF 体积 |
| database_index | 12 条月记录完整 |

---

### 阶段 4：全量生产迁移

**目标：** 完成 2007~2022 年全部数据的迁移。

#### 4.1 范围

```
年份: 2007 ~ 2022（缺 2009）
总计: ~450,000 HDF
预计 MAT: ~7.1 TB
预计转换时间: 数千小时（可分批运行）
```

#### 4.2 执行方式

```matlab
for each year in [2007, 2008, 2010, ..., 2022]:
    for each month in [1..12]:
        batch_convert_month(year, month)
        verify_month(year, month)
        generate_report(year, month)
        if report.verified == report.total:
            delete_hdf(year, month)
            update_index_delete_status(year, month)
```

#### 4.3 日志输出示例

```matlab
logs/convert_log/2007_01.log
  Total:    2511
  Success:  2508
  Failed:   3
  Time:     8h 32m
```

#### 4.4 异常处理

- 单日转换失败 → 记录 error_log → 跳过当天 → 后续手动重试
- 单月验证不通过 → 不删除 HDF → 标记需人工检查
- 磁盘空间不足 → 暂停转换 → 等待当前月份 HDF 删除释放空间

#### 4.5 验收标准

| 项目 | 要求 |
|------|------|
| 全量转换 | 15 年数据全部完成 |
| database_index | 450,000 条记录，完整可查询 |
| HDF 删除 | 全部标记 deleted（除失败文件） |
| 最终状态 | 仅保留 MAT 数据库 |

---

## 风险与应对

| 风险 | 影响 | 概率 | 应对 |
|------|------|------|------|
| **转换中断** | 残片 MAT 被当作完整 | 中 | `meta.status` + 逐文件 index 双重检查 |
| **验证失败** | 某天数据不完整 | 低 | 标记 partial，不删除 HDF，人工介入 |
| **磁盘空间不足** | 转换中止 | 低 | `disk_monitor.m` 提前预警 |
| **MAT 损坏** | 数据丢失 | 极低 | 删除前保留 HDF 至月报告确认 |
| **主函数不兼容** | MAT 数据格式不匹配 | 中 | 阶段 1 先验证兼容性 |
| **HDF 误删** | 数据永久丢失 | 极低 | verified + main_test + 月报告 + 人工确认四重检查 |

---

## 交付物清单

### 脚本（8 个）

| 脚本 | 阶段 | 说明 |
|------|------|------|
| `config.m` | 0 | 全局配置 |
| `convert_single_hdf.m` | 0 | 1 个 HDF → struct |
| `hdf2mat_day.m` | 1 | 日合并转换 |
| `verify_single_hdf.m` | 0 | 1 个文件字段对比 |
| `verify_day.m` | 1 | 日验证 |
| `verify_month.m` | 2 | 月汇总验证 |
| `test_main_day.m` | 1 | 主程序兼容测试 |
| `db_load.m` | 0 | 索引加载 |
| `db_save.m` | 0 | 索引保存 |
| `db_add.m` | 0 | 索引添加 |
| `db_update.m` | 0 | 索引更新 |
| `db_query.m` | 0 | 索引查询 |
| `disk_monitor.m` | 0 | 磁盘监控 |
| `logger.m` | 0 | 日志工具 |
| `delete_hdf.m` | 2 | 条件性 HDF 删除 |
| `batch_convert_month.m` | 2 | 月批量转换 |
| `batch_convert_all.m` | 4 | 全量转换入口 |

### 文档（2 个）

| 文档 | 说明 |
|------|------|
| `docs/schema.md` | 数据库结构定义 |
| `CALIPSO_MAT_DB/README.md` | 数据库使用说明 |

### 数据库

| 产物 | 说明 |
|------|------|
| `database/database_index.mat` | 文件级索引 |
| `data/` | 树形 MAT 数据 |
| `logs/` | 运行日志和迁移报告 |

---

## 附录：三类数据同步原则详解

### 为什么必须同步？

三类数据（APro / ALay / VFM）对应同一次 CALIPSO 过境扫描：

```
同一时刻的同一位置:
  APro: 气溶胶廓线（消光、后向散射）
  ALay: 气溶胶层（总 AOD、层高）
  VFM:  特征分类（云/气溶胶/晴空）
```

主函数需要同时读取三类数据才能完成计算。任何一类缺失都会导致处理失败。

### 同步方式

以**日期**为同步粒度的含义：

```
对每一天:
  步骤 A: 转换 05kmAP/.../2007_01_01/ 的全部 HDF → 1 个 MAT
  步骤 B: 转换 05kmAL/.../2007_01_01/ 的全部 HDF → 1 个 MAT
  步骤 C: 转换 VFM/.../2007_01_01/ 的全部 HDF → 1 个 MAT

  验证 A+B+C 全部通过？
    ✅ 是 → 删除该天三类 HDF
    ❌ 否 → 保留全部三类 HDF，不删除
```

### 不同步的后果

```
❌ 错误情况:
   05kmAP/2007_01_01 的 HDF 已删除
   但 VFM/2007_01_01 的 HDF 还在（转换失败）

   后果: 该天数据无法恢复，除非重新下载
```
