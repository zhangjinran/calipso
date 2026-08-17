# REASONIX.md — CALIPSO AOD / VFM Analysis

## Stack
- **Language:** MATLAB (`.m` scripts, `.mlx` live scripts) — no packaging / dependency manager
- **Domain:** CALIPSO satellite lidar — AOD gridding, aerosol frequency, spatial trend analysis over China
- **Data:** HDF via `hdfsd` (CALIPSO L1/L2 products), Shapefile via `shaperead`
- **Global state:** `Lidar_Data_Altitudes`, `Day_Night_Flag`, `fileTime`, `Z` shared via `global`

## Layout

| Directory | Purpose |
|-----------|---------|
| `1 Read_Pretreatment/` | HDF reading (`readHDF.m`), file traversal, CALIPSO L1/L2 data loading (`Fun_getCALIPSO_L1`, `Fun_getCALIPSO_L2`), file criteria filtering (`Fun_output_a_list_of_criteria`) |
| `2 Physcial_Models_1_Profile_Scanner/` | Horizontal resolution change |
| `3 Classification/` | Cloud / aerosol phase block-making and plotting |
| `4 Draw Layer/` | Layer profile pseudo-color plots with CALIPSO colormap |
| `5 Draw_VFM/` | VFM (Vertical Feature Mask) rendering, colormap, colorbars |
| `6 Data/` | Static data directories (`05kmAL/`, `05kmAP/`, `VFM/`) — populated at runtime |
| `7 Draw_test/` | Test plotting scripts |
| `8 Draw AOD/` | **Core pipeline** — AOD calculation, gridding, classified AOD, frequency stats, interval accumulation, time series, trend analysis, all final maps |
| `中华人民共和国/` | China boundary shapefile |
| `ChinaAdminDivisonSHP-master/` | Third-party admin division shapefiles |
| *root* | Entry scripts: `Main_CALIPSO_AL_AP_VFM.m`, `Maintest.m`, `simple_test.m`, `test_plotting.m`, `test_trend_analysis.m` |

## Pipeline (from `Main_CALIPSO_AL_AP_VFM.m`)

1. **File selection** → `Fun_output_a_list_of_criteria_1` (date, lat/lon, day/night filters)
2. **Data reading** → `Fun_getCALIPSO_L1` / `Fun_getCALIPSO_L2` → populates `mycell{1..9}` (ALay_05km, CLay_05km, MLay_05km, L2_CPro, L2_APro, L1, VFM, CLay_01km, MLay_333m)
3. **Variable assignment** → `eval()` loop creates named structs from `mycell`
4. **Per-file processing:**
   - `Select_surface_From_VFM` — surface mask from VFM flags
   - `calculate_aod` — gridded AOD accumulation
   - `calculate_freq` — aerosol occurrence frequency
   - `calculate_classified_aod` — total/anthropogenic/natural classified AOD
   - Interval accumulation + time series storage via `ts_append_block`
5. **Final plots** → `plot_aod_block`, `plot_freq_block`, `plot_classified_aod_block`
6. **Trend analysis** → `ts_run_analysis` for each time series

## Commands
No build/test scripts — run entry scripts directly in MATLAB editor.

## Conventions
- **`_1` file pairs:** Many functions have a `_1`-suffixed sibling alongside the original (e.g. `Fun_Get_filepath.m` / `Fun_Get_filepath_1.m`). **Not auto-synced** — editing one does not update the other. Check for the sibling after every change.
- **`.asv` files:** MATLAB auto-save artifacts (`readHDF.asv`). Not source — skip; safe to delete.
- **`eval()` variable loading:** Data products assigned via `eval([name,'=struct();'])` + `eval([name,'=mycell{ii};'])`. Adding new product types needs coordination with this loop.
- **Dead code after `continue`:** The plotting blocks (layer plots, VFM renders, phase classification maps) sit after a `continue;` and are **never reached** in normal AOD pipeline runs.
- **Chinese comments** throughout.

## Watch out for
- **Hardcoded Windows paths** (`E:\CALIPSO Code_new\`, `Z:\`) — will break on another machine. Search `E:` / `Z:` before relocating.
- **`_1` vs original:** `Main_CALIPSO_AL_AP_VFM.m` calls `Fun_output_a_list_of_criteria_1` (the `_1` variant), while `Maintest.m` calls `Fun_output_a_list_of_criteria` (the original). They may diverge.
- **`addpath(genpath(...))`** reloads all subdirs each run — no MATLAB path configuration needed.
- **No test framework** — test scripts use `disp()` + manual inspection. No `matlab.unittest.TestCase`.
- **`8 Draw AOD/` and `1 Read_Pretreatment/`** are where 95% of real work happens. Other dirs are visualization support or unreachable.
