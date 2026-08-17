function [ output_CALIPSO_L1_data] = Fun_getCALIPSO_L1( filename,lat_start,lat_end,start_profile,end_profile )
% FUN_GETCALIPSO_L1 此函数获取的是L1的原始数据信息，根据限制条件进行读取输出。
% 写于2018年3月，改于2019年3月4日

% 输入信息：
% filename：       文件的全部路径，包括文件名
% lat_start：      起始纬度（可省以[]代替）
% lat_end：        终止纬度（可省以[]代替）
% start_profile：  从第几条廓线开始（可省）
% end_profile:     共需提取多少条廓线（可省）


% 输出信息：
% Temperature：                     温度（原始）
% Relative_Humidity：               相对湿度（原始）
% Pressure：                        压强（原始）
% Surface_Wind_Speeds：             地面风速（原始）
% beta_m_initial_532：              532nm空气分子后向散射系数（原始）
% beta_m_initial_1064：             1064nm空气分子后向散射系数（原始）
% beta_O3_initial_532：             532nm臭氧分子后向散射系数（原始）
% TAB_532：                         532nm波段总的衰减后向散射系数 （原始）          
% VAB_532：                         532nm波段垂直方向衰减后向散射系数 （原始）      
% Attenuated_Backscatter_1064：     1064nm波段的衰减后向散射信息（原始）
% Temperature_interpolation：       温度（插值后）
% Relative_Humidity_interpolation： 相对湿度（插值后）
% beta_m_interpolation_532：        532nm空气分子后向散射系数（插值后）
% beta_m_interpolation_1064：       1064nm空气分子后向散射系数（插值后）
% beta_O3_interpolation_532：       532nm臭氧分子后向散射系数（插值后）
% Day_Night_Flag：                  日夜信息
% Number_of_particles：             廓线条数
% Lidar_Data_Altitudes：            激光雷达全路径高度序列
% Met_Data_Altitudes：              辅助气象数据高度序列
% Lon_L1_select：                   经度
% Lat_L1_select：                   纬度
% Surface_Elevation：               地表高程
% Time_L1：                         时间信息
% meanHoriDis：                     最大水平距离（指的是区域内最大水平范围）

              
%% 1.找到限制纬度区域内所对应的廓线（从第几条开始共多少条）
variable = 'Latitude';
[~, lat_whole] = readHDF(filename,variable);
if ~isempty(lat_start)&& ~isempty(lat_end)
    variable = 'Latitude';
    [~, lat] = readHDF(filename,variable);
    ilat(1)  = find(round(double(lat),4) == round(double(lat_start),4),1,'first');
    ilat(2)  = find(round(double(lat),4) == round(double(lat_end),4),1,'last');
    
    disp(['Reading CALIPSO L1：',filename])
    fprintf('New latitudes %f %f\n',lat(ilat(1)),lat(ilat(2)));
else
    ilat(1) = start_profile;
    ilat(2) = end_profile;
end
indA = ilat(1)-1; % DECREMENT for readHDF!1!
indB = ilat(2)-ilat(1)+1;
    
%% 2.读取已选择的廓线信息 
% 经纬度
start       = [indA 0];
edges       = [indB 1];
variable    = 'Longitude';
[~, Lon] = readHDF(filename,variable,start,edges);% 读取经度数据
variable    = 'Latitude';
[~, Lat] = readHDF(filename,variable,start,edges);% 读取经度数据
lat_start_inwhole = find(lat_whole(:,1) == Lat(1,1));
lat_end_inwhole = find(lat_whole(:,1) == Lat(end,1)); % 选中的廓线在总廓线中的终止位置
ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
%地表类型
variable = 'IGBP_Surface_Type';
[~,IGBP_Surface_Type] = readHDF(filename,variable,start,edges);
%对流层高度
variable = 'Tropopause_Height';
[~,Tropopause_Height] = readHDF(filename,variable,start,edges);
%Off_Nadir_Angle
variable = 'Off_Nadir_Angle';
[~,Off_Nadir_Angle] = readHDF(filename,variable,start,edges);
% 时间
variable   = 'Profile_Time'; % （这个时间指的是卫星运行的每个颗粒的时间）读取配置文件时间 这部分数据从1993年1月1日起以秒为单位公布?国际原子时间（TAI）。
[~, TAI] = readHDF(filename,variable,start,edges);
Time_L1    = Fun_convertTAITime(TAI); %时间序列转换（时差等）。
len        = length(Time_L1);
datestr([Time_L1(1) Time_L1(len)],21) 
% 地面高程
variable                  = 'Surface_Elevation';% 这是从GTOPO30数字高程图（DEM）获得的激光足迹表面高度，以高于当地平均海平面的公里数表示 。
[~, Surface_Elevation] = readHDF(filename,variable,start,edges);
Surface_Elevation         =double(Surface_Elevation)*1e3;% 单位变换，乘于1000，单位变为米 （这里海拔指的是地面高程吗？1000km以上）
% 辅助气象数据的高度（33）
Met_Data_Altitudes = hdfread(filename,'/metadata', 'Fields', 'Met_Data_Altitudes');
Met_Data_Altitudes =double(Met_Data_Altitudes{1,1}); 
flagAlt            = Met_Data_Altitudes>0;% 辅助气象数据生成掩膜（大于0的部分为1，其他为0）。
Met_Data_Altitudes = Met_Data_Altitudes(flagAlt);
% 激光雷达数据高度（583）
Lidar_Data_Altitudes = hdfread(filename,'/metadata', 'Fields',...
    'Lidar_Data_Altitudes');
Lidar_Data_Altitudes = Lidar_Data_Altitudes{1,1}; % 为什么会有{1,1}？因为原来的激光雷达数据高度储存方式是元胞数组型，这里提取出矩阵型。
% 筛选出的颗粒之间的最大距离 
maxHoriDis = distance(min(Lat),min(Lon),max(Lat),max(Lon),6371);% 6371为地球平均半径
% 日夜标志
[file_pathstr,file_name,file_ext]=fileparts(filename);
filename_tmp1=[file_name,file_ext];
indTime    = strfind(filename_tmp1,'.');              % 在命名信息中定位两.的位置（两点之间的内容即为每次记录的时间信息）
fileTime   = filename_tmp1(indTime(1):indTime(2));    % 在命名信息中提取时间信息
DayOrNight = fileTime(22);

variable        = 'Perpendicular_Amplifier_Gain_532';
[~, Perpendicular_Amplifier_Gain_532] = readHDF(filename,variable,start,edges);
Perpendicular_Amplifier_Gain_532(Perpendicular_Amplifier_Gain_532 == -9999)=nan;  

variable        = 'Parallel_Amplifier_Gain_532';
[~, Parallel_Amplifier_Gain_532] = readHDF(filename,variable,start,edges);
Parallel_Amplifier_Gain_532(Parallel_Amplifier_Gain_532 == -9999)=nan; 

variable        = 'Calibration_Constant_532';
[~, Calibration_Constant_532] = readHDF(filename,variable,start,edges);
Calibration_Constant_532(Calibration_Constant_532 < 3E10 | Calibration_Constant_532 >8E10)=nan; 

variable        = 'Noise_Scale_Factor_532_Parallel';
[~, Noise_Scale_Factor_532_Parallel] = readHDF(filename,variable,start,edges);
Noise_Scale_Factor_532_Parallel(Noise_Scale_Factor_532_Parallel < 4 | Noise_Scale_Factor_532_Parallel > 8)=nan;

variable        = 'Noise_Scale_Factor_532_Perpendicular';
[~, Noise_Scale_Factor_532_Perpendicular] = readHDF(filename,variable,start,edges);
Noise_Scale_Factor_532_Perpendicular(Noise_Scale_Factor_532_Perpendicular < 3.4 | Noise_Scale_Factor_532_Perpendicular > 8)=nan; 

variable        = 'Parallel_RMS_Baseline_532';
[~, Parallel_RMS_Baseline_532] = readHDF(filename,variable,start,edges);
Parallel_RMS_Baseline_532(Parallel_RMS_Baseline_532 < 0 | Parallel_RMS_Baseline_532 > 3200)=nan; 

variable        = 'Perpendicular_RMS_Baseline_532';
[~, Perpendicular_RMS_Baseline_532] = readHDF(filename,variable,start,edges);
Perpendicular_RMS_Baseline_532(Perpendicular_RMS_Baseline_532 < 0 | Perpendicular_RMS_Baseline_532 > 3200)=nan; 

variable        = 'Laser_Energy_532';
[~, Laser_Energy_532] = readHDF(filename,variable,start,edges);
Laser_Energy_532(Laser_Energy_532 < 0.003 | Laser_Energy_532 > 0.135)=nan; 

variable        = 'Number_Bins_Shift';
[~, Number_Bins_Shift] = readHDF(filename,variable,start,edges);
Number_Bins_Shift(Number_Bins_Shift < -8 | Number_Bins_Shift > 8)=nan; 
%% 3.获取目标区域的 温湿压风、空气分子数密度、臭氧数密度、532nm总的后向衰减散射系数、532波段空气分子的瑞利（后向）散射截面、532波段臭氧的吸收截面。
%（温、湿、压、风、分子数密度、臭氧数密度）——从GMAO提供的辅助气象数据获得。
% 532波段空气分子的瑞利（后向）散射截面、532波段臭氧的吸收截面、532nm总的后向衰减散射系数、532nm垂直后向衰减散射系数、1064nm后向衰减散射系数——激光雷达数据

% 读取文件中所有区域的以上要素数据
start               = [indA 0];
edges               = [indB 33];
variable            = 'Temperature';% 温度
[~, Temperature] = readHDF(filename,variable,start,edges);
Temperature         = Temperature(:,flagAlt);
Temperature(find(Temperature == -9999)) = nan;
variable                  = 'Relative_Humidity';% 相对湿度
[~, Relative_Humidity] = readHDF(filename,variable,start,edges);
Relative_Humidity         = Relative_Humidity(:,flagAlt);

variable         = 'Pressure';% 压强
[~, Pressure] = readHDF(filename,variable,start,edges);
Pressure         = Pressure(:,flagAlt);

variable                         = 'Molecular_Number_Density';% 空气分子数密度
[~, Molecular_Number_Density] = readHDF(filename,variable,start,edges);
Molecular_Number_Density         = Molecular_Number_Density(:,flagAlt);
% 清除掉填充值，转换成元胞数组格式
for i = 1:size(Molecular_Number_Density,1)
    Molecular_Number_temp                       =Molecular_Number_Density(i,:);
    Molecular_Number_temp(Molecular_Number_temp ==-9999) = [];
    Molecular_Number_Density_cell{i}            =Molecular_Number_temp;
end
variable                     = 'Ozone_Number_Density';% 臭氧分子的数密度
[~, Ozone_Number_Density] = readHDF(filename,variable,start,edges);
Ozone_Number_Density         = Ozone_Number_Density(:,flagAlt);
% 清除掉填充值，转换成元胞数组格式
for i = 1:size(Ozone_Number_Density,1)
    Ozone_Number_temp                   =Ozone_Number_Density(i,:);
    Ozone_Number_temp(Ozone_Number_temp ==-9999) = [];
    Ozone_Number_Density_cell{i}        =Ozone_Number_temp;
end


start                       = [indA 0];
edges                       = [indB 2];
variable                    = 'Surface_Wind_Speeds';% 地表风速
[~, Surface_Wind_Speeds] = readHDF(filename,variable,start,edges);

start           = [indA 0];
edges           = [indB 583];
variable        = 'Total_Attenuated_Backscatter_532';% 532总的衰减散射系数
[~, TAB_532] = readHDF(filename,variable,start,edges);
% TAB_532(TAB_532 == -9999)=nan;
TAB_532(TAB_532 < -0.1 | TAB_532 >3.3)=nan;

variable        = 'Perpendicular_Attenuated_Backscatter_532';% 532nm垂直后向衰减散射系数
[~, VAB_532] = readHDF(filename,variable,start,edges);
VAB_532(VAB_532 == -9999)=nan;  

variable                                                = 'Attenuated_Backscatter_1064';% 1064nm后向衰减散射系数
[~, Attenuated_Backscatter_1064]                     = readHDF(filename,variable,start,edges);
Attenuated_Backscatter_1064(Attenuated_Backscatter_1064 == -9999)=nan;  

CrossSection_Rayleigh_Backscatter_532 = hdfread(filename, '/metadata', 'Fields',...
    'Rayleigh_Backscatter_Cross-section_532');% 532波段空气分子瑞利后向散射截面（常数）
CrossSection_Ozone_Absorption_532 = hdfread(filename, '/metadata', 'Fields',...
    'Ozone_Absorption_Cross-section_532');% 532波段臭氧的吸收截面（常数）
CrossSection_Rayleigh_Backscatter_1064 = hdfread(filename, '/metadata', 'Fields',...
    'Rayleigh_Backscatter_Cross-section_1064');% 1064波段空气分子瑞利后向散射截面（常数）
CrossSection_Ozone_Absorption_1064 = hdfread(filename, '/metadata', 'Fields',...
    'Ozone_Absorption_Cross-section_1064');% 1064波段臭氧的吸收截面（常数）为0。

%% 3.计算空气分子的后向散射系数和臭氧的吸收系数（个/m）
for i = 1:size(Molecular_Number_Density_cell,2)
    air_molecule_backscattering_coefficient_initial_532{i}  = Molecular_Number_Density_cell{i} * CrossSection_Rayleigh_Backscatter_532{1,1}; % 空气分子数密度*532nm瑞利后向散射截面=空气分子后向散射系数。
    air_molecule_backscattering_coefficient_initial_1064{i} = Molecular_Number_Density_cell{i} * CrossSection_Rayleigh_Backscatter_1064{1,1}; % 空气分子数密度*532nm瑞利后向散射截面=空气分子后向散射系数。
    Ozone_absorption_coefficient_initial_532{i}             = Ozone_Number_Density_cell{i} * CrossSection_Ozone_Absorption_532{1,1}; % 臭氧数密度*532nm臭氧吸收截面=臭氧吸收系数。
    Ozone_absorption_coefficient_initial_1064{i}            = Ozone_Number_Density_cell{i} * CrossSection_Ozone_Absorption_1064{1,1}; % 臭氧数密度*532nm臭氧吸收截面=臭氧吸收系数。

end
%% 4.将辅助气象数据（33—>31）插值成与下行全分辨率LIDAR数据高度序列（583）一样
Temperature_interpolation                                  = nan(size(Temperature,1),length(Lidar_Data_Altitudes));
Relative_Humidity_interpolation                            = nan(size(Relative_Humidity,1),length(Lidar_Data_Altitudes));
Pressure_interpolation                                     = nan(size(Pressure,1),length(Lidar_Data_Altitudes));
air_molecule_backscattering_coefficient_532_interpolation  = nan(size(air_molecule_backscattering_coefficient_initial_532,2),length(Lidar_Data_Altitudes));
air_molecule_backscattering_coefficient_1064_interpolation = nan(size(air_molecule_backscattering_coefficient_initial_1064,2),length(Lidar_Data_Altitudes));
Ozone_absorption_coefficient_532_interpolation             = nan(size(Ozone_absorption_coefficient_initial_532,2),length(Lidar_Data_Altitudes));
Ozone_absorption_coefficient_1064_interpolation             = nan(size(Ozone_absorption_coefficient_initial_1064,2),length(Lidar_Data_Altitudes));

for i=1:size(TAB_532,1) % 第i条廓线
    % 温度
    last_num = find(~isnan(Temperature(i,:)),1,'last');
    Temperature_interpolation(i,:)                                  = interp1(Met_Data_Altitudes(1:last_num),Temperature(i,1:last_num),Lidar_Data_Altitudes,'linear','extrap');% 利用辅助温度数据及辅助温度数据所对应的高度，利用线性插值的方法，差值得到海平面以上高度海拔（666个点）的温度序列数据。
    % 湿度
    Relative_Humidity_interpolation(i,:)                            = interp1(Met_Data_Altitudes,Relative_Humidity(i,:),Lidar_Data_Altitudes,'linear','extrap');% 利用辅助温度数据及辅助温度数据所对应的高度，利用线性插值的方法，差值得到海平面以上高度海拔（666个点）的温度序列数据。
    % 压强
    Pressure_interpolation(i,:)                                     = interp1(Met_Data_Altitudes,Pressure(i,:),Lidar_Data_Altitudes,'linear','extrap');% 利用辅助气象数据（压强）及辅助温度数据所对应的高度，利用线性插值的方法，差值得到海平面以上高度海拔（666个点）的压强序列数据。
    % 空气分子的后向散射系数532
    air_molecule_backscattering_coefficient_532_interpolation(i,:)  = interp1(Met_Data_Altitudes(1:length(air_molecule_backscattering_coefficient_initial_532{i})),air_molecule_backscattering_coefficient_initial_532{i},Lidar_Data_Altitudes,'linear','extrap');
    % 空气分子的后向散射系数1064
    air_molecule_backscattering_coefficient_1064_interpolation(i,:) = interp1(Met_Data_Altitudes(1:length(air_molecule_backscattering_coefficient_initial_1064{i})),air_molecule_backscattering_coefficient_initial_1064{i},Lidar_Data_Altitudes,'linear','extrap');
    % 臭氧的吸收系数
    Ozone_absorption_coefficient_532_interpolation(i,:)             = interp1(Met_Data_Altitudes(1:length(Ozone_absorption_coefficient_initial_532{i})),Ozone_absorption_coefficient_initial_532{i},Lidar_Data_Altitudes,'linear','extrap');
    Ozone_absorption_coefficient_1064_interpolation(i,:)             = interp1(Met_Data_Altitudes(1:length(Ozone_absorption_coefficient_initial_1064{i})),Ozone_absorption_coefficient_initial_1064{i},Lidar_Data_Altitudes,'linear','extrap');

end
%% 输出数据
% 目标区域提取出的
output_CALIPSO_L1_data.Number_Bins_Shift=Number_Bins_Shift;
output_CALIPSO_L1_data.Laser_Energy_532=Laser_Energy_532;
output_CALIPSO_L1_data.Perpendicular_RMS_Baseline_532=Perpendicular_RMS_Baseline_532;
output_CALIPSO_L1_data.Parallel_RMS_Baseline_532=Parallel_RMS_Baseline_532;
output_CALIPSO_L1_data.Noise_Scale_Factor_532_Perpendicular=Noise_Scale_Factor_532_Perpendicular;
output_CALIPSO_L1_data.Noise_Scale_Factor_532_Parallel=Noise_Scale_Factor_532_Parallel;
output_CALIPSO_L1_data.Calibration_Constant_532=Calibration_Constant_532;
output_CALIPSO_L1_data.Parallel_Amplifier_Gain_532=Parallel_Amplifier_Gain_532;
output_CALIPSO_L1_data.Perpendicular_Amplifier_Gain_532=Perpendicular_Amplifier_Gain_532;
output_CALIPSO_L1_data.CrossSection_Rayleigh_Backscatter_532=CrossSection_Rayleigh_Backscatter_532;
output_CALIPSO_L1_data.CrossSection_Ozone_Absorption_532=CrossSection_Ozone_Absorption_532;
output_CALIPSO_L1_data.CrossSection_Rayleigh_Backscatter_1064=CrossSection_Rayleigh_Backscatter_1064;
output_CALIPSO_L1_data.CrossSection_Ozone_Absorption_1064=CrossSection_Ozone_Absorption_1064;
output_CALIPSO_L1_data.Ozone_Number_Density            = Ozone_Number_Density;
output_CALIPSO_L1_data.Molecular_Number_Density        = Molecular_Number_Density;
output_CALIPSO_L1_data.Temperature                     = Temperature;
output_CALIPSO_L1_data.Relative_Humidity               = Relative_Humidity;
output_CALIPSO_L1_data.Pressure                        = Pressure;
output_CALIPSO_L1_data.Surface_Wind_Speeds             = Surface_Wind_Speeds;
output_CALIPSO_L1_data.beta_m_initial_532              = air_molecule_backscattering_coefficient_initial_532;%（个/m）
output_CALIPSO_L1_data.beta_m_initial_1064             = air_molecule_backscattering_coefficient_initial_1064;%（个/m）
output_CALIPSO_L1_data.alpha_O3_initial_532            = Ozone_absorption_coefficient_initial_532;%（个/m）
output_CALIPSO_L1_data.alpha_O3_initial_1064           = Ozone_absorption_coefficient_initial_1064;%（个/m）
output_CALIPSO_L1_data.TAB_532                         = TAB_532;
output_CALIPSO_L1_data.VAB_532                         = VAB_532;
output_CALIPSO_L1_data.Attenuated_Backscatter_1064     = Attenuated_Backscatter_1064;
% 经过插值之后的
output_CALIPSO_L1_data.Temperature_interpolation       = Temperature_interpolation;
output_CALIPSO_L1_data.Relative_Humidity_interpolation = Relative_Humidity_interpolation;
output_CALIPSO_L1_data.Pressure_interpolation          = Pressure_interpolation;
output_CALIPSO_L1_data.beta_m_interpolation_532        = air_molecule_backscattering_coefficient_532_interpolation;%（个/m）
output_CALIPSO_L1_data.beta_m_interpolation_1064       = air_molecule_backscattering_coefficient_1064_interpolation;%（个/m）
output_CALIPSO_L1_data.alpha_O3_interpolation_532       = Ozone_absorption_coefficient_532_interpolation;%（个/m）
output_CALIPSO_L1_data.alpha_O3_interpolation_1064       = Ozone_absorption_coefficient_1064_interpolation;%（个/m）
% 属性信息
output_CALIPSO_L1_data.fileName                        = filename;
output_CALIPSO_L1_data.Number_Of_Profile               = indB;
output_CALIPSO_L1_data.profile_start_end               = ilat2;
output_CALIPSO_L1_data.Lon                             = Lon;
output_CALIPSO_L1_data.Lat                             = Lat;
output_CALIPSO_L1_data.Lidar_Data_Altitudes            = Lidar_Data_Altitudes;
output_CALIPSO_L1_data.Met_Data_Altitudes              = Met_Data_Altitudes;
output_CALIPSO_L1_data.Surface_Elevation               = Surface_Elevation;% 地表各颗粒海拔（是实际地表的海拔高度/m）
output_CALIPSO_L1_data.meanHoriDis                     = maxHoriDis;
output_CALIPSO_L1_data.Day_Night_Flag                  = DayOrNight;
output_CALIPSO_L1_data.Off_Nadir_Angle                 = Off_Nadir_Angle;
output_CALIPSO_L1_data.IGBP_Surface_Type               = IGBP_Surface_Type;
output_CALIPSO_L1_data.Tropopause_Height               = Tropopause_Height;

end

