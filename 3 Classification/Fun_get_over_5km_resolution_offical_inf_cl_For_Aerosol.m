function [output] = Fun_get_over_5km_resolution_offical_inf_cl_For_Aerosol(ALay_05km)
%% 分别提取各分辨率下的层次产品
% 输入信息：
% CLay_05km：    5km云层
% ALay_05km：    5km气溶胶层
%% 将5/20/80km的气溶胶，云产品分别保存
global Z;
%% -------------------------------------官方产品中5km云层各属性提取-----------------------------------------------------%%
%% 提取
True_horizontal_resolution_1 = ALay_05km.Horizontal_Averaging;    
Top_given_1                  = ALay_05km.Layer_Top_Altitude;                        
Base_given_1                 = ALay_05km.Layer_Base_Altitude;                       
Lat_given_1                  = ALay_05km.Lat;                        
Lon_given_1                  = ALay_05km.Lon;       
DEM_given_1                    = ALay_05km.DEM_Surface_Elevation(:,3);      
Integrated_Attenuated_Backscatter_532_given_1 = ALay_05km.Integrated_Attenuated_Backscatter_532; 
Integrated_Attenuated_Total_Color_Ratio_given_1 = ALay_05km.Integrated_Attenuated_Total_Color_Ratio; 
Integrated_Volume_Depolarization_Ratio_given_1 = ALay_05km.Integrated_Volume_Depolarization_Ratio; 
Integrated_Particulate_Depolarization_Ratio_given_1=ALay_05km.Integrated_Particulate_Depolarization_Ratio;
CAD_Score_given_1 = ALay_05km.CAD_Score;  
Feature_Classification_Flags_given_1 = ALay_05km.Feature_Classification_Flags;
Midlayer_Temperature_given_1=ALay_05km.Midlayer_Temperature;
Layer_Top_Temperature_given_1 = ALay_05km.Layer_Top_Temperature;
Surface_Type_given_1          = ALay_05km.IGBP_Surface_Type;
%Layer_Centroid_Temperature_given_1=ALay_05km.Layer_Centroid_Temperature;
Tropopause_Height_given_1=ALay_05km.Tropopause_Height;
Attenuated_Scattering_Ratio_Statistics_532_give_1 = ALay_05km.Attenuated_Scattering_Ratio_Statistics_532;
%% 预分配内存
topbin_right_5km_AL                 = nan(size(Top_given_1));
basebin_right_5km_AL                = nan(size(Top_given_1));
%Lat && surface type && Tropopause_Height
AL_5km_Lat=nan(size(Top_given_1));
AL_5km_Lon=nan(size(Top_given_1));
AL_5km_Tropopause_Height=nan(size(Top_given_1));
AL_5km_Surface_Type = nan(size(Top_given_1));
AL_5km_ASR_Mean = nan(size(Top_given_1));
%% 计算
%Bin
top_right_5km_AL=Top_given_1;
top_right_5km_AL(True_horizontal_resolution_1~=5)=NaN;
base_right_5km_AL=Base_given_1;
base_right_5km_AL(True_horizontal_resolution_1~=5)=NaN;
for i=1:size(top_right_5km_AL,1)
    for j=1:size(top_right_5km_AL,2)
        if ~isnan(base_right_5km_AL(i,j))
            topbin_right_5km_AL(i,j)                  = find(round(double(Z),4) == round(double(top_right_5km_AL(i,j)),4),1,'last');
            basebin_right_5km_AL(i,j)                 = find(round(double(Z),4) == round(double(base_right_5km_AL(i,j)),4),1,'last');
        end
    end
end
%Zmid
AL_5km_Zmid=(top_right_5km_AL+base_right_5km_AL)/2;

[Row,~]=size(AL_5km_Lat);
for i=1:1:Row
    [m]=find(True_horizontal_resolution_1(i,:)==5);
    if ~isempty(m)
        AL_5km_Lat(i,m)=Lat_given_1(i,2);
        AL_5km_Lon(i,m)=Lon_given_1(i,2);
        AL_5km_Surface_Type(i,m) = Surface_Type_given_1(i,1);   
        AL_5km_Tropopause_Height(i,m)=Tropopause_Height_given_1(i,1);
        AL_5km_ASR_Mean(i,m) = Attenuated_Scattering_Ratio_Statistics_532_give_1(i,6*(m-1)+3);
    end
end
%Layer_averaged_attenuated_backscatter
Integrated_Attenuated_Backscatter_5km_AL=Integrated_Attenuated_Backscatter_532_given_1;
Integrated_Attenuated_Backscatter_5km_AL(True_horizontal_resolution_1~=5)=NaN;
Width_5km_AL=basebin_right_5km_AL-topbin_right_5km_AL+1;
AL_5km_Layer_averaged_attenuated_backscatter=Integrated_Attenuated_Backscatter_5km_AL./Width_5km_AL;
%Layer_integrated_attenuated_backscatter
AL_5km_Layer_integrated_attenuated_backscatter=Integrated_Attenuated_Backscatter_5km_AL;
%layer-integrated attenuated total color ratio
AL_5km_layer_integrated_attenuated_total_color_ratio=Integrated_Attenuated_Total_Color_Ratio_given_1;
AL_5km_layer_integrated_attenuated_total_color_ratio(True_horizontal_resolution_1~=5)=NaN;
%layer-integrated volume depolarization ratio 
AL_5km_Integrated_Volume_Depolarization_Ratio=Integrated_Volume_Depolarization_Ratio_given_1;
AL_5km_Integrated_Volume_Depolarization_Ratio(True_horizontal_resolution_1~=5)=NaN;
%Integrated_Particulate_Depolarization_Ratio
AL_5km_Integrated_Particulate_Depolarization_Ratio=Integrated_Particulate_Depolarization_Ratio_given_1;
AL_5km_Integrated_Particulate_Depolarization_Ratio(True_horizontal_resolution_1~=5)=NaN;
%CAD_Score
AL_5km_CAD_Score=double(CAD_Score_given_1);
AL_5km_CAD_Score(True_horizontal_resolution_1~=5)=NaN;
%Feature_Classification_Flags
AL_5km_Feature_Classification_Flags=double(Feature_Classification_Flags_given_1);
AL_5km_Feature_Classification_Flags(True_horizontal_resolution_1~=5)=NaN;
%Midlayer_Temperature
AL_5km_Midlayer_Temperature=Midlayer_Temperature_given_1;
AL_5km_Midlayer_Temperature(True_horizontal_resolution_1~=5)=NaN;
%Layer_Top_Temperature
AL_5km_Layer_Top_Temperature=Layer_Top_Temperature_given_1;
AL_5km_Layer_Top_Temperature(True_horizontal_resolution_1~=5)=NaN;


%Layer_Centroid_Temperature
%AL_5km_Layer_Centroid_Temperature=Layer_Centroid_Temperature_given_1;
%AL_5km_Layer_Centroid_Temperature(True_horizontal_resolution_1~=5)=NaN;

%% 输出
output.top_right_5km_AL                   = top_right_5km_AL;
output.base_right_5km_AL                  = base_right_5km_AL;
output.topbin_right_5km_AL                = topbin_right_5km_AL;
output.basebin_right_5km_AL               = basebin_right_5km_AL;
output.AL_5km_Zmid                        =AL_5km_Zmid;
output.AL_5km_Lat                         =AL_5km_Lat;
output.AL_5km_Lon                         =AL_5km_Lon;
output.AL_5km_Layer_averaged_attenuated_backscatter=AL_5km_Layer_averaged_attenuated_backscatter;
output.AL_5km_Layer_integrated_attenuated_backscatter=AL_5km_Layer_integrated_attenuated_backscatter;
output.AL_5km_layer_integrated_attenuated_total_color_ratio=AL_5km_layer_integrated_attenuated_total_color_ratio;
output.AL_5km_Integrated_Volume_Depolarization_Ratio=AL_5km_Integrated_Volume_Depolarization_Ratio;
output.AL_5km_Integrated_Particulate_Depolarization_Ratio=AL_5km_Integrated_Particulate_Depolarization_Ratio;
output.AL_5km_CAD_Score                  =AL_5km_CAD_Score;              
output.AL_5km_Feature_Classification_Flags                  = AL_5km_Feature_Classification_Flags;
output.AL_5km_Midlayer_Temperature                  = AL_5km_Midlayer_Temperature;
output.AL_5km_Layer_Top_Temperature                 = AL_5km_Layer_Top_Temperature;
output.AL_5km_Tropopause_Height=AL_5km_Tropopause_Height;
output.AL_5km_Surface_Type = AL_5km_Surface_Type;
output.AL_5km_ASR_Mean = AL_5km_ASR_Mean;
output.DEM_given_5km  = DEM_given_1;
%output.AL_5km_Layer_Centroid_Temperature=AL_5km_Layer_Centroid_Temperature;
%% -------------------------------------官方产品中20km云层各属性提取-----------------------------------------------------%%
%% 预分配内存
top_right_20km_AL                   = nan(size(Top_given_1));
base_right_20km_AL                  = nan(size(Top_given_1));
topbin_right_20km_AL                = nan(size(Top_given_1));
basebin_right_20km_AL               = nan(size(Top_given_1));
AL_20km_Zmid                      = nan(size(Top_given_1));
AL_20km_Lat                       = nan(size(Top_given_1));
AL_20km_Lon                         =nan(size(Top_given_1));
AL_20km_Layer_averaged_attenuated_backscatter  = nan(size(Top_given_1));
AL_20km_Layer_integrated_attenuated_backscatter  = nan(size(Top_given_1));
AL_20km_layer_integrated_attenuated_total_color_ratio  = nan(size(Top_given_1));
AL_20km_Integrated_Volume_Depolarization_Ratio   = nan(size(Top_given_1));
AL_20km_Integrated_Particulate_Depolarization_Ratio=nan(size(Top_given_1));
AL_20km_CAD_Score=nan(size(Top_given_1));
AL_20km_Feature_Classification_Flags=nan(size(Top_given_1));
AL_20km_Midlayer_Temperature=nan(size(Top_given_1));
%AL_20km_Layer_Centroid_Temperature=nan(size(Top_given_1));
AL_20km_Tropopause_Height=nan(size(Top_given_1));
AL_20km_Surface_Type = nan(size(Top_given_1));
AL_20km_ASR_Mean = nan(size(Top_given_1));
DEM_20km_given                   = nan(size(DEM_given_1,1)/4,1);
%% 计算
%Bin
top_right_20km_AL=Top_given_1;
top_right_20km_AL(True_horizontal_resolution_1~=20)=NaN;
base_right_20km_AL=Base_given_1;
base_right_20km_AL(True_horizontal_resolution_1~=20)=NaN;
for i=1:size(top_right_20km_AL,1)
    for j=1:size(top_right_20km_AL,2)
        if ~isnan(base_right_20km_AL(i,j))
            topbin_right_20km_AL(i,j)                  = find(round(double(Z),4) == round(double(top_right_20km_AL(i,j)),4),1,'last');
            basebin_right_20km_AL(i,j)                 = find(round(double(Z),4) == round(double(base_right_20km_AL(i,j)),4),1,'last');
        end
    end
end
%Zmid
AL_20km_Zmid=(top_right_20km_AL+base_right_20km_AL)/2;
[Row,~]=size(AL_20km_Lat);
for i=1:1:Row
    [m]=find(True_horizontal_resolution_1(i,:)==20);
    if ~isempty(m)
        AL_20km_Lat(i,m)=Lat_given_1(i,2);
        AL_20km_Lon(i,m)=Lon_given_1(i,2);
        AL_20km_Tropopause_Height(i,m)=Tropopause_Height_given_1(i,1);
        AL_20km_Surface_Type(i,m) = Surface_Type_given_1(i,1);
        AL_20km_ASR_Mean(i,m)  = Attenuated_Scattering_Ratio_Statistics_532_give_1(i,6*(m-1)+3);
    end
end
% 1. 获取参考数据的行数，并计算循环次数
%    使用 floor 确保循环次数为整数，避免索引超出范围
n_rows = size(True_horizontal_resolution_1, 1);
num_windows = floor(n_rows / 4);

% 2. 预分配输出数组的内存，这是MATLAB中提高循环效率的好习惯
DEM_20km_given = zeros(num_windows, 1);

% 3. 循环计算，使用 mean 并手动忽略 NaN 值
for i = 1:num_windows
    % 计算当前窗口的起始和结束索引
    start_idx = 4 * i - 3;
    end_idx = 4 * i;
    
    % 提取当前窗口内的数据
    window_data = DEM_given_1(start_idx:end_idx);
    
    % 过滤掉数据中的 NaN 值，然后计算平均值
    % 这种方式等价于 nanmean(window_data)
    DEM_20km_given(i) = mean(window_data(~isnan(window_data)));
end

%Layer_averaged_attenuated_backscatter
AL_20km_Layer_integrated_attenuated_backscatter=Integrated_Attenuated_Backscatter_532_given_1;
AL_20km_Layer_integrated_attenuated_backscatter(True_horizontal_resolution_1~=20)=NaN;
Width_20km_AL=basebin_right_20km_AL-topbin_right_20km_AL+1;
AL_20km_Layer_averaged_attenuated_backscatter=AL_20km_Layer_integrated_attenuated_backscatter./Width_20km_AL;
%Layer_integrated_attenuated_backscatter
AL_20km_Layer_integrated_attenuated_backscatter=AL_20km_Layer_integrated_attenuated_backscatter;
%layer-integrated attenuated total color ratio
AL_20km_layer_integrated_attenuated_total_color_ratio=Integrated_Attenuated_Total_Color_Ratio_given_1;
AL_20km_layer_integrated_attenuated_total_color_ratio(True_horizontal_resolution_1~=20)=NaN;
%layer-integrated volume depolarization ratio 
AL_20km_Integrated_Volume_Depolarization_Ratio=Integrated_Volume_Depolarization_Ratio_given_1;
AL_20km_Integrated_Volume_Depolarization_Ratio(True_horizontal_resolution_1~=20)=NaN;
%Integrated_Particulate_Depolarization_Ratio
AL_20km_Integrated_Particulate_Depolarization_Ratio=Integrated_Particulate_Depolarization_Ratio_given_1;
AL_20km_Integrated_Particulate_Depolarization_Ratio(True_horizontal_resolution_1~=20)=NaN;
%CAD_Score
AL_20km_CAD_Score=double(CAD_Score_given_1);
AL_20km_CAD_Score(True_horizontal_resolution_1~=20)=NaN;
%Feature_Classification_Flags
AL_20km_Feature_Classification_Flags=double(Feature_Classification_Flags_given_1);
AL_20km_Feature_Classification_Flags(True_horizontal_resolution_1~=20)=NaN;
%Midlayer_Temperature
AL_20km_Midlayer_Temperature=Midlayer_Temperature_given_1;
AL_20km_Midlayer_Temperature(True_horizontal_resolution_1~=20)=NaN;
%Layer_Top_Temperature 
AL_20km_Layer_Top_Temperature = Layer_Top_Temperature_given_1;
AL_20km_Layer_Top_Temperature(True_horizontal_resolution_1~=20)  = NaN;
%Layer_Centroid_Temperature
%AL_20km_Layer_Centroid_Temperature=Layer_Centroid_Temperature_given_1;
%AL_20km_Layer_Centroid_Temperature(True_horizontal_resolution_1~=20)=NaN;

[top_right_20km_AL_changednum,Pos]            = Fun_CheckOfficialProfileNumber(top_right_20km_AL,'top_right_20km_AL',20); % 已转换成合适条数的80km廓线层顶
base_right_20km_AL_changednum=Fun_Assign_Profile_According_Position(base_right_20km_AL,Pos,20);
topbin_right_20km_AL_changednum               = Fun_Assign_Profile_According_Position(topbin_right_20km_AL,Pos,20); % 已转换成合适条数的20km廓线层顶
basebin_right_20km_AL_changednum              = Fun_Assign_Profile_According_Position(basebin_right_20km_AL,Pos,20); % 已转换成合适条数的20km廓线层顶
AL_20km_Zmid_changednum = Fun_Assign_Profile_According_Position(AL_20km_Zmid,Pos,20); 
AL_20km_Lat_changednum = Fun_Assign_Profile_According_Position(AL_20km_Lat,Pos,20);         
AL_20km_Lon_changednum = Fun_Assign_Profile_According_Position(AL_20km_Lon,Pos,20);         
AL_20km_Surface_Type_changednum = Fun_Assign_Profile_According_Position(AL_20km_Surface_Type,Pos,20);
AL_20km_Layer_averaged_attenuated_backscatter_changednum = Fun_Assign_Profile_According_Position(AL_20km_Layer_averaged_attenuated_backscatter,Pos,20);
AL_20km_Layer_integrated_attenuated_backscatter_changednum = Fun_Assign_Profile_According_Position(AL_20km_Layer_integrated_attenuated_backscatter,Pos,20);
AL_20km_layer_integrated_attenuated_t_c_r_changednum = Fun_Assign_Profile_According_Position(AL_20km_layer_integrated_attenuated_total_color_ratio,Pos,20);
AL_20km_Integrated_Volume_Depolarization_Ratio_changednum = Fun_Assign_Profile_According_Position(AL_20km_Integrated_Volume_Depolarization_Ratio,Pos,20);
AL_20km_Integrated_Particulate_Depolarization_Ratio_changednum = Fun_Assign_Profile_According_Position(AL_20km_Integrated_Particulate_Depolarization_Ratio,Pos,20);
AL_20km_CAD_Score_changednum = Fun_Assign_Profile_According_Position(AL_20km_CAD_Score,Pos,20); 
AL_20km_Feature_Classification_Flags_changednum = Fun_Assign_Profile_According_Position(AL_20km_Feature_Classification_Flags,Pos,20); 
AL_20km_Midlayer_Temperature_changednum = Fun_Assign_Profile_According_Position(AL_20km_Midlayer_Temperature,Pos,20); 
AL_20km_Layer_Top_Temperature_changednum = Fun_Assign_Profile_According_Position(AL_20km_Layer_Top_Temperature,Pos,20); 
%AL_20km_Layer_Centroid_Temperature_changednum = Fun_Assign_Profile_According_Position(AL_20km_Layer_Centroid_Temperature,Pos,20); 
AL_20km_Tropopause_Height_changednum = Fun_Assign_Profile_According_Position(AL_20km_Tropopause_Height,Pos,20); 
AL_20km_ASR_Mean_changednum = Fun_Assign_Profile_According_Position(AL_20km_ASR_Mean,Pos,20);
%% 输出
output.top_right_20km_AL                  = top_right_20km_AL_changednum;
output.base_right_20km_AL                 = base_right_20km_AL_changednum;
output.topbin_right_20km_AL               = topbin_right_20km_AL_changednum;
output.basebin_right_20km_AL              = basebin_right_20km_AL_changednum;
output.topbin_right_20km_AL_Nochange               = topbin_right_20km_AL;
output.basebin_right_20km_AL_Nochange              = basebin_right_20km_AL;

output.AL_20km_Zmid=AL_20km_Zmid_changednum;
output.AL_20km_Lat=AL_20km_Lat_changednum;
output.AL_20km_Lon=AL_20km_Lon_changednum;
output.AL_20km_Surface_Type = AL_20km_Surface_Type_changednum;
output.AL_20km_Layer_averaged_attenuated_backscatter=AL_20km_Layer_averaged_attenuated_backscatter_changednum;
output.AL_20km_Layer_integrated_attenuated_backscatter=AL_20km_Layer_integrated_attenuated_backscatter_changednum;
output.AL_20km_layer_integrated_attenuated_total_color_ratio=AL_20km_layer_integrated_attenuated_t_c_r_changednum;
output.AL_20km_Integrated_Volume_Depolarization_Ratio=AL_20km_Integrated_Volume_Depolarization_Ratio_changednum;
output.AL_20km_Integrated_Particulate_Depolarization_Ratio=AL_20km_Integrated_Particulate_Depolarization_Ratio_changednum;
output.AL_20km_CAD_Score=AL_20km_CAD_Score_changednum;
output.AL_20km_Feature_Classification_Flags=AL_20km_Feature_Classification_Flags_changednum;
output.AL_20km_Midlayer_Temperature=AL_20km_Midlayer_Temperature_changednum;
output.AL_20km_Layer_Top_Temperature=AL_20km_Layer_Top_Temperature_changednum;
%output.AL_20km_Layer_Centroid_Temperature=AL_20km_Layer_Centroid_Temperature_changednum;
output.AL_20km_Tropopause_Height=AL_20km_Tropopause_Height_changednum;
output.AL_20km_ASR_Mean=AL_20km_ASR_Mean_changednum;
output.DEM_given_20km                  = DEM_20km_given;
%% -------------------------------------官方产品中80km云层各属性提取-----------------------------------------------------%%
%% 预分配内存
top_right_80km_AL                   = nan(size(Top_given_1));
base_right_80km_AL                  = nan(size(Top_given_1));
topbin_right_80km_AL                = nan(size(Top_given_1));
basebin_right_80km_AL               = nan(size(Top_given_1));
AL_80km_Zmid                      = nan(size(Top_given_1));
AL_80km_Lat                       = nan(size(Top_given_1));
AL_80km_Lon                       = nan(size(Top_given_1));
AL_80km_Surface_Type              = nan(size(Top_given_1));
AL_80km_Layer_averaged_attenuated_backscatter  = nan(size(Top_given_1));
AL_80km_Layer_integrated_attenuated_backscatter  = nan(size(Top_given_1));
AL_80km_layer_integrated_attenuated_total_color_ratio  = nan(size(Top_given_1));
AL_80km_Integrated_Volume_Depolarization_Ratio   = nan(size(Top_given_1));
AL_80km_Integrated_Particulate_Depolarization_Ratio=nan(size(Top_given_1));
AL_80km_CAD_Score=nan(size(Top_given_1));
AL_80km_Feature_Classification_Flags=nan(size(Top_given_1));
AL_80km_Midlayer_Temperature=nan(size(Top_given_1));
AL_80km_Layer_Top_Temperature=nan(size(Top_given_1));
%AL_80km_Layer_Centroid_Temperature=nan(size(Top_given_1));
AL_80km_Tropopause_Height=nan(size(Top_given_1));
AL_80km_ASR_Mean = nan(size(Top_given_1));
DEM_80km_given                   = nan(size(DEM_given_1,1)/16,1);
%% 计算
%Bin
top_right_80km_AL=Top_given_1;
top_right_80km_AL(True_horizontal_resolution_1~=80)=NaN;
base_right_80km_AL=Base_given_1;
base_right_80km_AL(True_horizontal_resolution_1~=80)=NaN;
for i=1:size(top_right_80km_AL,1)
    for j=1:size(top_right_80km_AL,2)
        if ~isnan(base_right_80km_AL(i,j))
            topbin_right_80km_AL(i,j)                  = find(round(double(Z),4) == round(double(top_right_80km_AL(i,j)),4),1,'last');
            basebin_right_80km_AL(i,j)                 = find(round(double(Z),4) == round(double(base_right_80km_AL(i,j)),4),1,'last');
        end
    end
end
%Zmid
AL_80km_Zmid=(top_right_80km_AL+base_right_80km_AL)/2;
%Lat && surface type && Tropopause_Height
[Row,~]=size(AL_80km_Lat);
for i=1:1:Row
    [m]=find(True_horizontal_resolution_1(i,:)==80);
    if ~isempty(m)
        AL_80km_Lat(i,m)=Lat_given_1(i,2);
        AL_80km_Lon(i,m)=Lon_given_1(i,2);
        AL_80km_Surface_Type(i,m) = Surface_Type_given_1(i,1);
        AL_80km_Tropopause_Height(i,m)=Tropopause_Height_given_1(i,1);
        AL_80km_ASR_Mean(i,m)  = Attenuated_Scattering_Ratio_Statistics_532_give_1(i,6*(m-1)+3);
    
    end
end
% 1. 获取参考数据的行数，并计算循环次数
%    使用 floor 确保循环次数为整数，避免索引超出范围
n_rows = size(True_horizontal_resolution_1, 1);
num_windows = floor(n_rows / 16);

% 2. 预分配输出数组的内存，这是MATLAB中提高循环效率的好习惯
DEM_80km_given = zeros(num_windows, 1);

% 3. 循环计算，使用 mean 并手动忽略 NaN 值
for i = 1:num_windows
    % 计算当前窗口的起始和结束索引
    start_idx = 16 * i - 15;
    end_idx = 16 * i;
    
    % 提取当前窗口内的数据
    window_data = DEM_given_1(start_idx:end_idx);
    
    % 过滤掉数据中的 NaN 值，然后计算平均值
    % 这种方式等价于 nanmean(window_data)
    DEM_80km_given(i) = mean(window_data(~isnan(window_data)));
end

%Layer_averaged_attenuated_backscatter
AL_80km_Layer_integrated_attenuated_backscatter=Integrated_Attenuated_Backscatter_532_given_1;
AL_80km_Layer_integrated_attenuated_backscatter(True_horizontal_resolution_1~=80)=NaN;
Width_80km_AL=basebin_right_80km_AL-topbin_right_80km_AL+1;
AL_80km_Layer_averaged_attenuated_backscatter=AL_80km_Layer_integrated_attenuated_backscatter./Width_80km_AL;
%Layer_integrated_attenuated_backscatter
AL_80km_Layer_integrated_attenuated_backscatter=AL_80km_Layer_integrated_attenuated_backscatter;
%layer-integrated attenuated total color ratio
AL_80km_layer_integrated_attenuated_total_color_ratio=Integrated_Attenuated_Total_Color_Ratio_given_1;
AL_80km_layer_integrated_attenuated_total_color_ratio(True_horizontal_resolution_1~=80)=NaN;
%layer-integrated volume depolarization ratio 
AL_80km_Integrated_Volume_Depolarization_Ratio=Integrated_Volume_Depolarization_Ratio_given_1;
AL_80km_Integrated_Volume_Depolarization_Ratio(True_horizontal_resolution_1~=80)=NaN;
%Integrated_Particulate_Depolarization_Ratio
AL_80km_Integrated_Particulate_Depolarization_Ratio=Integrated_Particulate_Depolarization_Ratio_given_1;
AL_80km_Integrated_Particulate_Depolarization_Ratio(True_horizontal_resolution_1~=80)=NaN;
%CAD_Score
AL_80km_CAD_Score=double(CAD_Score_given_1);
AL_80km_CAD_Score(True_horizontal_resolution_1~=80)=NaN;
%Feature_Classification_Flags
AL_80km_Feature_Classification_Flags=double(Feature_Classification_Flags_given_1);
AL_80km_Feature_Classification_Flags(True_horizontal_resolution_1~=80)=NaN;
%Midlayer_Temperature
AL_80km_Midlayer_Temperature=Midlayer_Temperature_given_1;
AL_80km_Midlayer_Temperature(True_horizontal_resolution_1~=80)=NaN;
%Layer_Top_Temperature
AL_80km_Layer_Top_Temperature=Layer_Top_Temperature_given_1;
AL_80km_Layer_Top_Temperature(True_horizontal_resolution_1~=80)=NaN;
%Midlayer_Temperature
%AL_80km_Layer_Centroid_Temperature=Layer_Centroid_Temperature_given_1;
%AL_80km_Layer_Centroid_Temperature(True_horizontal_resolution_1~=80)=NaN;

[top_right_80km_AL_changednum,Pos]            = Fun_CheckOfficialProfileNumber(top_right_80km_AL,'top_right_80km_AL',80); % 已转换成合适条数的80km廓线层顶
base_right_80km_AL_changednum=Fun_Assign_Profile_According_Position(base_right_80km_AL,Pos,80);
topbin_right_80km_AL_changednum               = Fun_Assign_Profile_According_Position(topbin_right_80km_AL,Pos,80); % 已转换成合适条数的80km廓线层顶
basebin_right_80km_AL_changednum              = Fun_Assign_Profile_According_Position(basebin_right_80km_AL,Pos,80); % 已转换成合适条数的80km廓线层顶
AL_80km_Zmid_changednum = Fun_Assign_Profile_According_Position(AL_80km_Zmid,Pos,80); 
AL_80km_Lat_changednum = Fun_Assign_Profile_According_Position(AL_80km_Lat,Pos,80);         
AL_80km_Lon_changednum = Fun_Assign_Profile_According_Position(AL_80km_Lon,Pos,80);
AL_80km_Surface_Type_changednum = Fun_Assign_Profile_According_Position(AL_80km_Surface_Type,Pos,80);
AL_80km_Layer_averaged_attenuated_backscatter_changednum = Fun_Assign_Profile_According_Position(AL_80km_Layer_averaged_attenuated_backscatter,Pos,80);
AL_80km_Layer_integrated_attenuated_backscatter_changednum = Fun_Assign_Profile_According_Position(AL_80km_Layer_integrated_attenuated_backscatter,Pos,80);
AL_80km_layer_integrated_attenuated_t_c_r_changednum = Fun_Assign_Profile_According_Position(AL_80km_layer_integrated_attenuated_total_color_ratio,Pos,80);
AL_80km_Integrated_Volume_Depolarization_Ratio_changednum = Fun_Assign_Profile_According_Position(AL_80km_Integrated_Volume_Depolarization_Ratio,Pos,80);
AL_80km_Integrated_Particulate_Depolarization_Ratio_changednum = Fun_Assign_Profile_According_Position(AL_80km_Integrated_Particulate_Depolarization_Ratio,Pos,80);
AL_80km_CAD_Score_changednum = Fun_Assign_Profile_According_Position(AL_80km_CAD_Score,Pos,80); 
AL_80km_Feature_Classification_Flags_changednum = Fun_Assign_Profile_According_Position(AL_80km_Feature_Classification_Flags,Pos,80); 
AL_80km_Midlayer_Temperature_changednum = Fun_Assign_Profile_According_Position(AL_80km_Midlayer_Temperature,Pos,80); 
AL_80km_Layer_Top_Temperature_changednum = Fun_Assign_Profile_According_Position(AL_80km_Layer_Top_Temperature,Pos,80); 

%AL_80km_Layer_Centroid_Temperature_changednum = Fun_Assign_Profile_According_Position(AL_80km_Layer_Centroid_Temperature,Pos,80); 
AL_80km_Tropopause_Height_changednum = Fun_Assign_Profile_According_Position(AL_80km_Tropopause_Height,Pos,80); 
AL_80km_ASR_Mean_changednum = Fun_Assign_Profile_According_Position(AL_80km_ASR_Mean,Pos,80); 

%% 输出
output.top_right_80km_AL                  = top_right_80km_AL_changednum;
output.base_right_80km_AL                 = base_right_80km_AL_changednum;
output.topbin_right_80km_AL               = topbin_right_80km_AL_changednum;
output.basebin_right_80km_AL              = basebin_right_80km_AL_changednum;
output.topbin_right_80km_AL_Nochange      = topbin_right_80km_AL;
output.basebin_right_80km_AL_Nochange     = basebin_right_80km_AL;

output.AL_80km_Zmid=AL_80km_Zmid_changednum;
output.AL_80km_Lat=AL_80km_Lat_changednum;
output.AL_80km_Lon=AL_80km_Lon_changednum;
output.AL_80km_Surface_Type = AL_80km_Surface_Type_changednum;
output.AL_80km_Layer_averaged_attenuated_backscatter=AL_80km_Layer_averaged_attenuated_backscatter_changednum;
output.AL_80km_Layer_integrated_attenuated_backscatter=AL_80km_Layer_integrated_attenuated_backscatter_changednum;
output.AL_80km_layer_integrated_attenuated_total_color_ratio=AL_80km_layer_integrated_attenuated_t_c_r_changednum;
output.AL_80km_Integrated_Volume_Depolarization_Ratio=AL_80km_Integrated_Volume_Depolarization_Ratio_changednum;
output.AL_80km_Integrated_Particulate_Depolarization_Ratio=AL_80km_Integrated_Particulate_Depolarization_Ratio_changednum;
output.AL_80km_CAD_Score=AL_80km_CAD_Score_changednum;
output.AL_80km_Feature_Classification_Flags=AL_80km_Feature_Classification_Flags_changednum;
output.AL_80km_Midlayer_Temperature=AL_80km_Midlayer_Temperature_changednum;
output.AL_80km_Layer_Top_Temperature=AL_80km_Layer_Top_Temperature_changednum;
%output.AL_80km_Layer_Centroid_Temperature=AL_80km_Layer_Centroid_Temperature_changednum;
output.AL_80km_Tropopause_Height=AL_80km_Tropopause_Height_changednum;
output.AL_80km_ASR_Mean = AL_80km_ASR_Mean_changednum;
output.DEM_given_80km                  = DEM_80km_given;
%% 层次在哪个分辨率被检测到
output.AL_True_horizontal_resolution_1=True_horizontal_resolution_1;
end

