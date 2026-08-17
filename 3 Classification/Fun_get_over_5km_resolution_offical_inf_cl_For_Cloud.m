function [output] = Fun_get_over_5km_resolution_offical_inf_cl_For_Cloud(CLay_05km)
%% 分别提取各分辨率下的层次产品
% 输入信息：
% CLay_05km：    5km云层
% ALay_05km：    5km气溶胶层
%% 将5/20/80km的气溶胶，云产品分别保存
global Z;
%% -------------------------------------官方产品中5km云层各属性提取-----------------------------------------------------%%
%% 提取
True_horizontal_resolution_1 = CLay_05km.Horizontal_Averaging;    
Top_given_1                  = CLay_05km.Layer_Top_Altitude;                        
Base_given_1                 = CLay_05km.Layer_Base_Altitude;                       
Lat_given_1                  = CLay_05km.Lat;                        
Lon_given_1                  = CLay_05km.Lon;                        
Integrated_Attenuated_Backscatter_532_given_1 = CLay_05km.Integrated_Attenuated_Backscatter_532; 
Integrated_Attenuated_Total_Color_Ratio_given_1 = CLay_05km.Integrated_Attenuated_Total_Color_Ratio; 
Integrated_Volume_Depolarization_Ratio_given_1 = CLay_05km.Integrated_Volume_Depolarization_Ratio; 
Integrated_Particulate_Depolarization_Ratio_given_1=CLay_05km.Integrated_Particulate_Depolarization_Ratio;
CAD_Score_given_1 = CLay_05km.CAD_Score;  
Feature_Classification_Flags_given_1 = CLay_05km.Feature_Classification_Flags;
Midlayer_Temperature_given_1=CLay_05km.Midlayer_Temperature;
%Layer_Centroid_Temperature_given_1=CLay_05km.Layer_Centroid_Temperature;
Tropopause_Height_given_1=CLay_05km.Tropopause_Height;
%% 预分配内存
topbin_right_5km_CL                 = nan(size(Top_given_1));
basebin_right_5km_CL                = nan(size(Top_given_1));
%% 计算
%Bin
top_right_5km_CL=Top_given_1;
top_right_5km_CL(True_horizontal_resolution_1~=5)=NaN;
base_right_5km_CL=Base_given_1;
base_right_5km_CL(True_horizontal_resolution_1~=5)=NaN;
for i=1:size(top_right_5km_CL,1)
    for j=1:size(top_right_5km_CL,2)
        if ~isnan(base_right_5km_CL(i,j))
            topbin_right_5km_CL(i,j)                  = find(round(double(Z),4) == round(double(top_right_5km_CL(i,j)),4),1,'last');
            basebin_right_5km_CL(i,j)                 = find(round(double(Z),4) == round(double(base_right_5km_CL(i,j)),4),1,'last');
        end
    end
end
%Zmid
CL_5km_Zmid=(top_right_5km_CL+base_right_5km_CL)/2;
%Lat && surface type && Tropopause_Height
CL_5km_Lat=nan(size(CL_5km_Zmid));
CL_5km_Lon=nan(size(CL_5km_Zmid));
CL_5km_Tropopause_Height=nan(size(CL_5km_Zmid));
[Row,~]=size(CL_5km_Lat);
for i=1:1:Row
    [m]=find(True_horizontal_resolution_1(i,:)==5);
    if ~isempty(m)
        CL_5km_Lat(i,m)=Lat_given_1(i,2);
        CL_5km_Lon(i,m)=Lon_given_1(i,2);
        CL_5km_Tropopause_Height(i,m)=Tropopause_Height_given_1(i,1);
    end
end
%Layer_averaged_attenuated_backscatter
Integrated_Attenuated_Backscatter_5km_CL=Integrated_Attenuated_Backscatter_532_given_1;
Integrated_Attenuated_Backscatter_5km_CL(True_horizontal_resolution_1~=5)=NaN;
Width_5km_CL=basebin_right_5km_CL-topbin_right_5km_CL+1;
CL_5km_Layer_averaged_attenuated_backscatter=Integrated_Attenuated_Backscatter_5km_CL./Width_5km_CL;
%Layer_integrated_attenuated_backscatter
CL_5km_Layer_integrated_attenuated_backscatter=Integrated_Attenuated_Backscatter_5km_CL;
%layer-integrated attenuated total color ratio
CL_5km_layer_integrated_attenuated_total_color_ratio=Integrated_Attenuated_Total_Color_Ratio_given_1;
CL_5km_layer_integrated_attenuated_total_color_ratio(True_horizontal_resolution_1~=5)=NaN;
%layer-integrated volume depolarization ratio 
CL_5km_Integrated_Volume_Depolarization_Ratio=Integrated_Volume_Depolarization_Ratio_given_1;
CL_5km_Integrated_Volume_Depolarization_Ratio(True_horizontal_resolution_1~=5)=NaN;
%Integrated_Particulate_Depolarization_Ratio
CL_5km_Integrated_Particulate_Depolarization_Ratio=Integrated_Particulate_Depolarization_Ratio_given_1;
CL_5km_Integrated_Particulate_Depolarization_Ratio(True_horizontal_resolution_1~=5)=NaN;
%CAD_Score
CL_5km_CAD_Score=double(CAD_Score_given_1);
CL_5km_CAD_Score(True_horizontal_resolution_1~=5)=NaN;
%Feature_Classification_Flags
CL_5km_Feature_Classification_Flags=double(Feature_Classification_Flags_given_1);
CL_5km_Feature_Classification_Flags(True_horizontal_resolution_1~=5)=NaN;
%Midlayer_Temperature
CL_5km_Midlayer_Temperature=Midlayer_Temperature_given_1;
CL_5km_Midlayer_Temperature(True_horizontal_resolution_1~=5)=NaN;
%Layer_Centroid_Temperature
%CL_5km_Layer_Centroid_Temperature=Layer_Centroid_Temperature_given_1;
CL_5km_Layer_Centroid_Temperature(True_horizontal_resolution_1~=5)=NaN;

%% 输出
output.top_right_5km_CL                   = top_right_5km_CL;
output.base_right_5km_CL                  = base_right_5km_CL;
output.topbin_right_5km_CL                = topbin_right_5km_CL;
output.basebin_right_5km_CL               = basebin_right_5km_CL;
output.CL_5km_Zmid                        =CL_5km_Zmid;
output.CL_5km_Lat                         =CL_5km_Lat;
output.CL_5km_Lon                         =CL_5km_Lon;
output.CL_5km_Layer_averaged_attenuated_backscatter=CL_5km_Layer_averaged_attenuated_backscatter;
output.CL_5km_Layer_integrated_attenuated_backscatter=CL_5km_Layer_integrated_attenuated_backscatter;
output.CL_5km_layer_integrated_attenuated_total_color_ratio=CL_5km_layer_integrated_attenuated_total_color_ratio;
output.CL_5km_Integrated_Volume_Depolarization_Ratio=CL_5km_Integrated_Volume_Depolarization_Ratio;
output.CL_5km_Integrated_Particulate_Depolarization_Ratio=CL_5km_Integrated_Particulate_Depolarization_Ratio;
output.CL_5km_CAD_Score                  =CL_5km_CAD_Score;              
output.CL_5km_Feature_Classification_Flags                  =CL_5km_Feature_Classification_Flags;
output.CL_5km_Midlayer_Temperature                  =CL_5km_Midlayer_Temperature;
output.CL_5km_Tropopause_Height=CL_5km_Tropopause_Height;
%output.CL_5km_Layer_Centroid_Temperature=CL_5km_Layer_Centroid_Temperature;
%% -------------------------------------官方产品中20km云层各属性提取-----------------------------------------------------%%
%% 预分配内存
top_right_20km_CL                   = nan(size(Top_given_1));
base_right_20km_CL                  = nan(size(Top_given_1));
topbin_right_20km_CL                = nan(size(Top_given_1));
basebin_right_20km_CL               = nan(size(Top_given_1));
CL_20km_Zmid                      = nan(size(Top_given_1));
CL_20km_Lat                       = nan(size(Top_given_1));
CL_20km_Layer_averaged_attenuated_backscatter  = nan(size(Top_given_1));
CL_20km_Layer_integrated_attenuated_backscatter  = nan(size(Top_given_1));
CL_20km_layer_integrated_attenuated_total_color_ratio  = nan(size(Top_given_1));
CL_20km_Integrated_Volume_Depolarization_Ratio   = nan(size(Top_given_1));
CL_20km_Integrated_Particulate_Depolarization_Ratio=nan(size(Top_given_1));
CL_20km_CAD_Score=nan(size(Top_given_1));
CL_20km_Feature_Classification_Flags=nan(size(Top_given_1));
CL_20km_Midlayer_Temperature=nan(size(Top_given_1));
%CL_20km_Layer_Centroid_Temperature=nan(size(Top_given_1));
CL_20km_Tropopause_Height=nan(size(Top_given_1));
%% 计算
%Bin
top_right_20km_CL=Top_given_1;
top_right_20km_CL(True_horizontal_resolution_1~=20)=NaN;
base_right_20km_CL=Base_given_1;
base_right_20km_CL(True_horizontal_resolution_1~=20)=NaN;
for i=1:size(top_right_20km_CL,1)
    for j=1:size(top_right_20km_CL,2)
        if ~isnan(base_right_20km_CL(i,j))
            topbin_right_20km_CL(i,j)                  = find(round(double(Z),4) == round(double(top_right_20km_CL(i,j)),4),1,'last');
            basebin_right_20km_CL(i,j)                 = find(round(double(Z),4) == round(double(base_right_20km_CL(i,j)),4),1,'last');
        end
    end
end
%Zmid
CL_20km_Zmid=(top_right_20km_CL+base_right_20km_CL)/2;
%Lat && surface type && Tropopause_Height
CL_20km_Lat=nan(size(CL_20km_Zmid));
CL_20km_Lon=nan(size(CL_20km_Zmid));
CL_20km_Tropopause_Height=nan(size(CL_20km_Zmid));
[Row,~]=size(CL_20km_Lat);
for i=1:1:Row
    [m]=find(True_horizontal_resolution_1(i,:)==20);
    if ~isempty(m)
        CL_20km_Lat(i,m)=Lat_given_1(i,2);
        CL_20km_Lon(i,m)=Lon_given_1(i,2);
        CL_20km_Tropopause_Height(i,m)=Tropopause_Height_given_1(i,1);
    end
end
%Layer_averaged_attenuated_backscatter
CL_20km_Layer_integrated_attenuated_backscatter=Integrated_Attenuated_Backscatter_532_given_1;
CL_20km_Layer_integrated_attenuated_backscatter(True_horizontal_resolution_1~=20)=NaN;
Width_20km_CL=basebin_right_20km_CL-topbin_right_20km_CL+1;
CL_20km_Layer_averaged_attenuated_backscatter=CL_20km_Layer_integrated_attenuated_backscatter./Width_20km_CL;
%Layer_integrated_attenuated_backscatter
CL_20km_Layer_integrated_attenuated_backscatter=CL_20km_Layer_integrated_attenuated_backscatter;
%layer-integrated attenuated total color ratio
CL_20km_layer_integrated_attenuated_total_color_ratio=Integrated_Attenuated_Total_Color_Ratio_given_1;
CL_20km_layer_integrated_attenuated_total_color_ratio(True_horizontal_resolution_1~=20)=NaN;
%layer-integrated volume depolarization ratio 
CL_20km_Integrated_Volume_Depolarization_Ratio=Integrated_Volume_Depolarization_Ratio_given_1;
CL_20km_Integrated_Volume_Depolarization_Ratio(True_horizontal_resolution_1~=20)=NaN;
%Integrated_Particulate_Depolarization_Ratio
CL_20km_Integrated_Particulate_Depolarization_Ratio=Integrated_Particulate_Depolarization_Ratio_given_1;
CL_20km_Integrated_Particulate_Depolarization_Ratio(True_horizontal_resolution_1~=20)=NaN;
%CAD_Score
CL_20km_CAD_Score=double(CAD_Score_given_1);
CL_20km_CAD_Score(True_horizontal_resolution_1~=20)=NaN;
%Feature_Classification_Flags
CL_20km_Feature_Classification_Flags=double(Feature_Classification_Flags_given_1);
CL_20km_Feature_Classification_Flags(True_horizontal_resolution_1~=20)=NaN;
%Midlayer_Temperature
CL_20km_Midlayer_Temperature=Midlayer_Temperature_given_1;
CL_20km_Midlayer_Temperature(True_horizontal_resolution_1~=20)=NaN;
%Layer_Centroid_Temperature
%CL_20km_Layer_Centroid_Temperature=Layer_Centroid_Temperature_given_1;
%CL_20km_Layer_Centroid_Temperature(True_horizontal_resolution_1~=20)=NaN;

[top_right_20km_CL_changednum,Pos]            = Fun_CheckOfficialProfileNumber(top_right_20km_CL,'top_right_20km_CL',20); % 已转换成合适条数的80km廓线层顶
base_right_20km_CL_changednum=Fun_Assign_Profile_According_Position(base_right_20km_CL,Pos,20);
topbin_right_20km_CL_changednum               = Fun_Assign_Profile_According_Position(topbin_right_20km_CL,Pos,20); % 已转换成合适条数的20km廓线层顶
basebin_right_20km_CL_changednum              = Fun_Assign_Profile_According_Position(basebin_right_20km_CL,Pos,20); % 已转换成合适条数的20km廓线层顶
CL_20km_Zmid_changednum = Fun_Assign_Profile_According_Position(CL_20km_Zmid,Pos,20); 
CL_20km_Lat_changednum = Fun_Assign_Profile_According_Position(CL_20km_Lat,Pos,20);         
CL_20km_Lon_changednum = Fun_Assign_Profile_According_Position(CL_20km_Lon,Pos,20);         
CL_20km_Layer_averaged_attenuated_backscatter_changednum = Fun_Assign_Profile_According_Position(CL_20km_Layer_averaged_attenuated_backscatter,Pos,20);
CL_20km_Layer_integrated_attenuated_backscatter_changednum = Fun_Assign_Profile_According_Position(CL_20km_Layer_integrated_attenuated_backscatter,Pos,20);
CL_20km_layer_integrated_attenuated_t_c_r_changednum = Fun_Assign_Profile_According_Position(CL_20km_layer_integrated_attenuated_total_color_ratio,Pos,20);
CL_20km_Integrated_Volume_Depolarization_Ratio_changednum = Fun_Assign_Profile_According_Position(CL_20km_Integrated_Volume_Depolarization_Ratio,Pos,20);
CL_20km_Integrated_Particulate_Depolarization_Ratio_changednum = Fun_Assign_Profile_According_Position(CL_20km_Integrated_Particulate_Depolarization_Ratio,Pos,20);
CL_20km_CAD_Score_changednum = Fun_Assign_Profile_According_Position(CL_20km_CAD_Score,Pos,20); 
CL_20km_Feature_Classification_Flags_changednum = Fun_Assign_Profile_According_Position(CL_20km_Feature_Classification_Flags,Pos,20); 
CL_20km_Midlayer_Temperature_changednum = Fun_Assign_Profile_According_Position(CL_20km_Midlayer_Temperature,Pos,20); 
%CL_20km_Layer_Centroid_Temperature_changednum = Fun_Assign_Profile_According_Position(CL_20km_Layer_Centroid_Temperature,Pos,20); 
CL_20km_Tropopause_Height_changednum = Fun_Assign_Profile_According_Position(CL_20km_Tropopause_Height,Pos,20); 

%% 输出
output.top_right_20km_CL                  = top_right_20km_CL_changednum;
output.base_right_20km_CL                 = base_right_20km_CL_changednum;
output.topbin_right_20km_CL               = topbin_right_20km_CL_changednum;
output.basebin_right_20km_CL              = basebin_right_20km_CL_changednum;
output.CL_20km_Zmid=CL_20km_Zmid_changednum;
output.CL_20km_Lat=CL_20km_Lat_changednum;
output.CL_20km_Lon=CL_20km_Lon_changednum;
output.CL_20km_Layer_averaged_attenuated_backscatter=CL_20km_Layer_averaged_attenuated_backscatter_changednum;
output.CL_20km_Layer_integrated_attenuated_backscatter=CL_20km_Layer_integrated_attenuated_backscatter_changednum;
output.CL_20km_layer_integrated_attenuated_total_color_ratio=CL_20km_layer_integrated_attenuated_t_c_r_changednum;
output.CL_20km_Integrated_Volume_Depolarization_Ratio=CL_20km_Integrated_Volume_Depolarization_Ratio_changednum;
output.CL_20km_Integrated_Particulate_Depolarization_Ratio=CL_20km_Integrated_Particulate_Depolarization_Ratio_changednum;
output.CL_20km_CAD_Score=CL_20km_CAD_Score_changednum;
output.CL_20km_Feature_Classification_Flags=CL_20km_Feature_Classification_Flags_changednum;
output.CL_20km_Midlayer_Temperature=CL_20km_Midlayer_Temperature_changednum;
%output.CL_20km_Layer_Centroid_Temperature=CL_20km_Layer_Centroid_Temperature_changednum;
output.CL_20km_Tropopause_Height=CL_20km_Tropopause_Height_changednum;
%% -------------------------------------官方产品中80km云层各属性提取-----------------------------------------------------%%
%% 预分配内存
top_right_80km_CL                   = nan(size(Top_given_1));
base_right_80km_CL                  = nan(size(Top_given_1));
topbin_right_80km_CL                = nan(size(Top_given_1));
basebin_right_80km_CL               = nan(size(Top_given_1));
CL_80km_Zmid                      = nan(size(Top_given_1));
CL_80km_Lat                       = nan(size(Top_given_1));
CL_80km_Layer_averaged_attenuated_backscatter  = nan(size(Top_given_1));
CL_80km_Layer_integrated_attenuated_backscatter  = nan(size(Top_given_1));
CL_80km_layer_integrated_attenuated_total_color_ratio  = nan(size(Top_given_1));
CL_80km_Integrated_Volume_Depolarization_Ratio   = nan(size(Top_given_1));
CL_80km_Integrated_Particulate_Depolarization_Ratio=nan(size(Top_given_1));
CL_80km_CAD_Score=nan(size(Top_given_1));
CL_80km_Feature_Classification_Flags=nan(size(Top_given_1));
CL_80km_Midlayer_Temperature=nan(size(Top_given_1));
%CL_80km_Layer_Centroid_Temperature=nan(size(Top_given_1));
CL_80km_Tropopause_Height=nan(size(Top_given_1));
%% 计算
%Bin
top_right_80km_CL=Top_given_1;
top_right_80km_CL(True_horizontal_resolution_1~=80)=NaN;
base_right_80km_CL=Base_given_1;
base_right_80km_CL(True_horizontal_resolution_1~=80)=NaN;
for i=1:size(top_right_80km_CL,1)
    for j=1:size(top_right_80km_CL,2)
        if ~isnan(base_right_80km_CL(i,j))
            topbin_right_80km_CL(i,j)                  = find(round(double(Z),4) == round(double(top_right_80km_CL(i,j)),4),1,'last');
            basebin_right_80km_CL(i,j)                 = find(round(double(Z),4) == round(double(base_right_80km_CL(i,j)),4),1,'last');
        end
    end
end
%Zmid
CL_80km_Zmid=(top_right_80km_CL+base_right_80km_CL)/2;
%Lat && surface type && Tropopause_Height
CL_80km_Lat=nan(size(CL_80km_Zmid));
CL_80km_Lon=nan(size(CL_80km_Zmid));
CL_80km_Tropopause_Height=nan(size(CL_80km_Zmid));
[Row,~]=size(CL_80km_Lat);
for i=1:1:Row
    [m]=find(True_horizontal_resolution_1(i,:)==80);
    if ~isempty(m)
        CL_80km_Lat(i,m)=Lat_given_1(i,2);
        CL_80km_Lon(i,m)=Lon_given_1(i,2);
        CL_80km_Tropopause_Height(i,m)=Tropopause_Height_given_1(i,1);
    end
end
%Layer_averaged_attenuated_backscatter
CL_80km_Layer_integrated_attenuated_backscatter=Integrated_Attenuated_Backscatter_532_given_1;
CL_80km_Layer_integrated_attenuated_backscatter(True_horizontal_resolution_1~=80)=NaN;
Width_80km_CL=basebin_right_80km_CL-topbin_right_80km_CL+1;
CL_80km_Layer_averaged_attenuated_backscatter=CL_80km_Layer_integrated_attenuated_backscatter./Width_80km_CL;
%Layer_integrated_attenuated_backscatter
CL_80km_Layer_integrated_attenuated_backscatter=CL_80km_Layer_integrated_attenuated_backscatter;
%layer-integrated attenuated total color ratio
CL_80km_layer_integrated_attenuated_total_color_ratio=Integrated_Attenuated_Total_Color_Ratio_given_1;
CL_80km_layer_integrated_attenuated_total_color_ratio(True_horizontal_resolution_1~=80)=NaN;
%layer-integrated volume depolarization ratio 
CL_80km_Integrated_Volume_Depolarization_Ratio=Integrated_Volume_Depolarization_Ratio_given_1;
CL_80km_Integrated_Volume_Depolarization_Ratio(True_horizontal_resolution_1~=80)=NaN;
%Integrated_Particulate_Depolarization_Ratio
CL_80km_Integrated_Particulate_Depolarization_Ratio=Integrated_Particulate_Depolarization_Ratio_given_1;
CL_80km_Integrated_Particulate_Depolarization_Ratio(True_horizontal_resolution_1~=80)=NaN;
%CAD_Score
CL_80km_CAD_Score=double(CAD_Score_given_1);
CL_80km_CAD_Score(True_horizontal_resolution_1~=80)=NaN;
%Feature_Classification_Flags
CL_80km_Feature_Classification_Flags=double(Feature_Classification_Flags_given_1);
CL_80km_Feature_Classification_Flags(True_horizontal_resolution_1~=80)=NaN;
%Midlayer_Temperature
CL_80km_Midlayer_Temperature=Midlayer_Temperature_given_1;
CL_80km_Midlayer_Temperature(True_horizontal_resolution_1~=80)=NaN;
%Midlayer_Temperature
%CL_80km_Layer_Centroid_Temperature=Layer_Centroid_Temperature_given_1;
%CL_80km_Layer_Centroid_Temperature(True_horizontal_resolution_1~=80)=NaN;

[top_right_80km_CL_changednum,Pos]            = Fun_CheckOfficialProfileNumber(top_right_80km_CL,'top_right_80km_CL',80); % 已转换成合适条数的80km廓线层顶
base_right_80km_CL_changednum=Fun_Assign_Profile_According_Position(base_right_80km_CL,Pos,80);
topbin_right_80km_CL_changednum               = Fun_Assign_Profile_According_Position(topbin_right_80km_CL,Pos,80); % 已转换成合适条数的80km廓线层顶
basebin_right_80km_CL_changednum              = Fun_Assign_Profile_According_Position(basebin_right_80km_CL,Pos,80); % 已转换成合适条数的80km廓线层顶
CL_80km_Zmid_changednum = Fun_Assign_Profile_According_Position(CL_80km_Zmid,Pos,80); 
CL_80km_Lat_changednum = Fun_Assign_Profile_According_Position(CL_80km_Lat,Pos,80);         
CL_80km_Lon_changednum = Fun_Assign_Profile_According_Position(CL_80km_Lon,Pos,80);
CL_80km_Layer_averaged_attenuated_backscatter_changednum = Fun_Assign_Profile_According_Position(CL_80km_Layer_averaged_attenuated_backscatter,Pos,80);
CL_80km_Layer_integrated_attenuated_backscatter_changednum = Fun_Assign_Profile_According_Position(CL_80km_Layer_integrated_attenuated_backscatter,Pos,80);
CL_80km_layer_integrated_attenuated_t_c_r_changednum = Fun_Assign_Profile_According_Position(CL_80km_layer_integrated_attenuated_total_color_ratio,Pos,80);
CL_80km_Integrated_Volume_Depolarization_Ratio_changednum = Fun_Assign_Profile_According_Position(CL_80km_Integrated_Volume_Depolarization_Ratio,Pos,80);
CL_80km_Integrated_Particulate_Depolarization_Ratio_changednum = Fun_Assign_Profile_According_Position(CL_80km_Integrated_Particulate_Depolarization_Ratio,Pos,80);
CL_80km_CAD_Score_changednum = Fun_Assign_Profile_According_Position(CL_80km_CAD_Score,Pos,80); 
CL_80km_Feature_Classification_Flags_changednum = Fun_Assign_Profile_According_Position(CL_80km_Feature_Classification_Flags,Pos,80); 
CL_80km_Midlayer_Temperature_changednum = Fun_Assign_Profile_According_Position(CL_80km_Midlayer_Temperature,Pos,80); 
%CL_80km_Layer_Centroid_Temperature_changednum = Fun_Assign_Profile_According_Position(CL_80km_Layer_Centroid_Temperature,Pos,80); 
CL_80km_Tropopause_Height_changednum = Fun_Assign_Profile_According_Position(CL_80km_Tropopause_Height,Pos,80); 

%% 输出
output.top_right_80km_CL                  = top_right_80km_CL_changednum;
output.base_right_80km_CL                 = base_right_80km_CL_changednum;
output.topbin_right_80km_CL               = topbin_right_80km_CL_changednum;
output.basebin_right_80km_CL              = basebin_right_80km_CL_changednum;
output.CL_80km_Zmid=CL_80km_Zmid_changednum;
output.CL_80km_Lat=CL_80km_Lat_changednum;
output.CL_80km_Lon=CL_80km_Lon_changednum;
output.CL_80km_Layer_averaged_attenuated_backscatter=CL_80km_Layer_averaged_attenuated_backscatter_changednum;
output.CL_80km_Layer_integrated_attenuated_backscatter=CL_80km_Layer_integrated_attenuated_backscatter_changednum;
output.CL_80km_layer_integrated_attenuated_total_color_ratio=CL_80km_layer_integrated_attenuated_t_c_r_changednum;
output.CL_80km_Integrated_Volume_Depolarization_Ratio=CL_80km_Integrated_Volume_Depolarization_Ratio_changednum;
output.CL_80km_Integrated_Particulate_Depolarization_Ratio=CL_80km_Integrated_Particulate_Depolarization_Ratio_changednum;
output.CL_80km_CAD_Score=CL_80km_CAD_Score_changednum;
output.CL_80km_Feature_Classification_Flags=CL_80km_Feature_Classification_Flags_changednum;
output.CL_80km_Midlayer_Temperature=CL_80km_Midlayer_Temperature_changednum;
%output.CL_80km_Layer_Centroid_Temperature=CL_80km_Layer_Centroid_Temperature_changednum;
output.CL_80km_Tropopause_Height=CL_80km_Tropopause_Height_changednum;
%% 层次在哪个分辨率被检测到
output.CL_True_horizontal_resolution_1=True_horizontal_resolution_1;
end

