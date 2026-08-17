# Main_CALIPSO_AL_AP_VFM — 函数原理详解

## 全局数据流

```
文件遍历 (216 files)
  │
  ├─ Fun_getCALIPSO_L1 → mycell{6}  (L1: 原始后向散射)
  ├─ Fun_getCALIPSO_L2 → mycell{1..5,7..9}
  │   ├─ mycell{1} ALay_05km       (层产品：Column_TAOD_532, Lat, Lon)
  │   ├─ mycell{4} L2_CPro         (云廓线产品)
  │   ├─ mycell{5} L2_APro         (气溶胶廓线产品)
  │   │   ├─ Extinction_Coefficient_532       ← 消光系数廓线 (km⁻¹)
  │   │   ├─ Total_Backscatter_Coefficient_532  ← 总后向散射 (km⁻¹sr⁻¹)
  │   │   └─ Perpendicular_Backscatter_Coefficient_532 ← 垂直偏振后向散射
  │   ├─ mycell{7} VFM             (垂直特征掩膜：Feature_Classification_Flags)
  │   └─ ...
  │
  └─ eval() 循环 → 命名变量
```

---

## 0. 前置：地表掩膜 `Select_surface_From_VFM`

**文件：** `8 Draw AOD/Select_surface_From_VFM.m`

**目的：** 判断每条廓线的激光雷达信号是否成功到达地表，排除被云/厚气溶胶遮挡的廓线。

**原理：**

```
输入: VFM.Feature_Classification_Flags (N×5515), lims=[1, N], type='type'

对每条廓线 i:
  block = vfm_row2block(vfm_row, 'type')   → 545(高度) × 15(水平)的块

  对15个水平子样本(列)逐一检查:
    if any(block(:,j) == 5)
      → 该列至少有一个高度层标记为 Surface, 通过
    else
      → 该列没检测到地表 → surface_mask(i)=0, 整条廓线无效
```

**VFM 特征类型编码（最低3 bits）：**

| 值 | 含义 |
|----|------|
| 0 | Invalid |
| 1 | Clear Air |
| 2 | Cloud |
| 3 | Tropospheric Aerosol |
| 4 | Stratospheric Aerosol |
| **5** | **Surface** |
| 6 | Subsurface |
| 7 | No Signal |

**逻辑：** 一条廓线的 15 个水平子样本**全部**必须至少有一个高度层被 VFM 判定为"Surface"。如果有任何一个子样本没有检测到地表（被遮挡），说明该廓线的地表信号不可靠，整条廓线标记为无效（`surface_mask=0`）。

surface_mask 在后续 `calculate_aod`、`calculate_freq`、`calculate_classified_aod` 中统一用于过滤：`mask=0` 的廓线不参与任何计算。

---

## 一、计算函数

### 1. `calculate_aod` — 普通 AOD 计算

**数据源：** `ALay_05km.Column_TAOD_532`

**文件：** `8 Draw AOD/calculate_aod.m`

**原理：** `Column_TAOD_532` 是 CALIPSO 官方 L2 层产品（ALay）直接提供的**柱积分 AOD**，单位无量纲。每个廓线一个值。

```
1. 读取 Column_TAOD_532（每条廓线一个值）
2. surface_mask == 0 的廓线 → NaN
3. 只保留 taod > 0 的有效值
4. 按经纬度定位到 1°×1° 网格
5. 在线更新均值: new = (old_mean × old_cnt + val) / (old_cnt + 1)
```

**特点：** 官方产品直读，不做任何垂直积分，简单可靠。

---

### 2. `calculate_freq` — 气溶胶频率统计

**数据源：** `VFM.Feature_Classification_Flags`

**文件：** `8 Draw AOD/calculate_freq.m`

```
每条廓线:
  vfm_row(1×5515) → vfm_row2block('tropospheric aerosol')
  → 545×15 块, 元素 0-7 (0=未确定, 1-7=气溶胶子类型)

取 unique_types = 该廓线所有高度层出现过的类型(1-7)

分类:
  Total         类型 1-7                  (所有气溶胶)
  Anthropogenic 类型 3,5,6                (污染大陆/污染沙尘/抬升烟尘)
  Natural       类型 1,2,4,5,7            (海洋/沙尘/清洁大陆/污染沙尘/沙尘海洋)

网格统计:
  cnt_block(y,x) += 1                    ← 有效廓线数(分母)
  freq_block(y,x,1) += (Total)           ← 分子
  freq_block(y,x,2) += (Anthropogenic)
  freq_block(y,x,3) += (Natural)

最终绘图: 频率 = freq_block ./ cnt_block
```

注意：类型 5 (Polluted Dust) 同时计入 Anthropogenic 和 Natural。

---

### 3. `calculate_classified_aod` — 分类 AOD 计算

**数据源：** APro 消光/后向散射廓线 + VFM 气溶胶类型

**文件：** `8 Draw AOD/calculate_classified_aod.m`

#### 3.1 预处理

```
APro_altitudes → dz(k) = altitude(k) - altitude(k+1)  (单位 km)

VFM 高度 (get_vfm_altitudes):
  0-8km:   290 层, 均匀
  8-20km:  200 层, 均匀
  20-30km: 55 层, 均匀
  总计 545 层
```

#### 3.2 逐廓线流程

```
for i = 1:n_profiles:
  跳过: surface_mask == 0, 网格定位无效

  步骤1: VFM 气溶胶子类型提取
    vfm_row(1×5515) → vfm_row2block('tropospheric aerosol') → 545×15
    每个高度层取第一个有效类型(1-7) → type_for_height(545×1)

  步骤2: APro ↔ VFM 高度匹配
    每个 APro 高度 k:
      idx = argmin|APro_alt(k) - VFM_alt|
      apro_layer_type(k) = type_for_height(idx)

  步骤3: 逐高度层积分
    aod_total = 0; aod_anthro = 0; aod_natural = 0

    for k = 1:n_apro_alt:
      跳过: type ≤ 0, extinction 无效/≤0

      switch type:
        1,2,4,7  → aod_natural += ext × dz          (纯自然源)
        3,6      → aod_anthro   += ext × dz          (纯人为源)
        5        → 退偏振拆分 (见3.3)                (污染沙尘: 需拆分)

      aod_total += aod_layer
```

#### 3.3 类型 5 (Polluted Dust) 退偏振拆分（修正版）

**⚠️ 注意：** 最初版本误用测量的 `extinction × dz` 作为 type-5 的 AOD_layer，再用后向散射比例去拆分。**修正后**直接从后向散射 β_p 出发，经 LR 转换为消光再积分，与论文 Mamouri & Ansmann (2015/2016) 一致。

**数据源：**
- `Total_Backscatter_Coefficient_532` → β_p
- `Perpendicular_Backscatter_Coefficient_532` → β_⟂
- `Extinction_Coefficient_532` → 仅当 β_p 无效时回退用

**公式：**

```
δₚ = β_⟂ / β_总                     ← 退偏振比

if δₚ ≥ 0.31:  dust_frac = 1        ← 纯沙尘
if δₚ ≤ 0.05:  dust_frac = 0        ← 纯非沙尘
else:
  Eq.(8): dust_frac = (δₚ-0.05)(1+0.31) / (0.31-0.05)(1+δₚ)

β_dust = β_p × dust_frac                ← 沙尘后向散射
β_nd   = β_p × (1 - dust_frac)          ← 非沙尘后向散射

LR_DUST     = 44 sr   (Kim et al. 2018)
LR_POLLUTED = 70 sr   (污染大陆型)

α_dust = β_dust × LR_DUST               ← 沙尘消光系数
α_nd   = β_nd × LR_POLLUTED            ← 非沙尘消光系数

dust_aod = α_dust × dz                   ← 沙尘 AOD → Natural
nd_aod   = α_nd × dz                     ← 非沙尘 AOD → Anthropogenic

aod_layer = dust_aod + nd_aod            ← 该层总 AOD（替代测量值）
```

**验证示例：**

| 输入 | 中间值 | 输出 |
|------|--------|------|
| depol=0.2270 | dust_frac=0.7268 | dust_aod=0.0398 |
| β_p(隐含) | α_dust, α_nd | nd_aod=0.0238 |
| dz=0.05996 | | aod_layer=0.0636 |

```
验: 0.0398 + 0.0238 = 0.0636 ✓
```

#### 3.4 在线均值更新

与 `calculate_aod` 相同的在线平均公式：

```
old_mean = block(y,x,class)
old_cnt  = cnt_block(y,x,class)
block(y,x,class) = (old_mean × old_cnt + new_val) / (old_cnt + 1)
cnt_block(y,x,class) = old_cnt + 1
```

#### 3.5 `aod_total` 的含义

| 层类型 | aod_total 来源 |
|--------|---------------|
| 非 type-5 | `extinction × dz`（APro 测量消光） |
| type-5 | `(α_dust + α_nd) × dz`（从后向散射+LR重建） |

`aod_total` = APro 数据中能被 VFM 分类为气溶胶的层的 AOD 和。

**与 `calculate_aod` 的 `aod_block` 不一致是正常现象**：两者使用不同产品（ALay 官方柱AOD vs APro 廓线积分），且 type-5 层使用了不同的消光来源。

---

## 二、绘图函数

### 1. `plot_grid_block` — 通用网格色块图

**调用链：** `plot_aod_block` / `plot_freq_block` / `plot_classified_aod_block` → `plot_grid_block`

```
1. inpolygon(LON, LAT, china_shp) → 中国境内 mask
2. plot_block(~in_china) = NaN
3. pcolor(lon_edges, lat_edges, padarray(data, [1,1], NaN, 'post'))
4. shading flat + plot(china_shp.X, china_shp.Y)
5. colormap(parula) + colorbar + clim
6. xlim([70 136]) ylim([0 56])
```

**保存：** `result/<子文件夹>/标题.png`

### 2. `plot_trend_line` — 区域平均时间序列

```
1. inpolygon → 中国 mask
2. 逐时间点: mean(中国内(data)) → time_series
3. polyfit(years, time_series, 1) → slope
4. 5点滑动平均: movmean(time_series, 5)
5. 绘图: 蓝点(原始) + 红线(平滑) + 斜率标注
```

### 3. `plot_spatial_trend` — 季节空间趋势

**双模式回归（由数据量自动切换）：**

```
模式A (≥5年数据):
  按年求季度均值 → fitlm(年份, 均值) → slope + p值
  p<0.05 → 图上叠加黑点标记显著格点

模式B (<5年数据, 小样本保底):
  逐月值 → polyfit(连续时间, 值) → slope
  无 p 值（样本太少，不画显著性点）

示例(2年 Q1, 模式B):
  时间         | 值
  2007.00(1月) | 0.3
  2007.08(2月) | 0.5
  2007.17(3月) | 0.4
  2008.00(1月) | 0.4
  2008.08(2月) | 0.6
  2008.17(3月) | 0.5
  → polyfit → slope ≈ 0.10/year

布局: 2×2 子图 (Q1, Q2, Q3, Q4)
  第一遍: 算完 4 个斜率图, 确定全局色标范围
  第二遍: 绘图, 统一 clim([-max_abs, max_abs])
  全局 colorbar(右侧)
```

---

## 三、辅助函数一览

| 函数 | 作用 | 文件 |
|------|------|------|
| `create_empty_aod_grid` | 初始化 1°×1° AOD 网格 | 8 Draw AOD/ |
| `create_empty_freq_grid` | 频率网格 3D (lat×lon×3) | 8 Draw AOD/ |
| `create_empty_classified_aod_grid` | 同频率网格 | 8 Draw AOD/ |
| `create_ts_struct` | 时间序列容器 | 8 Draw AOD/ |
| `ts_append_block` | 追加时间点 | 8 Draw AOD/ |
| `get_time_from_filename` | 文件名 → datetime | 8 Draw AOD/ |
| `check_time_interval` | 判断是否跨区间 | 8 Draw AOD/ |
| `get_interval_end_date` | interval_key → 区间最后一天 | 8 Draw AOD/ |
| `get_vfm_altitudes` | 545 个 VFM 高度 (km) | 8 Draw AOD/ |
| `vfm_row2block` | 1×5515 → 545×15 | 5 Draw_VFM/ |
| `vfm_type` | VFM 位掩码解码 | 5 Draw_VFM/ |

---

## 四、修改记录

| 日期 | 文件 | 修改内容 |
|------|------|---------|
| 2026-06-13 | `calculate_classified_aod.m` | **type-5 拆分修正**：从"测量 extinction×dz ×比例"改为"后向散射→LR→消光→积分"，与论文一致 |
| 2026-06-13 | `plot_spatial_trend.m` | 全年混合回归 → 按季 2×2 子图 + 双模式(≥5年 fitlm / <5年 polyfit) |
| 2026-06-13 | `plot_spatial_trend.m` | 显著性检验 (p<0.05 叠黑点) |
| 2026-06-13 | `Main.m` | catch 块打印错误信息 |
| 2026-06-13 | `Main.m` | catch 块绘图注释掉 |
| 2026-06-13 | `ts_append_block.m` | 保持 3D 存储 |
| 2026-06-13 | `ts_run_analysis.m` | 时间点 < 2 跳过 |
| 2026-06-13 | `plot_grid_block/trend_line/spatial_trend.m` | 自动保存到 result/ |
| 2026-06-13 | `Main.m` | 保存路径设置 + year_select 改 range 形式 |
