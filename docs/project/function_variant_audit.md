# 函数版本审计（原始版与 `_1` 版）

## 当前结论

暂不删除或移动 `_1` 文件。项目中有三类情况：

1. **内容完全相同**：可以在后续验证后归档。
2. **内容不同但函数名相同**：必须先确定主程序使用的版本，不能按文件名直接删除。
3. **函数声明与文件名不一致**：存在 MATLAB path 冲突风险，需要单独修复。

## 完全相同的函数对

- `Fun_Assign_Profile_According_Position`
- `Fun_Change_num`
- `Fun_CheckOfficialProfileNumber`
- `Fun_convertTAITime`
- `Fun_filesTraversal`
- `Fun_get_over_5km_resolution_offical_inf_Merge`
- `Fun_getCALIPSO_L1`
- `readHDF`
- `Fun_get_over_5km_resolution_offical_inf_cl_For_Aerosol`
- `Fun_get_over_5km_resolution_offical_inf_cl_For_Cloud`
- `Fun_Make_Block`
- `ginputax`
- `CreateColorMap`
- `kathys_lidar_colors`
- `lidar_colorbar`
- `newfigure`
- `vfm_type`

这些文件仅可在 MATLAB 路径检查和主流程回归测试通过后归档一份。

## 内容不同的函数对

- `Fun_Get_filepath`
- `Fun_getCALIPSO_L2`
- `Fun_output_a_list_of_criteria`
- `Fun_horizontal_resolution_Change`
- `Cloud_Phase_plot`
- `Fun_Layer_Plot_Profile`
- `Fun_Layer_Plot`
- `vfm_plot_V1`
- `vfm_row2block`

这些函数需要逐个比较差异和调用结果，不能直接合并。

## 已发现的高风险点

### 1. `Fun_output_a_list_of_criteria.m` 声明异常

文件名是 `Fun_output_a_list_of_criteria.m`，但第一行函数声明为：

```matlab
function [File_select,int] = Fun_output_a_list_of_criteria_1(...)
```

这会造成文件名与主函数名不一致，当前主程序调用 `_1` 版本，必须保留并优先修复命名关系。

### 2. VFM 绘图函数存在重复函数名

- `vfm_plot_V1_1.m` 声明 `vfm_plot_V1_1`，参数较多；
- `vfm_plot_V1_1_1.m` 也声明 `vfm_plot_V1_1`，参数较少。

两者同时位于 MATLAB path 时，实际调用取决于 path 顺序，具有不确定性。

### 3. 主入口的当前调用

- `Main_CALIPSO_AL_AP_VFM.m` 调用 `Fun_output_a_list_of_criteria_1`；
- `Main_CALIPSO_AL_AP_VFM.m` 和 `Maintest.m` 调用 `vfm_plot_V1_1`；
- 其他多数函数通过无后缀名称调用。

## 下一步安全操作

1. 先修复函数名与文件名不一致的问题，并做 MATLAB 最小测试。
2. 为 VFM 绘图函数改成唯一、明确的函数名，再更新调用方。
3. 对完全相同的函数对做回归测试。
4. 将确认不再使用的重复文件移入 `archive/legacy_functions/`。
5. 每完成一组变更就单独 Git 提交。
