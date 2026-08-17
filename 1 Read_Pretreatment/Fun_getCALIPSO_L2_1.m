function [output_CALIPSO_L2_data] = Fun_getCALIPSO_L2( filename,lat_lim,profile_start_and_length)
% FUN_GETCALIPSO_L2 此函数获取的是L2的产品信息，根据限制条件进行读取输出。
% 写于2018年4月，修改于2019年3月4日

% 输入信息：
% filename：                                          存放路径信息（完整路径完整名称）
% lat_lim：                                           纬度起止信息
% profile_start_and_length                            起始廓线及廓线条数


% 输出信息：
% fileName：                                          确定读取的文件名字
% time：                                              经过研究区域的时间序列
% Layer_Base_Altitude：                               层底高度
% Layer_Top_Altitude：                                层顶高度
% Final_532_Lidar_Ratio：                             最终确定的激光雷达比
% Measured_Two_Way_Transmittance_532：                测得的532双向透过率
% Lidar_Ratio_532_Selection_Method：                  532激光雷达比的选择方法
% Integrated_Attenuated_Backscatter_532：             532整层积分后向散射系数
% Layer_Effective_532_Multiple_Scattering_Factor：    532层次多重散射因子
% dist：                                              选取的廓线与目标点之间的距离
% maxHoriDis：                                        研究区域最大的的水平距离
% minint：                                            求出符合要求的最近距离的点在总符合要求的输出序列中的位置（排序）。
% number_of_profile：                                 符合条件的颗粒数
%% 读取05kmALay数据
if ~isempty(strfind(filename,'05kmALay') )
    if any(isnan(profile_start_and_length))  % 如果前文没有完全指出实际用到的廓线，则下面开始计算；若已指出则不必计算，直接读取即可。
        % 1.找到限制纬度区域内所对应的廓线（从第几条开始共多少条）
        variable = 'Latitude';
        [~, lat_whole] = readHDF(filename,variable);
        % 选取起始廓线的位置 方法1：
        lat_the_first_column = lat_whole(:,1);
        lat_the_last_column = lat_whole(:,3);
        % 先看纬度是从大到小呢，还是从小到大
        if lat_the_first_column(1) < lat_the_first_column(end)                 % 从小到大
            start_profile = find(round(lat_the_last_column,4) > round(lat_lim(1),4),1,'first'); % 第一次大
            end_profile = find(round(lat_the_first_column,4) < round(lat_lim(2),4),1,'last');    % 最后一次小
        else
            start_profile = find(round(lat_the_first_column,4) < round(lat_lim(2),4),1,'first'); % 第一次小
            end_profile = find(round(lat_the_last_column,4) > round(lat_lim(1),4),1,'last');  % 最后一次大
        end
        ilat = [start_profile,end_profile];
        indA = ilat(1)-1; % DECREMENT for readHDF!1!  % 用readhdf时提取字段时，indA为起始廓线位置-1，indB为拟提取的总廓线条数。
        indB = (ilat(2)-ilat(1)+1);  % 范围内的条数。
    else
        indA = profile_start_and_length(1)-1;
        indB = profile_start_and_length(2)-profile_start_and_length(1)+1;
    end
    % 2.调整廓线条数(需Horizontal_Averaging和Layer_Top_Altitude配合使用)
    start = [indA 0];
    edges = [indB -9];
    variable = 'Horizontal_Averaging'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
    [~, Horizontal_Averaging] = readHDF(filename,variable,start,edges);
    variable = 'Layer_Top_Altitude'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
    [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
    top_right_80km = nan(size(Layer_Top_Altitude));        % 官方80km检测出的层次
    for i=1:size(Horizontal_Averaging,1)
        for j=1:size(Horizontal_Averaging,2)
            if Horizontal_Averaging(i,j) ==80
                top_right_80km(i,j) = Layer_Top_Altitude(i,j);
            end
        end
    end
    change_num = Fun_Change_num(top_right_80km);
    indA = indA + change_num(1); % 前后均截断一部分，所以起始位置往后移，故为加号。
    indB = indB - change_num(1) - change_num(2); % 实际上就是indB - residue；
    % 3.开始读取
    % 经纬度
    start = [indA 0];
    edges = [indB 3];
    variable = 'Longitude';
    [~, Lon] = readHDF(filename,variable,start,edges);
    variable = 'Latitude';
    [~, Lat] = readHDF(filename,variable,start,edges);
    lat_start_inwhole = find(round(lat_whole(:,1),4) == round(Lat(1,1),4));
    lat_end_inwhole = find(round(lat_whole(:,1),4) == round(Lat(end,1),4)); % 选中的廓线在总廓线中的终止位置
    ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
    % DEM地表高程
    start = [indA 0];
    edges = [indB -9];
    variable = 'DEM_Surface_Elevation';
    [~, DEM_Surface_Elevation] = readHDF(filename,variable,start,edges);
    % (版本3和版本4数据不同，字段名称有所改变，故读取方式相应改变)
    try
        variable = 'Lidar_Surface_Elevation';   % 激光雷达测得的地表高程
        [~, Lidar_Surface_Elevation] = readHDF(filename,variable,start,edges);
        variable = 'Surface_Elevation_Detection_Frequency';   % 地表高程探测频率
        [~, Surface_Elevation_Detection_Frequency] = readHDF(filename,variable,start,edges);
        A=cell(size(Surface_Elevation_Detection_Frequency,1),1); % 预分配空间
        horizontal_resolution_Initial_detection_surface = nan(size(Surface_Elevation_Detection_Frequency));  % 第一次探测到层底时的水平分辨率
        detection_frequency_5km = nan(size(Surface_Elevation_Detection_Frequency));                                  % 5km检测到层底的频率。
        for i=1:size(Surface_Elevation_Detection_Frequency,1)
            A{i,1} = dec2bin(Surface_Elevation_Detection_Frequency(i,1),8);  % 转成8位二进制格式
            horizontal_resolution_Initial_detection_surface(i) = bin2dec(A{i,1}(1:3));
            detection_frequency_5km(i) = bin2dec(A{i,1}(6:8));
        end
        variable = 'Column_Optical_Depth_Aerosols_532';                  % 列气溶胶层的光学厚度532
        [~, Column_AOD_532] = readHDF(filename,variable,start,edges); 
        variable = 'Column_Optical_Depth_Aerosols_1064';                 % 列气溶胶层的光学厚度1064
        [~, Column_AOD_1064] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_532';             % 列平流层的光学厚度532
        [~, Column_SOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_1064';            % 列平流层的光学厚度1064
        [~, Column_SOD_1064] = readHDF(filename,variable,start,edges);
    catch
        variable = 'Surface_Top_Altitude_532';    
        [~, Surface_Top_Altitude_532] = readHDF(filename,variable,start,edges);
        variable = 'Surface_Base_Altitude_532';    
        [~, Surface_Base_Altitude_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_Aerosols_532';    % 列对流层气溶胶光学厚度532
        [~, Column_SAOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Tropospheric_Aerosols_532';     % 列平流层气溶胶光学厚度532
        [~, Column_TAOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_Aerosols_1064';   % 列对流层气溶胶光学厚度1064
        [~, Column_SAOD_1064] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Tropospheric_Aerosols_1064';    % 列平流层气溶胶光学厚度1064
        [~, Column_TAOD_1064] = readHDF(filename,variable,start,edges);
    end
    % 列特征分数
    variable = 'Column_Feature_Fraction';
    [~, Column_Feature_Fraction] = readHDF(filename,variable,start,edges);
    % 列集成衰减后向散射系数532
    variable = 'Column_Integrated_Attenuated_Backscatter_532';
    [~, Column_Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 列IAB累积概率
    variable = 'Column_IAB_Cumulative_Probability';
    [~, Column_IAB_Cumulative_Probability] = readHDF(filename,variable,start,edges);
    % 列云层的光学厚度
    variable = 'Column_Optical_Depth_Cloud_532';
    [~, Column_COD] = readHDF(filename,variable,start,edges);
    % 特征查找QC标志（16位整数15个布尔值）
    variable = 'FeatureFinderQC';
    [~, FeatureFinderQC] = readHDF(filename,variable,start,edges);
    % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
    variable = 'Horizontal_Averaging';
    [~, Horizontal_Averaging] = readHDF(filename,variable,start,edges);
    % 层顶高度
    variable = 'Layer_Top_Altitude';
    [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
    % 层底高度
    variable = 'Layer_Base_Altitude';
    [~, Layer_Base_Altitude] = readHDF(filename,variable,start,edges);
    % 层底高度延伸
    variable = 'Layer_Base_Extended';
    [~, Layer_Base_Extended] = readHDF(filename,variable,start,edges);
    % 每列的层次数目
    variable = 'Number_Layers_Found';
    [~, Number_Layers_Found] = readHDF(filename,variable,start,edges);
    % 被移除的边界层云的面积
    variable = 'Single_Shot_Cloud_Cleared_Fraction';
    [~, Single_Shot_Cloud_Cleared_Fraction] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射532
    variable = 'Integrated_Attenuated_Backscatter_532';
    [~, Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计532
    variable = 'Attenuated_Backscatter_Statistics_532';
    [~, Attenuated_Backscatter_Statistics_532] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射1064
    variable = 'Integrated_Attenuated_Backscatter_1064';
    [~, Integrated_Attenuated_Backscatter_1064] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计1064
    variable = 'Attenuated_Backscatter_Statistics_1064';
    [~, Attenuated_Backscatter_Statistics_1064] = readHDF(filename,variable,start,edges);
    % 整层总体体积去极化比
    variable = 'Integrated_Volume_Depolarization_Ratio';
    [~, Integrated_Volume_Depolarization_Ratio] = readHDF(filename,variable,start,edges);
    % 体积去极化比统计
    variable = 'Volume_Depolarization_Ratio_Statistics';
    [~, Volume_Depolarization_Ratio_Statistics] = readHDF(filename,variable,start,edges);
    % 层积分颗粒去极化比
    variable = 'Integrated_Particulate_Depolarization_Ratio';
    [~, Integrated_Particulate_Depolarization_Ratio] = readHDF(filename,variable,start,edges);
    % 层积分颗粒去极化比统计
    variable = 'Particulate_Depolarization_Ratio_Statistics';
    [~, Particulate_Depolarization_Ratio_Statistics] = readHDF(filename,variable,start,edges);        
    % 整层总体衰减总色比
    variable = 'Integrated_Attenuated_Total_Color_Ratio';
    [~, Integrated_Attenuated_Total_Color_Ratio] = readHDF(filename,variable,start,edges);
    % 衰减总色比统计
    variable = 'Attenuated_Total_Color_Ratio_Statistics';
    [~, Attenuated_Total_Color_Ratio_Statistics] = readHDF(filename,variable,start,edges);
    % 测量双向透过率
    variable = 'Measured_Two_Way_Transmittance_532';
    [~, Measured_Two_Way_Transmittance_532] = readHDF(filename,variable,start,edges);
    % 双向透过率测量区域
    variable = 'Two_Way_Transmittance_Measurement_Region';
    [~, Two_Way_Transmittance_Measurement_Region] = readHDF(filename,variable,start,edges);
    % 初始532激光雷达比
    variable = 'Initial_532_Lidar_Ratio';
    [~, Initial_532_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 初始1064激光雷达比
    variable = 'Initial_1064_Lidar_Ratio';
    [~, Initial_1064_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 最终532激光雷达比
    variable = 'Final_532_Lidar_Ratio';
    [~, Final_532_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 最终1064激光雷达比
    variable = 'Final_1064_Lidar_Ratio';
    [~, Final_1064_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 激光雷达比选择方法532
    variable = 'Lidar_Ratio_532_Selection_Method';
    [~, Lidar_Ratio_532_Selection_Method] = readHDF(filename,variable,start,edges);
    % 激光雷达比选择方法1064
    variable = 'Lidar_Ratio_1064_Selection_Method';
    [~, Lidar_Ratio_1064_Selection_Method] = readHDF(filename,variable,start,edges);
    % 不透明标志
    variable = 'Opacity_Flag';
    [~, Opacity_Flag] = readHDF(filename,variable,start,edges);
    % 层次有效多重散射因子532
    variable = 'Layer_Effective_532_Multiple_Scattering_Factor';
    [~, Layer_Effective_532_Multiple_Scattering_Factor] = readHDF(filename,variable,start,edges);
    % 层次有效多重散射因子1064
    variable = 'Layer_Effective_1064_Multiple_Scattering_Factor';
    [~, Layer_Effective_1064_Multiple_Scattering_Factor] = readHDF(filename,variable,start,edges);
    % 层次光学厚度532
    variable = 'Feature_Optical_Depth_532';
    [~, Feature_Optical_Depth_532] = readHDF(filename,variable,start,edges);
    % 层次光学厚度1064
    variable = 'Feature_Optical_Depth_1064';
    [~, Feature_Optical_Depth_1064] = readHDF(filename,variable,start,edges);
    % CAD分数
    variable = 'CAD_Score';
    [~, CAD_Score] = readHDF(filename,variable,start,edges);
    % 消光QC 532
    variable = 'ExtinctionQC_532';
    [~, ExtinctionQC_532] = readHDF(filename,variable,start,edges);
    % 消光QC 1064
    variable = 'ExtinctionQC_1064';
    [~, ExtinctionQC_1064] = readHDF(filename,variable,start,edges);
    % 层次分类标志
    variable = 'Feature_Classification_Flags';
    [~, Feature_Classification_Flags] = readHDF(filename,variable,start,edges);
     % 层顶温度
    variable = 'Layer_Top_Temperature';
    [~, Layer_Top_Temperature] = readHDF(filename,variable,start,edges);
     % 层底温度
    variable = 'Layer_Base_Temperature';
    [~, Layer_Base_Temperature] = readHDF(filename,variable,start,edges);
     % 层中心温度
    variable = 'Midlayer_Temperature';
    [~, Midlayer_Temperature] = readHDF(filename,variable,start,edges);
    % 层顶压强
    variable = 'Layer_Top_Pressure';
    [~, Layer_Top_Pressure] = readHDF(filename,variable,start,edges);
    % 层底压强
    variable = 'Layer_Base_Pressure';
    [~, Layer_Base_Pressure] = readHDF(filename,variable,start,edges);
    % 层中心压强
    variable = 'Midlayer_Pressure';
    [~, Midlayer_Pressure] = readHDF(filename,variable,start,edges);
    % 地表类型
    variable = 'IGBP_Surface_Type';
    [~, IGBP_Surface_Type] = readHDF(filename,variable,start,edges); 
    % 对流层高度
    variable = 'Tropopause_Height';
    [~, Tropopause_Height] = readHDF(filename,variable,start,edges);
    % 单廓线云清除标志
    variable = 'ssWas_Cleared';
    edges_temp=edges;edges_temp(1)=edges_temp(1)*15;
    start_temp=start;start_temp(1)=start_temp(1)*15;
    [~, ssWas_Cleared] = readHDF(filename,variable,start_temp,edges_temp);
    % 单廓线层顶高
    variable = 'ssLayer_Top_Altitude';
    edges_temp=edges;edges_temp(1)=edges_temp(1)*15;
    start_temp=start;start_temp(1)=start_temp(1)*15;
    [~, ssLayer_Top_Altitude] = readHDF(filename,variable,start_temp,edges_temp);
    % 单廓线层底高
    variable = 'ssLayer_Base_Altitude';
    edges_temp=edges;edges_temp(1)=edges_temp(1)*15;
    start_temp=start;start_temp(1)=start_temp(1)*15;
    [~, ssLayer_Base_Altitude] = readHDF(filename,variable,start_temp,edges_temp);
    % 单廓线不透明标志
    variable = 'ssOpacity_Flag';
    edges_temp=edges;edges_temp(1)=edges_temp(1)*15;
    start_temp=start;start_temp(1)=start_temp(1)*15;
    [~, ssOpacity_Flag] = readHDF(filename,variable,start_temp,edges_temp);
    % 整层衰减散射比统计数据
    variable = 'Attenuated_Scattering_Ratio_Statistics_532';
    [~, Attenuated_Scattering_Ratio_Statistics_532] = readHDF(filename,variable,start,edges);
     
    % 3.输出
    output_CALIPSO_L2_data.fileName                                        = filename;
    output_CALIPSO_L2_data.profile_number                                  = indB;
    output_CALIPSO_L2_data.profile_start_end                               = ilat2;
    output_CALIPSO_L2_data.Lon                                             = Lon;
    output_CALIPSO_L2_data.Lat                                             = Lat;
    output_CALIPSO_L2_data.DEM_Surface_Elevation                           = DEM_Surface_Elevation;
    try
        output_CALIPSO_L2_data.Lidar_Surface_Elevation                         = Lidar_Surface_Elevation;
        output_CALIPSO_L2_data.horizontal_resolution_Initial_detection_surface = horizontal_resolution_Initial_detection_surface;
        output_CALIPSO_L2_data.detection_frequency_5km                         = detection_frequency_5km;
        output_CALIPSO_L2_data.Column_AOD_532                                  = Column_AOD_532;
        output_CALIPSO_L2_data.Column_AOD_1064                                 = Column_AOD_1064;
        output_CALIPSO_L2_data.Column_SOD_532                                  = Column_SOD_532;
        output_CALIPSO_L2_data.Column_SOD_1064                                 = Column_SOD_1064;
    catch
        output_CALIPSO_L2_data.Surface_Top_Altitude_532                        = Surface_Top_Altitude_532;
        output_CALIPSO_L2_data.Surface_Base_Altitude_532                       = Surface_Base_Altitude_532;
        output_CALIPSO_L2_data.Column_SAOD_532                                 = Column_SAOD_532;
        output_CALIPSO_L2_data.Column_TAOD_532                                 = Column_TAOD_532;
        output_CALIPSO_L2_data.Column_SAOD_1064                                = Column_SAOD_1064;
        output_CALIPSO_L2_data.Column_TAOD_1064                                = Column_TAOD_1064;
    end
    output_CALIPSO_L2_data.Column_Feature_Fraction                         = Column_Feature_Fraction;
    output_CALIPSO_L2_data.Column_Integrated_Attenuated_Backscatter_532    = Column_Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Column_IAB_Cumulative_Probability               = Column_IAB_Cumulative_Probability;
    output_CALIPSO_L2_data.Column_COD                                      = Column_COD;
    output_CALIPSO_L2_data.FeatureFinderQC                                 = FeatureFinderQC;
    output_CALIPSO_L2_data.Horizontal_Averaging                            = Horizontal_Averaging;
    output_CALIPSO_L2_data.Layer_Top_Altitude                              = Layer_Top_Altitude;
    output_CALIPSO_L2_data.Layer_Base_Altitude                             = Layer_Base_Altitude;
    output_CALIPSO_L2_data.Layer_Base_Extended                             = Layer_Base_Extended;
    output_CALIPSO_L2_data.Number_Layers_Found                             = Number_Layers_Found;
    output_CALIPSO_L2_data.Single_Shot_Cloud_Cleared_Fraction              = Single_Shot_Cloud_Cleared_Fraction;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_532           = Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_532           = Attenuated_Backscatter_Statistics_532;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_1064          = Integrated_Attenuated_Backscatter_1064;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_1064          = Attenuated_Backscatter_Statistics_1064;
    output_CALIPSO_L2_data.Integrated_Volume_Depolarization_Ratio          = Integrated_Volume_Depolarization_Ratio;
    output_CALIPSO_L2_data.Volume_Depolarization_Ratio_Statistics          = Volume_Depolarization_Ratio_Statistics;
    output_CALIPSO_L2_data.Integrated_Particulate_Depolarization_Ratio          = Integrated_Particulate_Depolarization_Ratio;
    output_CALIPSO_L2_data.Particulate_Depolarization_Ratio_Statistics         = Particulate_Depolarization_Ratio_Statistics;
    output_CALIPSO_L2_data.Integrated_Attenuated_Total_Color_Ratio         = Integrated_Attenuated_Total_Color_Ratio;
    output_CALIPSO_L2_data.Attenuated_Total_Color_Ratio_Statistics         = Attenuated_Total_Color_Ratio_Statistics;
    output_CALIPSO_L2_data.Measured_Two_Way_Transmittance_532              = Measured_Two_Way_Transmittance_532;
    output_CALIPSO_L2_data.Two_Way_Transmittance_Measurement_Region        = Two_Way_Transmittance_Measurement_Region;
    output_CALIPSO_L2_data.Initial_532_Lidar_Ratio                         = Initial_532_Lidar_Ratio;
    output_CALIPSO_L2_data.Initial_1064_Lidar_Ratio                        = Initial_1064_Lidar_Ratio;
    output_CALIPSO_L2_data.Final_532_Lidar_Ratio                           = Final_532_Lidar_Ratio;
    output_CALIPSO_L2_data.Final_1064_Lidar_Ratio                          = Final_1064_Lidar_Ratio;
    output_CALIPSO_L2_data.Lidar_Ratio_532_Selection_Method                = Lidar_Ratio_532_Selection_Method;
    output_CALIPSO_L2_data.Lidar_Ratio_1064_Selection_Method               = Lidar_Ratio_1064_Selection_Method;
    output_CALIPSO_L2_data.Opacity_Flag                                    = Opacity_Flag;
    output_CALIPSO_L2_data.Layer_Effective_532_Multiple_Scattering_Factor  = Layer_Effective_532_Multiple_Scattering_Factor;
    output_CALIPSO_L2_data.Layer_Effective_1064_Multiple_Scattering_Factor = Layer_Effective_1064_Multiple_Scattering_Factor;
    output_CALIPSO_L2_data.Feature_Optical_Depth_532                       = Feature_Optical_Depth_532;
    output_CALIPSO_L2_data.Feature_Optical_Depth_1064                      = Feature_Optical_Depth_1064;
    output_CALIPSO_L2_data.CAD_Score                                       = CAD_Score;
    output_CALIPSO_L2_data.ExtinctionQC_532                                = ExtinctionQC_532;
    output_CALIPSO_L2_data.ExtinctionQC_1064                               = ExtinctionQC_1064;
    output_CALIPSO_L2_data.Feature_Classification_Flags                    = Feature_Classification_Flags;
    output_CALIPSO_L2_data.Layer_Top_Temperature                               = Layer_Top_Temperature;
    output_CALIPSO_L2_data.Layer_Base_Temperature                    = Layer_Base_Temperature;   
    output_CALIPSO_L2_data.Midlayer_Temperature                    = Midlayer_Temperature;
    output_CALIPSO_L2_data.Layer_Top_Pressure                    = Layer_Top_Pressure;
    output_CALIPSO_L2_data.Layer_Base_Pressure                   = Layer_Base_Pressure;
    output_CALIPSO_L2_data.Midlayer_Pressure                    = Midlayer_Pressure;
    output_CALIPSO_L2_data.IGBP_Surface_Type                    = IGBP_Surface_Type;
    output_CALIPSO_L2_data.Tropopause_Height                    = Tropopause_Height;
    output_CALIPSO_L2_data.ssWas_Cleared                        = ssWas_Cleared;
    output_CALIPSO_L2_data.ssLayer_Top_Altitude                        = ssLayer_Top_Altitude;
    output_CALIPSO_L2_data.ssLayer_Base_Altitude                        = ssLayer_Base_Altitude;
    output_CALIPSO_L2_data.ssOpacity_Flag                        = ssOpacity_Flag;
    output_CALIPSO_L2_data.Attenuated_Scattering_Ratio_Statistics_532      = Attenuated_Scattering_Ratio_Statistics_532;
    
end

%% 读取05kmCLay数据
if ~isempty(strfind(filename,'05kmCLay') ),
    variable = 'Latitude';
    [~, lat_whole] = readHDF(filename,variable);
    if any(isnan(profile_start_and_length))  % 如果前文没有完全指出实际用到的廓线，则下面开始计算；若已指出则不必计算，直接读取即可。
        % 1.选取起始廓线的位置 方法1：
        lat_the_first_column = lat_whole(:,1);
        lat_the_last_column = lat_whole(:,3);
        % 先看纬度是从大到小呢，还是从小到大
        if lat_the_first_column(1) < lat_the_first_column(end)                 % 从小到大
            start_profile = find(lat_the_last_column > lat_lim(1),1,'first'); % 第一次大
            end_profile = find(lat_the_first_column < lat_lim(2),1,'last');    % 最后一次小
        else
            start_profile = find(lat_the_first_column < lat_lim(2),1,'first'); % 第一次小
            end_profile = find(lat_the_last_column > lat_lim(1),1,'last');  % 最后一次大
        end
        ilat = [start_profile,end_profile];
        indA = ilat(1)-1; % DECREMENT for readHDF!1!  % 起始位置
        indB = (ilat(2)-ilat(1)+1);  % 范围内的条数。
        % 2.调整廓线条数(需Horizontal_Averaging和Layer_Top_Altitude配合使用)
        start = [indA 0];
        edges = [indB -9];
        variable = 'Horizontal_Averaging'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Horizontal_Averaging] = readHDF(filename,variable,start,edges);
        variable = 'Layer_Top_Altitude'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
        top_right_80km = nan(size(Layer_Top_Altitude));        % 官方80km检测出的层次
        for i=1:size(Horizontal_Averaging,1)
            for j=1:size(Horizontal_Averaging,2)
                if Horizontal_Averaging(i,j) ==80
                    top_right_80km(i,j) = Layer_Top_Altitude(i,j);
                end
            end
        end
        residue = mod(size(top_right_80km,1),16);% 表示要去掉residue条廓线。
        % 遍历每行直到找到与目标行（第一行的的一个非nan数）连起一共16行的都具有同样数的起始行。
        bingo = 0;
        for i=1:size(top_right_80km,1)
            target = top_right_80km(i,~isnan(top_right_80km(i,:)));
            if isempty(target)
                continue;
            end
            repetition = 1;
            for int = 1:length(target)
                for j = i+1:size(top_right_80km,1)
                    if find(top_right_80km(j,:)==target(int))
                        repetition = repetition+1;
                    else
                        break;
                    end
                end
            end
            if repetition == 16
                bingo = 1;
                start_ave_row = i;
                break;
            end
        end
        if bingo == 1
            before_cut = mod(start_ave_row-1,16);
            after_cut = residue - before_cut;
        else
            % 手动查看top_right_80km_change字段后，屏幕要求输入两个数（开始廓线改变量，结尾廓线改变量）表示前后要减去的廓线条数。必为正值，正常连续相同的有16条。
            before_cut = input('please input a number:');
            after_cut = input('please input a number:');
        end
        indA = indA - before_cut;
        indB = indB - before_cut - after_cut; % 实际上就是indB - residue；
    else
        indA = profile_start_and_length(1)-1;
        indB = profile_start_and_length(2);
    end
    % 3.开始读取
    % 经纬度
    start = [indA 0];
    edges = [indB 3];
    variable = 'Longitude';
    [~, Lon] = readHDF(filename,variable,start,edges);
    variable = 'Latitude';
    [~, Lat] = readHDF(filename,variable,start,edges);
    lat_start_inwhole = find(round(lat_whole(:,1),4) == round(Lat(1,1),4));
    lat_end_inwhole = find(round(lat_whole(:,1),4) == round(Lat(end,1),4)); % 选中的廓线在总廓线中的终止位置
    ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
    % DEM地表高程
    start = [indA 0];
    edges = [indB -9];
    variable = 'DEM_Surface_Elevation';
    [~, DEM_Surface_Elevation] = readHDF(filename,variable,start,edges);   
    try
        variable = 'Lidar_Surface_Elevation';                % 激光雷达测得的地表高程
        [~, Lidar_Surface_Elevation] = readHDF(filename,variable,start,edges);
        variable = 'Surface_Elevation_Detection_Frequency';  % 地表高程探测频率
        [~, Surface_Elevation_Detection_Frequency] = readHDF(filename,variable,start,edges);
        A=cell(size(Surface_Elevation_Detection_Frequency,1),1); % 预分配空间
        horizontal_resolution_Initial_detection_surface = nan(size(Surface_Elevation_Detection_Frequency));  % 第一次探测到层底时的水平分辨率
        detection_frequency_5km = nan(size(Surface_Elevation_Detection_Frequency));                          % 5km检测到层底的频率。
        for i=1:size(Surface_Elevation_Detection_Frequency,1)
            A{i,1} = dec2bin(Surface_Elevation_Detection_Frequency(i,1),8);  % 转成二进制格式
            horizontal_resolution_Initial_detection_surface(i) = bin2dec(A{i,1}(1:3));
            detection_frequency_5km(i) = bin2dec(A{i,1}(6:8));
        end
        % 列气溶胶层的光学厚度532
        variable = 'Column_Optical_Depth_Aerosols_532';
        [~, Column_AOD_532] = readHDF(filename,variable,start,edges);
        % 列气溶胶层的光学厚度1064
        variable = 'Column_Optical_Depth_Aerosols_1064';
        [~, Column_AOD_1064] = readHDF(filename,variable,start,edges);
        % 列平流层的光学厚度532
        variable = 'Column_Optical_Depth_Stratospheric_532';
        [~, Column_SOD_532] = readHDF(filename,variable,start,edges);
        % 列平流层的光学厚度1064
        variable = 'Column_Optical_Depth_Stratospheric_1064';
        [~, Column_SOD_1064] = readHDF(filename,variable,start,edges);
    catch
        variable = 'Surface_Top_Altitude_532';    
        [~, Surface_Top_Altitude_532] = readHDF(filename,variable,start,edges);
        variable = 'Surface_Base_Altitude_532';    
        [~, Surface_Base_Altitude_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_Aerosols_532';    % 列对流层气溶胶光学厚度532
        [~, Column_SAOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Tropospheric_Aerosols_532';     % 列平流层气溶胶光学厚度532
        [~, Column_TAOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_Aerosols_1064';   % 列对流层气溶胶光学厚度1064
        [~, Column_SAOD_1064] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Tropospheric_Aerosols_1064';    % 列平流层气溶胶光学厚度1064
        [~, Column_TAOD_1064] = readHDF(filename,variable,start,edges);
    end   
    % 列特征分数
    variable = 'Column_Feature_Fraction';
    [~, Column_Feature_Fraction] = readHDF(filename,variable,start,edges);
    % 列集成衰减后向散射系数532
    variable = 'Column_Integrated_Attenuated_Backscatter_532';
    [~, Column_Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 列IAB累积概率
    variable = 'Column_IAB_Cumulative_Probability';
    [~, Column_IAB_Cumulative_Probability] = readHDF(filename,variable,start,edges);
    % 列云层的光学厚度
    variable = 'Column_Optical_Depth_Cloud_532';
    [~, Column_COD] = readHDF(filename,variable,start,edges);
    % 特征查找QC标志（16位整数15个布尔值）
    variable = 'FeatureFinderQC';
    [~, FeatureFinderQC] = readHDF(filename,variable,start,edges);
    % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
    variable = 'Horizontal_Averaging';
    [~, Horizontal_Averaging] = readHDF(filename,variable,start,edges);
    % 层顶高度
    variable = 'Layer_Top_Altitude';
    [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
    % 层底高度
    variable = 'Layer_Base_Altitude';
    [~, Layer_Base_Altitude] = readHDF(filename,variable,start,edges);
    % 层底高度延伸
    variable = 'Layer_Base_Extended';
    [~, Layer_Base_Extended] = readHDF(filename,variable,start,edges);
    % 每列的层次数目
    variable = 'Number_Layers_Found';
    [~, Number_Layers_Found] = readHDF(filename,variable,start,edges);
    % 被移除的边界层云的面积
    variable = 'Single_Shot_Cloud_Cleared_Fraction';
    [~, Single_Shot_Cloud_Cleared_Fraction] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射532
    variable = 'Integrated_Attenuated_Backscatter_532';
    [~, Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计532
    variable = 'Attenuated_Backscatter_Statistics_532';
    [~, Attenuated_Backscatter_Statistics_532] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射1064
    variable = 'Integrated_Attenuated_Backscatter_1064';
    [~, Integrated_Attenuated_Backscatter_1064] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计1064
    variable = 'Attenuated_Backscatter_Statistics_1064';
    [~, Attenuated_Backscatter_Statistics_1064] = readHDF(filename,variable,start,edges);
    % 整层总体体积去极化比
    variable = 'Integrated_Volume_Depolarization_Ratio';
    [~, Integrated_Volume_Depolarization_Ratio] = readHDF(filename,variable,start,edges);
    % 体积去极化比统计
    variable = 'Volume_Depolarization_Ratio_Statistics';
    [~, Volume_Depolarization_Ratio_Statistics] = readHDF(filename,variable,start,edges);
    % 层积分颗粒去极化比
    variable = 'Integrated_Particulate_Depolarization_Ratio';
    [~, Integrated_Particulate_Depolarization_Ratio] = readHDF(filename,variable,start,edges);
    % 层积分颗粒去极化比统计
    variable = 'Particulate_Depolarization_Ratio_Statistics';
    [~, Particulate_Depolarization_Ratio_Statistics] = readHDF(filename,variable,start,edges);        
    % 整层总体衰减总色比
    variable = 'Integrated_Attenuated_Total_Color_Ratio';
    [~, Integrated_Attenuated_Total_Color_Ratio] = readHDF(filename,variable,start,edges);
    % 衰减总色比统计
    variable = 'Attenuated_Total_Color_Ratio_Statistics';
    [~, Attenuated_Total_Color_Ratio_Statistics] = readHDF(filename,variable,start,edges);
    % 测量双向透过率
    variable = 'Measured_Two_Way_Transmittance_532';
    [~, Measured_Two_Way_Transmittance_532] = readHDF(filename,variable,start,edges);
    % 双向透过率测量区域
    variable = 'Two_Way_Transmittance_Measurement_Region';
    [~, Two_Way_Transmittance_Measurement_Region] = readHDF(filename,variable,start,edges);
    % 初始532激光雷达比
    variable = 'Initial_532_Lidar_Ratio';
    [~, Initial_532_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 最终532激光雷达比
    variable = 'Final_532_Lidar_Ratio';
    [~, Final_532_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 激光雷达比选择方法532
    variable = 'Lidar_Ratio_532_Selection_Method';
    [~, Lidar_Ratio_532_Selection_Method] = readHDF(filename,variable,start,edges);
    % 不透明标志
    variable = 'Opacity_Flag';
    [~, Opacity_Flag] = readHDF(filename,variable,start,edges);
    % 层次有效多重散射因子532
    variable = 'Layer_Effective_532_Multiple_Scattering_Factor';
    [~, Layer_Effective_532_Multiple_Scattering_Factor] = readHDF(filename,variable,start,edges);
    % 层次光学厚度532
    variable = 'Feature_Optical_Depth_532';
    [~, Feature_Optical_Depth_532] = readHDF(filename,variable,start,edges);
    % 冰水路径
    variable = 'Ice_Water_Path';
    [~, Ice_Water_Path] = readHDF(filename,variable,start,edges);
    % CAD分数
    variable = 'CAD_Score';
    [~, CAD_Score] = readHDF(filename,variable,start,edges);
    % 消光QC 532
    variable = 'ExtinctionQC_532';
    [~, ExtinctionQC_532] = readHDF(filename,variable,start,edges);
    % 层次分类标志
    variable = 'Feature_Classification_Flags';
    [~, Feature_Classification_Flags] = readHDF(filename,variable,start,edges);
     % 层顶温度
    variable = 'Layer_Top_Temperature';
    [~, Layer_Top_Temperature] = readHDF(filename,variable,start,edges);
     % 层底温度
    variable = 'Layer_Base_Temperature';
    [~, Layer_Base_Temperature] = readHDF(filename,variable,start,edges);
     % 层中心温度
    variable = 'Midlayer_Temperature';
    [~, Midlayer_Temperature] = readHDF(filename,variable,start,edges);
    % 层顶压强
    variable = 'Layer_Top_Pressure';
    [~, Layer_Top_Pressure] = readHDF(filename,variable,start,edges);
    % 层底压强
    variable = 'Layer_Base_Pressure';
    [~, Layer_Base_Pressure] = readHDF(filename,variable,start,edges);
    % 层中心压强
    variable = 'Midlayer_Pressure';
    [~, Midlayer_Pressure] = readHDF(filename,variable,start,edges);
    % 地表类型
    variable = 'IGBP_Surface_Type';
    [~, IGBP_Surface_Type] = readHDF(filename,variable,start,edges);    
    % 对流层高度
    variable = 'Tropopause_Height';
    [~, Tropopause_Height] = readHDF(filename,variable,start,edges); 
    % 单廓线云清除标志
    variable = 'ssWas_Cleared';
    edges_temp=edges;edges_temp(1)=edges_temp(1)*15;
    start_temp=start;start_temp(1)=start_temp(1)*15;
    [~, ssWas_Cleared] = readHDF(filename,variable,start_temp,edges_temp);
    % 单廓线层顶高
    variable = 'ssLayer_Top_Altitude';
    edges_temp=edges;edges_temp(1)=edges_temp(1)*15;
    start_temp=start;start_temp(1)=start_temp(1)*15;
    [~, ssLayer_Top_Altitude] = readHDF(filename,variable,start_temp,edges_temp);
    % 单廓线层底高
    variable = 'ssLayer_Base_Altitude';
    edges_temp=edges;edges_temp(1)=edges_temp(1)*15;
    start_temp=start;start_temp(1)=start_temp(1)*15;
    [~, ssLayer_Base_Altitude] = readHDF(filename,variable,start_temp,edges_temp);
    % 单廓线不透明标志
    variable = 'ssOpacity_Flag';
    edges_temp=edges;edges_temp(1)=edges_temp(1)*15;
    start_temp=start;start_temp(1)=start_temp(1)*15;
    [~, ssOpacity_Flag] = readHDF(filename,variable,start_temp,edges_temp);
    % 整层衰减散射比统计数据
    variable = 'Attenuated_Scattering_Ratio_Statistics_532';
    [~, Attenuated_Scattering_Ratio_Statistics_532] = readHDF(filename,variable,start,edges);
     
    % 3.输出
    output_CALIPSO_L2_data.fileName                                        = filename;
    output_CALIPSO_L2_data.profile_number                                  = indB;
    output_CALIPSO_L2_data.profile_start_end                               = ilat2;
    output_CALIPSO_L2_data.Lon                                             = Lon;
    output_CALIPSO_L2_data.Lat                                             = Lat;
    output_CALIPSO_L2_data.DEM_Surface_Elevation                           = DEM_Surface_Elevation;
    try
        output_CALIPSO_L2_data.Lidar_Surface_Elevation                         = Lidar_Surface_Elevation;
        output_CALIPSO_L2_data.horizontal_resolution_Initial_detection_surface = horizontal_resolution_Initial_detection_surface;
        output_CALIPSO_L2_data.detection_frequency_5km                         = detection_frequency_5km;
        output_CALIPSO_L2_data.Column_AOD_532                                  = Column_AOD_532;
        output_CALIPSO_L2_data.Column_AOD_1064                                 = Column_AOD_1064;
        output_CALIPSO_L2_data.Column_SOD_532                                  = Column_SOD_532;
        output_CALIPSO_L2_data.Column_SOD_1064                                 = Column_SOD_1064;
    catch
        output_CALIPSO_L2_data.Surface_Top_Altitude_532                        = Surface_Top_Altitude_532;
        output_CALIPSO_L2_data.Surface_Base_Altitude_532                       = Surface_Base_Altitude_532;
        output_CALIPSO_L2_data.Column_SAOD_532                                 = Column_SAOD_532;
        output_CALIPSO_L2_data.Column_TAOD_532                                 = Column_TAOD_532;
        output_CALIPSO_L2_data.Column_SAOD_1064                                = Column_SAOD_1064;
        output_CALIPSO_L2_data.Column_TAOD_1064                                = Column_TAOD_1064;
    end  
    output_CALIPSO_L2_data.Column_Feature_Fraction                         = Column_Feature_Fraction;
    output_CALIPSO_L2_data.Column_Integrated_Attenuated_Backscatter_532    = Column_Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Column_IAB_Cumulative_Probability               = Column_IAB_Cumulative_Probability;
    output_CALIPSO_L2_data.Column_COD                                      = Column_COD;
    
    output_CALIPSO_L2_data.FeatureFinderQC                                 = FeatureFinderQC;
    output_CALIPSO_L2_data.Horizontal_Averaging                            = Horizontal_Averaging;
    output_CALIPSO_L2_data.Layer_Top_Altitude                              = Layer_Top_Altitude;
    output_CALIPSO_L2_data.Layer_Base_Altitude                             = Layer_Base_Altitude;
    output_CALIPSO_L2_data.Layer_Base_Extended                             = Layer_Base_Extended;
    output_CALIPSO_L2_data.Number_Layers_Found                             = Number_Layers_Found;
    output_CALIPSO_L2_data.Single_Shot_Cloud_Cleared_Fraction              = Single_Shot_Cloud_Cleared_Fraction;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_532           = Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_532           = Attenuated_Backscatter_Statistics_532;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_1064          = Integrated_Attenuated_Backscatter_1064;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_1064          = Attenuated_Backscatter_Statistics_1064;
    output_CALIPSO_L2_data.Integrated_Volume_Depolarization_Ratio          = Integrated_Volume_Depolarization_Ratio;
    output_CALIPSO_L2_data.Volume_Depolarization_Ratio_Statistics          = Volume_Depolarization_Ratio_Statistics;
    output_CALIPSO_L2_data.Integrated_Particulate_Depolarization_Ratio          = Integrated_Particulate_Depolarization_Ratio;
    output_CALIPSO_L2_data.Particulate_Depolarization_Ratio_Statistics         = Particulate_Depolarization_Ratio_Statistics;    
    output_CALIPSO_L2_data.Integrated_Attenuated_Total_Color_Ratio         = Integrated_Attenuated_Total_Color_Ratio;
    output_CALIPSO_L2_data.Attenuated_Total_Color_Ratio_Statistics         = Attenuated_Total_Color_Ratio_Statistics;
    output_CALIPSO_L2_data.Measured_Two_Way_Transmittance_532              = Measured_Two_Way_Transmittance_532;
    output_CALIPSO_L2_data.Two_Way_Transmittance_Measurement_Region        = Two_Way_Transmittance_Measurement_Region;
    output_CALIPSO_L2_data.Initial_532_Lidar_Ratio                         = Initial_532_Lidar_Ratio;
    output_CALIPSO_L2_data.Final_532_Lidar_Ratio                           = Final_532_Lidar_Ratio;
    output_CALIPSO_L2_data.Lidar_Ratio_532_Selection_Method                = Lidar_Ratio_532_Selection_Method;
    output_CALIPSO_L2_data.Opacity_Flag                                    = Opacity_Flag;
    output_CALIPSO_L2_data.Layer_Effective_532_Multiple_Scattering_Factor  = Layer_Effective_532_Multiple_Scattering_Factor;
    output_CALIPSO_L2_data.Feature_Optical_Depth_532                       = Feature_Optical_Depth_532;
    output_CALIPSO_L2_data.Ice_Water_Path                                  = Ice_Water_Path;
    output_CALIPSO_L2_data.CAD_Score                                       = CAD_Score;
    output_CALIPSO_L2_data.ExtinctionQC_532                                = ExtinctionQC_532;
    output_CALIPSO_L2_data.Feature_Classification_Flags                    = Feature_Classification_Flags;
    output_CALIPSO_L2_data.Layer_Top_Temperature                               = Layer_Top_Temperature;
    output_CALIPSO_L2_data.Layer_Base_Temperature                    = Layer_Base_Temperature;   
    output_CALIPSO_L2_data.Midlayer_Temperature                    = Midlayer_Temperature;
    output_CALIPSO_L2_data.Layer_Top_Pressure                    = Layer_Top_Pressure;
    output_CALIPSO_L2_data.Layer_Base_Pressure                   = Layer_Base_Pressure;
    output_CALIPSO_L2_data.Midlayer_Pressure                    = Midlayer_Pressure;
    output_CALIPSO_L2_data.IGBP_Surface_Type                    = IGBP_Surface_Type;
    output_CALIPSO_L2_data.Tropopause_Height                    = Tropopause_Height;
    output_CALIPSO_L2_data.ssWas_Cleared                        = ssWas_Cleared;
    output_CALIPSO_L2_data.ssLayer_Top_Altitude                        = ssLayer_Top_Altitude;
    output_CALIPSO_L2_data.ssLayer_Base_Altitude                        = ssLayer_Base_Altitude;
    output_CALIPSO_L2_data.ssOpacity_Flag                        = ssOpacity_Flag;
    output_CALIPSO_L2_data.Attenuated_Scattering_Ratio_Statistics_532      = Attenuated_Scattering_Ratio_Statistics_532;
    

end
%% 先读取MLAY的产品，从中选出80km水平分辨率区域的起始终止廓线的经纬度坐标
if ~isempty(strfind(filename,'05kmMLay') )
    variable = 'Latitude';
    [~, lat_whole] = readHDF(filename,variable);
    if any(isnan(profile_start_and_length)) , % 如果前文没有完全指出实际用到的廓线，则下面开始计算；若已指出则不必计算，直接读取即可。
        % 1.选取起始廓线的位置 方法1：
        lat_the_first_column = lat_whole(:,1);
        lat_the_last_column = lat_whole(:,3);
        % 先看纬度是从大到小呢，还是从小到大
        if lat_the_first_column(1) < lat_the_first_column(end)                 % 从小到大
            start_profile = find(lat_the_last_column > lat_lim(1),1,'first'); % 第一次大
            end_profile = find(lat_the_first_column < lat_lim(2),1,'last');    % 最后一次小
        else
            start_profile = find(lat_the_first_column < lat_lim(2),1,'first'); % 第一次小
            end_profile = find(lat_the_last_column > lat_lim(1),1,'last');  % 最后一次大
        end
        ilat = [start_profile,end_profile];
        indA = ilat(1)-1; % DECREMENT for readHDF!1!  % 起始位置
        indB = (ilat(2)-ilat(1)+1);  % 范围内的条数。
        % 2.调整廓线条数(需Horizontal_Averaging和Layer_Top_Altitude配合使用)
        start = [indA 0];
        edges = [indB -9];
        variable = 'Horizontal_Averaging'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Horizontal_Averaging] = readHDF(filename,variable,start,edges);
        variable = 'Layer_Top_Altitude'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
        top_right_80km = nan(size(Layer_Top_Altitude));        % 官方80km检测出的层次
        for i=1:size(Horizontal_Averaging,1)
            for j=1:size(Horizontal_Averaging,2)
                if Horizontal_Averaging(i,j) ==80
                    top_right_80km(i,j) = Layer_Top_Altitude(i,j);
                end
            end
        end
        residue = mod(size(top_right_80km,1),16);% 表示要去掉residue条廓线。
        % 遍历每行直到找到与目标行（第一行的的一个非nan数）连起一共16行的都具有同样数的起始行。
        bingo = 0;
        for i=1:size(top_right_80km,1)
            target = top_right_80km(i,~isnan(top_right_80km(i,:)));
            if isempty(target)
                continue;
            end
            repetition = 1;
            for int = 1:length(target)
                for j = i+1:size(top_right_80km,1)
                    if find(top_right_80km(j,:)==target(int))
                        repetition = repetition+1;
                    else
                        break;
                    end
                end
            end
            if repetition == 16
                bingo = 1;
                start_ave_row = i;
                break;
            end
        end
        if bingo == 1
            before_cut = mod(start_ave_row-1,16);
            after_cut = residue - before_cut;
        else
            % 手动查看top_right_80km_change字段后，屏幕要求输入两个数（开始廓线改变量，结尾廓线改变量）表示前后要减去的廓线条数。必为正值，正常连续相同的有16条。
            before_cut = input('please input a number:');
            after_cut = input('please input a number:');
        end
        indA = indA - before_cut;
        indB = indB - before_cut - after_cut; % 实际上就是indB - residue；
    else
        indA = profile_start_and_length(1)-1;
        indB = profile_start_and_length(2);
    end
    % 3.开始读取：经纬度
    start = [indA 0];
    edges = [indB 3];
    variable = 'Longitude';
    [~, Lon] = readHDF(filename,variable,start,edges);
    variable = 'Latitude';
    [~, Lat] = readHDF(filename,variable,start,edges);
    lat_start_inwhole = find(round(lat_whole(:,1),4) == round(Lat(1,1),4));
    lat_end_inwhole = find(round(lat_whole(:,1),4) == round(Lat(end,1),4)); % 选中的廓线在总廓线中的终止位置
    ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
    % DEM地表高程
    start = [indA 0];
    edges = [indB -9];
    variable = 'DEM_Surface_Elevation';   
    [~, DEM_Surface_Elevation] = readHDF(filename,variable,start,edges);
    % 532波段探测到的地面回波的起始高度（地表回波层顶）
    variable = 'Surface_Top_Altitude_532';
    [~, Surface_Top_Altitude_532] = readHDF(filename,variable,start,edges);
    % 532波段探测到的地面回波的终止高度（地表回波层底）
    variable = 'Surface_Base_Altitude_532';
    [~, Surface_Base_Altitude_532] = readHDF(filename,variable,start,edges);
    % 地表回波标志532
    variable = 'Surface_Detection_Flags_532';
    [~, Surface_Detection_Flags_532] = readHDF(filename,variable,start,edges);
    A=cell(size(Surface_Detection_Flags_532,1),1); % 预分配空间
    Surface_detection_method = nan(size(Surface_Detection_Flags_532));  % 地表检测方法(0代表派生引出测试，1代表多廓线平均测试，2表示单射地表分数测试，3表示未使用)
    for i=1:size(Surface_Detection_Flags_532,1)
        A{i,1} = dec2bin(Surface_Detection_Flags_532(i,1),16);  % 转成二进制格式
        Surface_detection_method(i) = bin2dec(A{i,1}(2:3));
    end
    % 1km分辨率探测到的地表回波532 （表示在每5km范围内中，有几条1km分辨率的廓线检测到了地表回波，在532nm通道中）
    variable = 'Surface_Detections_1km_532';
    [~, Surface_Detections_1km_532] = readHDF(filename,variable,start,edges);
    % 333m分辨率探测到的地表回波532（表示在每5km范围内中，有几条333m分辨率的廓线检测到了地表回波，在532nm通道中）
    variable = 'Surface_Detections_333m_532';
    [~, Surface_Detections_333m_532] = readHDF(filename,variable,start,edges);
    % 地表整层衰减后向散射比532
    variable = 'Surface_Integrated_Attenuated_Backscatter_532';
    [~, Surface_Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 通过边界层云清除算法从5 km分辨率列清除的单次分辨率下检测到的层数
    variable = 'High_Resolution_Layers_Cleared';
    [~, High_Resolution_Layers_Cleared] = readHDF(filename,variable,start,edges);
    % 单廓线云清除标志
     variable = 'ssWas_Cleared';
    [~, ssWas_Cleared] = readHDF(filename,variable,start,edges);   
    % 列特征分数
    variable = 'Column_Feature_Fraction';
    [~, Column_Feature_Fraction] = readHDF(filename,variable,start,edges);
    % 列集成衰减后向散射系数532
    variable = 'Column_Integrated_Attenuated_Backscatter_532';
    [~, Column_Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 列IAB累积概率
    variable = 'Column_IAB_Cumulative_Probability';
    [~, Column_IAB_Cumulative_Probability] = readHDF(filename,variable,start,edges);
    % 列云层的光学厚度
    variable = 'Column_Optical_Depth_Cloud_532';
    [~, Column_COD] = readHDF(filename,variable,start,edges);
    % 特征查找QC标志（16位整数15个布尔值）
    variable = 'FeatureFinderQC';
    [~, FeatureFinderQC] = readHDF(filename,variable,start,edges);
    % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
    variable = 'Horizontal_Averaging';
    [~, Horizontal_Averaging] = readHDF(filename,variable,start,edges);
    % 层顶高度
    variable = 'Layer_Top_Altitude';
    [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
    % 层底高度
    variable = 'Layer_Base_Altitude';
    [~, Layer_Base_Altitude] = readHDF(filename,variable,start,edges);
    % 层底高度延伸
    variable = 'Layer_Base_Extended';
    [~, Layer_Base_Extended] = readHDF(filename,variable,start,edges);
    % 每列的层次数目
    variable = 'Number_Layers_Found';
    [~, Number_Layers_Found] = readHDF(filename,variable,start,edges);
    % 被移除的边界层云的面积 （云清除过程移除的标称层区域的分数,即水平平均距离乘以层高度）
    variable = 'Single_Shot_Cloud_Cleared_Fraction';
    [~, Single_Shot_Cloud_Cleared_Fraction] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射532
    variable = 'Integrated_Attenuated_Backscatter_532';
    [~, Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计532
    variable = 'Attenuated_Backscatter_Statistics_532';
    [~, Attenuated_Backscatter_Statistics_532] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射1064
    variable = 'Integrated_Attenuated_Backscatter_1064';
    [~, Integrated_Attenuated_Backscatter_1064] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计1064
    variable = 'Attenuated_Backscatter_Statistics_1064';
    [~, Attenuated_Backscatter_Statistics_1064] = readHDF(filename,variable,start,edges);
    % 整层总体体积去极化比
    variable = 'Integrated_Volume_Depolarization_Ratio';
    [~, Integrated_Volume_Depolarization_Ratio] = readHDF(filename,variable,start,edges);
    % 体积去极化比统计
    variable = 'Volume_Depolarization_Ratio_Statistics';
    [~, Volume_Depolarization_Ratio_Statistics] = readHDF(filename,variable,start,edges);
    % 层积分颗粒去极化比
    variable = 'Integrated_Particulate_Depolarization_Ratio';
    [~, Integrated_Particulate_Depolarization_Ratio] = readHDF(filename,variable,start,edges);
    % 层积分颗粒去极化比统计
    variable = 'Particulate_Depolarization_Ratio_Statistics';
    [~, Particulate_Depolarization_Ratio_Statistics] = readHDF(filename,variable,start,edges);     
    % 整层总体衰减总色比
    variable = 'Integrated_Attenuated_Total_Color_Ratio';
    [~, Integrated_Attenuated_Total_Color_Ratio] = readHDF(filename,variable,start,edges);
    % 衰减总色比统计
    variable = 'Attenuated_Total_Color_Ratio_Statistics';
    [~, Attenuated_Total_Color_Ratio_Statistics] = readHDF(filename,variable,start,edges);
    % 测量双向透过率
    variable = 'Measured_Two_Way_Transmittance_532';
    [~, Measured_Two_Way_Transmittance_532] = readHDF(filename,variable,start,edges);
    % 双向透过率测量区域
    variable = 'Two_Way_Transmittance_Measurement_Region';
    [~, Two_Way_Transmittance_Measurement_Region] = readHDF(filename,variable,start,edges);
    % 初始532激光雷达比
    variable = 'Initial_532_Lidar_Ratio';
    [~, Initial_532_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 初始1064激光雷达比
    variable = 'Initial_1064_Lidar_Ratio';
    [~, Initial_1064_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 最终532激光雷达比
    variable = 'Final_532_Lidar_Ratio';
    [~, Final_532_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 最终1064激光雷达比
    variable = 'Final_1064_Lidar_Ratio';
    [~, Final_1064_Lidar_Ratio] = readHDF(filename,variable,start,edges);
    % 激光雷达比选择方法532
    variable = 'Lidar_Ratio_532_Selection_Method';
    [~, Lidar_Ratio_532_Selection_Method] = readHDF(filename,variable,start,edges);
    % 激光雷达比选择方法1064
    variable = 'Lidar_Ratio_1064_Selection_Method';
    [~, Lidar_Ratio_1064_Selection_Method] = readHDF(filename,variable,start,edges);
    % 不透明标志
    variable = 'Opacity_Flag';
    [~, Opacity_Flag] = readHDF(filename,variable,start,edges);
    % 层次有效多重散射因子532
    variable = 'Layer_Effective_532_Multiple_Scattering_Factor';
    [~, Layer_Effective_532_Multiple_Scattering_Factor] = readHDF(filename,variable,start,edges);
    % 层次有效多重散射因子1064
    variable = 'Layer_Effective_1064_Multiple_Scattering_Factor';
    [~, Layer_Effective_1064_Multiple_Scattering_Factor] = readHDF(filename,variable,start,edges);
    % 层次光学厚度532
    variable = 'Feature_Optical_Depth_532';
    [~, Feature_Optical_Depth_532] = readHDF(filename,variable,start,edges);
    % 层次光学厚度1064
    variable = 'Feature_Optical_Depth_1064';
    [~, Feature_Optical_Depth_1064] = readHDF(filename,variable,start,edges);
    % CAD分数
    variable = 'CAD_Score';
    [~, CAD_Score] = readHDF(filename,variable,start,edges);
    % 消光QC 532
    variable = 'ExtinctionQC_532';
    [~, ExtinctionQC_532] = readHDF(filename,variable,start,edges);
    % 消光QC 1064
    variable = 'ExtinctionQC_1064';
    [~, ExtinctionQC_1064] = readHDF(filename,variable,start,edges);
    % 层次分类标志
    variable = 'Feature_Classification_Flags';
    [~, Feature_Classification_Flags] = readHDF(filename,variable,start,edges);
     % 层顶温度
    variable = 'Layer_Top_Temperature';
    [~, Layer_Top_Temperature] = readHDF(filename,variable,start,edges);
     % 层底温度
    variable = 'Layer_Base_Temperature';
    [~, Layer_Base_Temperature] = readHDF(filename,variable,start,edges);
     % 层中心温度
    variable = 'Midlayer_Temperature';
    [~, Midlayer_Temperature] = readHDF(filename,variable,start,edges);
    % 层顶压强
    variable = 'Layer_Top_Pressure';
    [~, Layer_Top_Pressure] = readHDF(filename,variable,start,edges);
    % 层底压强
    variable = 'Layer_Base_Pressure';
    [~, Layer_Base_Pressure] = readHDF(filename,variable,start,edges);
    % 层中心压强
    variable = 'Midlayer_Pressure';
    [~, Midlayer_Pressure] = readHDF(filename,variable,start,edges);  
    % 地表类型
    variable = 'IGBP_Surface_Type';
    [~, IGBP_Surface_Type] = readHDF(filename,variable,start,edges);   
     % 对流层高度
    variable = 'Tropopause_Height';
    [~, Tropopause_Height] = readHDF(filename,variable,start,edges); 
   % 4.输出
    output_CALIPSO_L2_data.fileName                                        = filename;
    output_CALIPSO_L2_data.profile_number                                  = indB;
    output_CALIPSO_L2_data.profile_start_end                               = ilat2;
    output_CALIPSO_L2_data.Lon                                             = Lon;
    output_CALIPSO_L2_data.Lat                                             = Lat;
    output_CALIPSO_L2_data.DEM_Surface_Elevation                           = DEM_Surface_Elevation;
    output_CALIPSO_L2_data.Surface_Top_Altitude_532                        = Surface_Top_Altitude_532;
    output_CALIPSO_L2_data.Surface_Base_Altitude_532                       = Surface_Base_Altitude_532;
    output_CALIPSO_L2_data.Surface_Detection_Flags_532                     = Surface_Detection_Flags_532;
    output_CALIPSO_L2_data.Surface_detection_method                        = Surface_detection_method;
    output_CALIPSO_L2_data.Surface_Detections_1km_532                      = Surface_Detections_1km_532;
    output_CALIPSO_L2_data.Surface_Detections_333m_532                     = Surface_Detections_333m_532;
    output_CALIPSO_L2_data.Surface_Integrated_Attenuated_Backscatter_532   = Surface_Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.High_Resolution_Layers_Cleared                  = High_Resolution_Layers_Cleared;
    output_CALIPSO_L2_data.ssWas_Cleared                                   = ssWas_Cleared;  
    output_CALIPSO_L2_data.Column_Feature_Fraction                         = Column_Feature_Fraction;
    output_CALIPSO_L2_data.Column_Integrated_Attenuated_Backscatter_532    = Column_Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Column_IAB_Cumulative_Probability               = Column_IAB_Cumulative_Probability;
    output_CALIPSO_L2_data.Column_COD                                      = Column_COD;
    output_CALIPSO_L2_data.FeatureFinderQC                                 = FeatureFinderQC;
    output_CALIPSO_L2_data.Horizontal_Averaging                            = Horizontal_Averaging;
    output_CALIPSO_L2_data.Layer_Top_Altitude                              = Layer_Top_Altitude;
    output_CALIPSO_L2_data.Layer_Base_Altitude                             = Layer_Base_Altitude;
    output_CALIPSO_L2_data.Layer_Base_Extended                             = Layer_Base_Extended;
    output_CALIPSO_L2_data.Number_Layers_Found                             = Number_Layers_Found;
    output_CALIPSO_L2_data.Single_Shot_Cloud_Cleared_Fraction              = Single_Shot_Cloud_Cleared_Fraction;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_532           = Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_532           = Attenuated_Backscatter_Statistics_532;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_1064          = Integrated_Attenuated_Backscatter_1064;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_1064          = Attenuated_Backscatter_Statistics_1064;
    output_CALIPSO_L2_data.Integrated_Volume_Depolarization_Ratio          = Integrated_Volume_Depolarization_Ratio;
    output_CALIPSO_L2_data.Volume_Depolarization_Ratio_Statistics          = Volume_Depolarization_Ratio_Statistics;
    output_CALIPSO_L2_data.Integrated_Particulate_Depolarization_Ratio          = Integrated_Particulate_Depolarization_Ratio;
    output_CALIPSO_L2_data.Particulate_Depolarization_Ratio_Statistics         = Particulate_Depolarization_Ratio_Statistics;    
    output_CALIPSO_L2_data.Integrated_Attenuated_Total_Color_Ratio         = Integrated_Attenuated_Total_Color_Ratio;
    output_CALIPSO_L2_data.Attenuated_Total_Color_Ratio_Statistics         = Attenuated_Total_Color_Ratio_Statistics;
    output_CALIPSO_L2_data.Measured_Two_Way_Transmittance_532              = Measured_Two_Way_Transmittance_532;
    output_CALIPSO_L2_data.Two_Way_Transmittance_Measurement_Region        = Two_Way_Transmittance_Measurement_Region;
    output_CALIPSO_L2_data.Initial_532_Lidar_Ratio                         = Initial_532_Lidar_Ratio;
    output_CALIPSO_L2_data.Initial_1064_Lidar_Ratio                        = Initial_1064_Lidar_Ratio;
    output_CALIPSO_L2_data.Final_532_Lidar_Ratio                           = Final_532_Lidar_Ratio;
    output_CALIPSO_L2_data.Final_1064_Lidar_Ratio                          = Final_1064_Lidar_Ratio;
    output_CALIPSO_L2_data.Lidar_Ratio_532_Selection_Method                = Lidar_Ratio_532_Selection_Method;
    output_CALIPSO_L2_data.Lidar_Ratio_1064_Selection_Method               = Lidar_Ratio_1064_Selection_Method;
    output_CALIPSO_L2_data.Opacity_Flag                                    = Opacity_Flag;
    output_CALIPSO_L2_data.Layer_Effective_532_Multiple_Scattering_Factor  = Layer_Effective_532_Multiple_Scattering_Factor;
    output_CALIPSO_L2_data.Layer_Effective_1064_Multiple_Scattering_Factor = Layer_Effective_1064_Multiple_Scattering_Factor;
    output_CALIPSO_L2_data.Feature_Optical_Depth_532                       = Feature_Optical_Depth_532;
    output_CALIPSO_L2_data.Feature_Optical_Depth_1064                      = Feature_Optical_Depth_1064;
    output_CALIPSO_L2_data.CAD_Score                                       = CAD_Score;
    output_CALIPSO_L2_data.ExtinctionQC_532                                = ExtinctionQC_532;
    output_CALIPSO_L2_data.ExtinctionQC_1064                               = ExtinctionQC_1064;
    output_CALIPSO_L2_data.Feature_Classification_Flags                    = Feature_Classification_Flags;
    output_CALIPSO_L2_data.Layer_Top_Temperature                               = Layer_Top_Temperature;
    output_CALIPSO_L2_data.Layer_Base_Temperature                    = Layer_Base_Temperature;   
    output_CALIPSO_L2_data.Midlayer_Temperature                    = Midlayer_Temperature;   
    output_CALIPSO_L2_data.Layer_Top_Pressure                    = Layer_Top_Pressure;   
    output_CALIPSO_L2_data.Layer_Base_Pressure                   = Layer_Base_Pressure;   
    output_CALIPSO_L2_data.Midlayer_Pressure                    = Midlayer_Pressure; 
    output_CALIPSO_L2_data.IGBP_Surface_Type                    = IGBP_Surface_Type; 
    output_CALIPSO_L2_data.Tropopause_Height=Tropopause_Height;
end

%% 读取05kmAPro文件
if ~isempty(strfind(filename,'05kmAPro') )
    variable = 'Latitude';
    [~, lat_whole] = readHDF(filename,variable);
    if any(isnan(profile_start_and_length))  % 如果前文没有完全指出实际用到的廓线，则下面开始计算；若已指出则不必计算，直接读取即可。
        % 1.选取起始廓线的位置 方法1：
        lat_the_first_column = lat_whole(:,1);
        lat_the_last_column = lat_whole(:,3);
        % 先看纬度是从大到小呢，还是从小到大
        if lat_the_first_column(1) < lat_the_first_column(end)                 % 从小到大
            start_profile = find(lat_the_last_column > lat_lim(1),1,'first'); % 第一次大
            end_profile = find(lat_the_first_column < lat_lim(2),1,'last');    % 最后一次小
        else
            start_profile = find(lat_the_first_column < lat_lim(2),1,'first'); % 第一次小
            end_profile = find(lat_the_last_column > lat_lim(1),1,'last');  % 最后一次大
        end
        ilat = [start_profile,end_profile];
        indA = ilat(1)-1; % DECREMENT for readHDF!1!  % 起始位置
        indB = (ilat(2)-ilat(1)+1);  % 范围内的条数-1。不知为何总是该数总是比需要提取的总廓线条数少1，才可以。
        % 2.调整廓线条数(需Horizontal_Averaging和Layer_Top_Altitude配合使用)
        start = [indA 0];
        edges = [indB -9];
        variable = 'Horizontal_Averaging'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Horizontal_Averaging] = readHDF(filename,variable,start,edges);
        variable = 'Layer_Top_Altitude'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
        top_right_80km = nan(size(Layer_Top_Altitude));        % 官方80km检测出的层次
        for i=1:size(Horizontal_Averaging,1)
            for j=1:size(Horizontal_Averaging,2)
                if Horizontal_Averaging(i,j) ==80
                    top_right_80km(i,j) = Layer_Top_Altitude(i,j);
                end
            end
        end
        residue = mod(size(top_right_80km,1),16);% 表示要去掉residue条廓线。
        % 遍历每行直到找到与目标行（第一行的的一个非nan数）连起一共16行的都具有同样数的起始行。
        bingo = 0;
        for i=1:size(top_right_80km,1)
            target = top_right_80km(i,~isnan(top_right_80km(i,:)));
            if isempty(target)
                continue;
            end
            repetition = 1;
            for int = 1:length(target)
                for j = i+1:size(top_right_80km,1)
                    if find(top_right_80km(j,:)==target(int))
                        repetition = repetition+1;
                    else
                        break;
                    end
                end
            end
            if repetition == 16
                bingo = 1;
                start_ave_row = i;
                break;
            end
        end
        if bingo == 1
            before_cut = mod(start_ave_row-1,16);
            after_cut = residue - before_cut;
        else
            % 手动查看top_right_80km_change字段后，屏幕要求输入两个数（开始廓线改变量，结尾廓线改变量）表示前后要减去的廓线条数。必为正值，正常连续相同的有16条。
            before_cut = input('please input a number:');
            after_cut = input('please input a number:');
        end
        indA = indA - before_cut;
        indB = indB - before_cut - after_cut; % 实际上就是indB - residue；
    else
        indA = profile_start_and_length(1)-1;
        indB = profile_start_and_length(2);
    end
    % 3.开始读取
    % 经纬度
    start = [indA 0];
    edges = [indB 3];
    variable = 'Longitude';
    [~, Lon] = readHDF(filename,variable,start,edges);
    variable = 'Latitude';
    [~, Lat] = readHDF(filename,variable,start,edges);
    lat_start_inwhole = find(round(lat_whole(:,1),4) == round(Lat(1,1),4));
    lat_end_inwhole = find(round(lat_whole(:,1),4) == round(Lat(end,1),4)); % 选中的廓线在总廓线中的终止位置
    ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
    % 激光雷达数据高度（583）
    Altitudes_Profile = hdfread(filename,'/metadata', 'Fields',...
        'Lidar_Data_Altitudes');
    Altitudes_Profile = Altitudes_Profile{1,1}; % 为什么会有{1,1}？因为原来的激光雷达数据高度储存方式是元胞数组型，这里提取出矩阵型。
    % CAD分数
    start = [indA 0 0];
    edges = [indB -9 -9];
    variable = 'CAD_Score';
    [~, CAD_Score] = readHDF(filename,variable,start,edges);
    % 大气体积描述
    variable = 'Atmospheric_Volume_Description';
    [~, Atmospheric_Volume_Description] = readHDF(filename,variable,start,edges);
    % 消光QC标志532
    variable = 'Extinction_QC_Flag_532';
    [~, Extinction_QC_Flag_532] = readHDF(filename,variable,start,edges);
    % 消光QC标志1064
    variable = 'Extinction_QC_Flag_1064';
    [~, Extinction_QC_Flag_1064] = readHDF(filename,variable,start,edges);
    % 列云的光学厚度532
    start = [indA 0];
    edges = [indB -9];
    variable = 'Column_Optical_Depth_Cloud_532';
    [~, Column_COD_532] = readHDF(filename,variable,start,edges);
    try
        variable = 'Column_Optical_Depth_Aerosols_532';       % 列气溶胶的光学厚度532
        [~, Column_AOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Aerosols_1064';      % 列气溶胶的光学厚度1064
        [~, Column_AOD_1064] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_532';  % 列平流层的光学厚度532
        [~, Column_SOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_1064'; % 列平流层的光学厚度1064
        [~, Column_SOD_1064] = readHDF(filename,variable,start,edges);
    catch
        variable = 'Column_Optical_Depth_Stratospheric_Aerosols_532';    % 列对流层气溶胶光学厚度532
        [~, Column_SAOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Tropospheric_Aerosols_532';     % 列平流层气溶胶光学厚度532
        [~, Column_TAOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_Aerosols_1064';   % 列对流层气溶胶光学厚度1064
        [~, Column_SAOD_1064] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Tropospheric_Aerosols_1064';    % 列平流层气溶胶光学厚度1064
        [~, Column_TAOD_1064] = readHDF(filename,variable,start,edges);
    end
    % 列集成衰减后向散射532
    variable = 'Column_Integrated_Attenuated_Backscatter_532';
    [~, Column_Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 列IAB累积概率
    variable = 'Column_IAB_Cumulative_Probability';
    [~, Column_IAB_Cumulative_Probability] = readHDF(filename,variable,start,edges);
    % 地表高程统计
    variable = 'Surface_Elevation_Statistics';
    [~, Surface_Elevation_Statistics] = readHDF(filename,variable,start,edges);
    % 列特征分数
    variable = 'Column_Feature_Fraction';
    [~, Column_Feature_Fraction] = readHDF(filename,variable,start,edges);
    % 样本平均
    variable = 'Samples_Averaged';
    [~, Samples_Averaged] = readHDF(filename,variable,start,edges);
    % 气溶胶层分数
    variable = 'Aerosol_Layer_Fraction';
    [~, Aerosol_Layer_Fraction] = readHDF(filename,variable,start,edges);
    % 总后向散射系数532
    variable = 'Total_Backscatter_Coefficient_532';
    [~, Total_Backscatter_Coefficient_532] = readHDF(filename,variable,start,edges);
    % 后向散射系数532 不确定性
    variable = 'Total_Backscatter_Coefficient_Uncertainty_532';
    [~, Total_Backscatter_Coefficient_Uncertainty_532] = readHDF(filename,variable,start,edges);
    % 后向散射系数1064
    variable = 'Backscatter_Coefficient_1064';
    [~, Backscatter_Coefficient_1064] = readHDF(filename,variable,start,edges);
    % 垂直后向散射系数532
    variable = 'Perpendicular_Backscatter_Coefficient_532';
    [~, Perpendicular_Backscatter_Coefficient_532] = readHDF(filename,variable,start,edges);
    % 消光系数532
    variable = 'Extinction_Coefficient_532';
    [~, Extinction_Coefficient_532] = readHDF(filename,variable,start,edges);
    % 消光系数532 不确定性
    variable = 'Extinction_Coefficient_Uncertainty_532';
    [~, Extinction_Coefficient_Uncertainty_532] = readHDF(filename,variable,start,edges);
    % 消光系数1064
    variable = 'Extinction_Coefficient_1064';
    [~, Extinction_Coefficient_1064] = readHDF(filename,variable,start,edges);
    % 消光系数1064 不确定性
    variable = 'Extinction_Coefficient_Uncertainty_1064';
    [~, Extinction_Coefficient_Uncertainty_1064] = readHDF(filename,variable,start,edges);
    % 气溶胶多重散射剖面532
    variable = 'Aerosol_Multiple_Scattering_Profile_532';
    [~, Aerosol_Multiple_Scattering_Profile_532] = readHDF(filename,variable,start,edges);
    % 气溶胶多重散射剖面1064
    variable = 'Aerosol_Multiple_Scattering_Profile_1064';
    [~, Aerosol_Multiple_Scattering_Profile_1064] = readHDF(filename,variable,start,edges);
    % 空气分子数密度
    variable                         = 'Molecular_Number_Density';
    [~, Molecular_Number_Density] = readHDF(filename,variable,start,edges);
    Molecular_Number_Density(Molecular_Number_Density == -9999)=nan;  

    % 臭氧分子的数密度
    variable                     = 'Ozone_Number_Density';
    [~, Ozone_Number_Density] = readHDF(filename,variable,start,edges);
    Ozone_Number_Density(Ozone_Number_Density == -9999)=nan;  

    CrossSection_Rayleigh_Backscatter_532 = hdfread(filename, '/metadata', 'Fields',...
        'Rayleigh_Backscatter_Cross-section_532');% 532波段空气分子瑞利后向散射截面（常数）
    CrossSection_Ozone_Absorption_532 = hdfread(filename, '/metadata', 'Fields',...
        'Ozone_Absorption_Cross-section_532');% 532波段臭氧的吸收截面（常数）
    CrossSection_Rayleigh_Backscatter_1064 = hdfread(filename, '/metadata', 'Fields',...
        'Rayleigh_Backscatter_Cross-section_1064');% 1064波段空气分子瑞利后向散射截面（常数）
    CrossSection_Ozone_Absorption_1064 = hdfread(filename, '/metadata', 'Fields',...
        'Ozone_Absorption_Cross-section_1064');% 1064波段臭氧的吸收截面（常数）为0。
    % 计算空气分子的后向散射系数和臭氧的吸收系数（个/m）
    air_molecule_backscattering_coefficient_532_interpolation  = Molecular_Number_Density * CrossSection_Rayleigh_Backscatter_532{1,1}; % 空气分子数密度*532nm瑞利后向散射截面=空气分子后向散射系数。
    air_molecule_backscattering_coefficient_1064_interpolation = Molecular_Number_Density * CrossSection_Rayleigh_Backscatter_1064{1,1}; % 空气分子数密度*532nm瑞利后向散射截面=空气分子后向散射系数。
    Ozone_absorption_coefficient_532_interpolation             = Ozone_Number_Density * CrossSection_Ozone_Absorption_532{1,1}; % 臭氧数密度*532nm臭氧吸收截面=臭氧吸收系数。
    Ozone_absorption_coefficient_1064_interpolation            = Ozone_Number_Density * CrossSection_Ozone_Absorption_1064{1,1}; % 臭氧数密度*532nm臭氧吸收截面=臭氧吸收系数。
    
    
    % 4.输出
    output_CALIPSO_L2_data.fileName                                     = filename;
    output_CALIPSO_L2_data.profile_number                               = indB;
    output_CALIPSO_L2_data.profile_start_end                            = ilat2;
    output_CALIPSO_L2_data.Lon                                          = Lon;
    output_CALIPSO_L2_data.Lat                                          = Lat; 
    output_CALIPSO_L2_data.Altitudes_Profile                            =Altitudes_Profile;
    output_CALIPSO_L2_data.CAD_Score                                    = CAD_Score;
    output_CALIPSO_L2_data.Column_COD_532                               = Column_COD_532;
    try
        output_CALIPSO_L2_data.Column_AOD_532                               = Column_AOD_532;
        output_CALIPSO_L2_data.Column_AOD_1064                              = Column_AOD_1064;
        output_CALIPSO_L2_data.Column_SOD_532                               = Column_SOD_532;
        output_CALIPSO_L2_data.Column_SOD_1064                              = Column_SOD_1064;
    catch
        output_CALIPSO_L2_data.Column_SAOD_532                                 = Column_SAOD_532;
        output_CALIPSO_L2_data.Column_TAOD_532                                 = Column_TAOD_532;
        output_CALIPSO_L2_data.Column_SAOD_1064                                = Column_SAOD_1064;
        output_CALIPSO_L2_data.Column_TAOD_1064                                = Column_TAOD_1064;
    end
    output_CALIPSO_L2_data.Column_Integrated_Attenuated_Backscatter_532 = Column_Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Column_IAB_Cumulative_Probability            = Column_IAB_Cumulative_Probability;
    output_CALIPSO_L2_data.Surface_Elevation_Statistics                 = Surface_Elevation_Statistics;
    output_CALIPSO_L2_data.Column_Feature_Fraction                      = Column_Feature_Fraction;
    output_CALIPSO_L2_data.Samples_Averaged                             = Samples_Averaged;
    output_CALIPSO_L2_data.Aerosol_Layer_Fraction                       = Aerosol_Layer_Fraction;
    output_CALIPSO_L2_data.Atmospheric_Volume_Description               = Atmospheric_Volume_Description;
    output_CALIPSO_L2_data.Extinction_QC_Flag_532                       = Extinction_QC_Flag_532;
    output_CALIPSO_L2_data.Extinction_QC_Flag_1064                      = Extinction_QC_Flag_1064;
    output_CALIPSO_L2_data.Total_Backscatter_Coefficient_532            = Total_Backscatter_Coefficient_532;
    output_CALIPSO_L2_data.Total_Backscatter_Coefficient_Uncertainty_532            = Total_Backscatter_Coefficient_Uncertainty_532;
    output_CALIPSO_L2_data.Backscatter_Coefficient_1064                 = Backscatter_Coefficient_1064;
    output_CALIPSO_L2_data.Perpendicular_Backscatter_Coefficient_532    = Perpendicular_Backscatter_Coefficient_532;
    output_CALIPSO_L2_data.Extinction_Coefficient_532                   = Extinction_Coefficient_532;
    output_CALIPSO_L2_data.Extinction_Coefficient_Uncertainty_532       =Extinction_Coefficient_Uncertainty_532;
    output_CALIPSO_L2_data.Extinction_Coefficient_1064                  = Extinction_Coefficient_1064;
    output_CALIPSO_L2_data.Extinction_Coefficient_Uncertainty_1064      =Extinction_Coefficient_Uncertainty_1064;
    output_CALIPSO_L2_data.Aerosol_Multiple_Scattering_Profile_532      = Aerosol_Multiple_Scattering_Profile_532;
    output_CALIPSO_L2_data.Aerosol_Multiple_Scattering_Profile_1064     = Aerosol_Multiple_Scattering_Profile_1064; 
    output_CALIPSO_L2_data.beta_m_interpolation_532     = air_molecule_backscattering_coefficient_532_interpolation; 
    output_CALIPSO_L2_data.beta_m_interpolation_1064     = air_molecule_backscattering_coefficient_1064_interpolation; 
    output_CALIPSO_L2_data.alpha_O3_interpolation_532     = Ozone_absorption_coefficient_532_interpolation; 
    output_CALIPSO_L2_data.alpha_O3_interpolation_1064     = Ozone_absorption_coefficient_1064_interpolation; 

end

%% 读取05kmCPro数据
if ~isempty(strfind(filename,'05kmCPro') )
    variable = 'Latitude';
    [~, lat_whole] = readHDF(filename,variable);
    if any(isnan(profile_start_and_length))  % 如果前文没有完全指出实际用到的廓线，则下面开始计算；若已指出则不必计算，直接读取即可。
        % 1.选取起始廓线的位置 方法1：
        lat_the_first_column = lat_whole(:,1);
        lat_the_last_column = lat_whole(:,3);
        % 先看纬度是从大到小呢，还是从小到大
        if lat_the_first_column(1) < lat_the_first_column(end)                 % 从小到大
            start_profile = find(lat_the_last_column > lat_lim(1),1,'first'); % 第一次大
            end_profile = find(lat_the_first_column < lat_lim(2),1,'last');    % 最后一次小
        else
            start_profile = find(lat_the_first_column < lat_lim(2),1,'first'); % 第一次小
            end_profile = find(lat_the_last_column > lat_lim(1),1,'last');  % 最后一次大
        end
        ilat = [start_profile,end_profile];
        indA = ilat(1)-1; % DECREMENT for readHDF!1!  % 起始位置
        indB = (ilat(2)-ilat(1)+1);  % 范围内的条数-1。不知为何总是该数总是比需要提取的总廓线条数少1，才可以。
        % 2.调整廓线条数(需Horizontal_Averaging和Layer_Top_Altitude配合使用)
        start = [indA 0];
        edges = [indB -9];
        variable = 'Horizontal_Averaging'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Horizontal_Averaging] = readHDF(filename,variable,start,edges);
        variable = 'Layer_Top_Altitude'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
        top_right_80km = nan(size(Layer_Top_Altitude));        % 官方80km检测出的层次
        for i=1:size(Horizontal_Averaging,1)
            for j=1:size(Horizontal_Averaging,2)
                if Horizontal_Averaging(i,j) ==80
                    top_right_80km(i,j) = Layer_Top_Altitude(i,j);
                end
            end
        end
        residue = mod(size(top_right_80km,1),16);% 表示要去掉residue条廓线。
        % 遍历每行直到找到与目标行（第一行的的一个非nan数）连起一共16行的都具有同样数的起始行。
        bingo = 0;
        for i=1:size(top_right_80km,1)
            target = top_right_80km(i,~isnan(top_right_80km(i,:)));
            if isempty(target)
                continue;
            end
            repetition = 1;
            for int = 1:length(target)
                for j = i+1:size(top_right_80km,1)
                    if find(top_right_80km(j,:)==target(int))
                        repetition = repetition+1;
                    else
                        break;
                    end
                end
            end
            if repetition == 16
                bingo = 1;
                start_ave_row = i;
                break;
            end
        end
        if bingo == 1
            before_cut = mod(start_ave_row-1,16);
            after_cut = residue - before_cut;
        else
            % 手动查看top_right_80km_change字段后，屏幕要求输入两个数（开始廓线改变量，结尾廓线改变量）表示前后要减去的廓线条数。必为正值，正常连续相同的有16条。
            before_cut = input('please input a number:');
            after_cut = input('please input a number:');
        end
        indA = indA - before_cut;
        indB = indB - before_cut - after_cut; % 实际上就是indB - residue；
    else
        indA = profile_start_and_length(1)-1;
        indB = profile_start_and_length(2);
    end
    % 3.开始读取
    % 经纬度
    start = [indA 0];
    edges = [indB 3];
    variable = 'Longitude';
    [~, Lon] = readHDF(filename,variable,start,edges);
    variable = 'Latitude';
    [~, Lat] = readHDF(filename,variable,start,edges);
    lat_start_inwhole = find(round(lat_whole(:,1),4) == round(Lat(1,1),4));
    lat_end_inwhole = find(round(lat_whole(:,1),4) == round(Lat(end,1),4)); % 选中的廓线在总廓线中的终止位置
    ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
    % 激光雷达数据高度（583）
    Altitudes_Profile = hdfread(filename,'/metadata', 'Fields',...
        'Lidar_Data_Altitudes');
    Altitudes_Profile = Altitudes_Profile{1,1}; % 为什么会有{1,1}？因为原来的激光雷达数据高度储存方式是元胞数组型，这里提取出矩阵型。
    % CAD分数
    start = [indA 0 0];
    edges = [indB -9 -9];
    variable = 'CAD_Score';
    [~, CAD_Score] = readHDF(filename,variable,start,edges);
    % 大气体积描述
    variable = 'Atmospheric_Volume_Description';
    [~, Atmospheric_Volume_Description] = readHDF(filename,variable,start,edges);
    % 消光QC标志532
    variable = 'Extinction_QC_Flag_532';
    [~, Extinction_QC_Flag_532] = readHDF(filename,variable,start,edges);
    % 列云的光学厚度532
    start = [indA 0];
    edges = [indB -9];
    variable = 'Column_Optical_Depth_Cloud_532';
    [~, Column_COD_532] = readHDF(filename,variable,start,edges);
    try
        variable = 'Column_Optical_Depth_Aerosols_532';   % 列气溶胶的光学厚度532
        [~, Column_AOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Aerosols_1064';      % 列气溶胶的光学厚度1064
        [~, Column_AOD_1064] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_532';  % 列平流层的光学厚度532
        [~, Column_SOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_1064'; % 列平流层的光学厚度1064
        [~, Column_SOD_1064] = readHDF(filename,variable,start,edges);
    catch
        variable = 'Column_Optical_Depth_Stratospheric_Aerosols_532';    % 列对流层气溶胶光学厚度532
        [~, Column_SAOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Tropospheric_Aerosols_532';     % 列平流层气溶胶光学厚度532
        [~, Column_TAOD_532] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Stratospheric_Aerosols_1064';   % 列对流层气溶胶光学厚度1064
        [~, Column_SAOD_1064] = readHDF(filename,variable,start,edges);
        variable = 'Column_Optical_Depth_Tropospheric_Aerosols_1064';    % 列平流层气溶胶光学厚度1064
        [~, Column_TAOD_1064] = readHDF(filename,variable,start,edges);
    end
    % 列集成衰减后向散射532
    variable = 'Column_Integrated_Attenuated_Backscatter_532';
    [~, Column_Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 列IAB累积概率
    variable = 'Column_IAB_Cumulative_Probability';
    [~, Column_IAB_Cumulative_Probability] = readHDF(filename,variable,start,edges);
    % 地表高程统计
    variable = 'Surface_Elevation_Statistics';
    [~, Surface_Elevation_Statistics] = readHDF(filename,variable,start,edges);
    % 列特征分数
    variable = 'Column_Feature_Fraction';
    [~, Column_Feature_Fraction] = readHDF(filename,variable,start,edges);
    % 样本平均
    variable = 'Samples_Averaged';
    [~, Samples_Averaged] = readHDF(filename,variable,start,edges);
    % 气溶胶层分数
    variable = 'Aerosol_Layer_Fraction';
    [~, Aerosol_Layer_Fraction] = readHDF(filename,variable,start,edges);
    % 总后向散射系数532
    variable = 'Total_Backscatter_Coefficient_532';
    [~, Total_Backscatter_Coefficient_532] = readHDF(filename,variable,start,edges);
    % 垂直后向散射系数532
    variable = 'Perpendicular_Backscatter_Coefficient_532';
    [~, Perpendicular_Backscatter_Coefficient_532] = readHDF(filename,variable,start,edges);
    % 消光系数532
    variable = 'Extinction_Coefficient_532';
    [~, Extinction_Coefficient_532] = readHDF(filename,variable,start,edges);
    % 云多重散射剖面532
    variable = 'Cloud_Multiple_Scattering_Profile_532';
    [~, Cloud_Multiple_Scattering_Profile_532] = readHDF(filename,variable,start,edges);
    % 冰水含量廓线
    variable = 'Ice_Water_Content_Profile';
    [~, Ice_Water_Content_Profile] = readHDF(filename,variable,start,edges);
    % 消光系数532 不确定性
    variable = 'Extinction_Coefficient_Uncertainty_532';
    [~, Extinction_Coefficient_Uncertainty_532] = readHDF(filename,variable,start,edges);
    % 后向散射系数532 不确定性
    variable = 'Total_Backscatter_Coefficient_Uncertainty_532';
    [~, Total_Backscatter_Coefficient_Uncertainty_532] = readHDF(filename,variable,start,edges);    
    % 4.输出
    output_CALIPSO_L2_data.fileName                                     = filename;
    output_CALIPSO_L2_data.profile_number                               = indB;
    output_CALIPSO_L2_data.profile_start_end                            = ilat2;
    output_CALIPSO_L2_data.Lon                                          = Lon;
    output_CALIPSO_L2_data.Lat                                          = Lat;
    output_CALIPSO_L2_data.Altitudes_Profile                            =Altitudes_Profile;
    output_CALIPSO_L2_data.CAD_Score                                    = CAD_Score;
    output_CALIPSO_L2_data.Column_COD_532                               = Column_COD_532;
    try
        output_CALIPSO_L2_data.Column_AOD_532                               = Column_AOD_532;
        output_CALIPSO_L2_data.Column_AOD_1064                              = Column_AOD_1064;
        output_CALIPSO_L2_data.Column_SOD_532                               = Column_SOD_532;
        output_CALIPSO_L2_data.Column_SOD_1064                              = Column_SOD_1064;
    catch
        output_CALIPSO_L2_data.Column_SAOD_532                                 = Column_SAOD_532;
        output_CALIPSO_L2_data.Column_TAOD_532                                 = Column_TAOD_532;
        output_CALIPSO_L2_data.Column_SAOD_1064                                = Column_SAOD_1064;
        output_CALIPSO_L2_data.Column_TAOD_1064                                = Column_TAOD_1064;
    end
    output_CALIPSO_L2_data.Column_Integrated_Attenuated_Backscatter_532 = Column_Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Column_IAB_Cumulative_Probability            = Column_IAB_Cumulative_Probability;
    output_CALIPSO_L2_data.Surface_Elevation_Statistics                 = Surface_Elevation_Statistics;
    output_CALIPSO_L2_data.Column_Feature_Fraction                      = Column_Feature_Fraction;
    output_CALIPSO_L2_data.Samples_Averaged                             = Samples_Averaged;
    output_CALIPSO_L2_data.Aerosol_Layer_Fraction                       = Aerosol_Layer_Fraction;
    output_CALIPSO_L2_data.Atmospheric_Volume_Description               = Atmospheric_Volume_Description;
    output_CALIPSO_L2_data.Extinction_QC_Flag_532                       = Extinction_QC_Flag_532;
    output_CALIPSO_L2_data.Ice_Water_Content_Profile                    = Ice_Water_Content_Profile;
    output_CALIPSO_L2_data.Cloud_Multiple_Scattering_Profile_532        = Cloud_Multiple_Scattering_Profile_532;
    output_CALIPSO_L2_data.Total_Backscatter_Coefficient_532            = Total_Backscatter_Coefficient_532;
    output_CALIPSO_L2_data.Perpendicular_Backscatter_Coefficient_532    = Perpendicular_Backscatter_Coefficient_532;
    output_CALIPSO_L2_data.Extinction_Coefficient_532                   = Extinction_Coefficient_532;
    output_CALIPSO_L2_data.Total_Backscatter_Coefficient_Uncertainty_532            = Total_Backscatter_Coefficient_Uncertainty_532;
    output_CALIPSO_L2_data.Extinction_Coefficient_Uncertainty_532       =Extinction_Coefficient_Uncertainty_532;
end

%% 读取VFM数据
if ~isempty(strfind(filename,'VFM') )
    variable = 'Latitude';
    [~, lat_whole] = readHDF(filename,variable);
    if any(isnan(profile_start_and_length))  % 如果前文没有完全指出实际用到的廓线，则下面开始计算；若已指出则不必计算，直接读取即可。
        % 1.找到限制纬度区域内所对应的廓线（从第几条开始共多少条）
        ilat(1) = find(lat_whole == lat_lim(1),1,'first');
        ilat(2) = find(lat_whole == lat_lim(2),1,'last');
        disp(['Reading CALIPSO L2：',filename])
        fprintf('New latitudes %f %f\n',lat_whole(ilat(1)),lat_whole(ilat(2)));
        indA = ilat(1)-1; % DECREMENT for readHDF!1!  % 起始位置
        indB = (ilat(2)-ilat(1)+1);  % 范围内的条数-1。不知为何总是该数总是比需要提取的总廓线条数少1，才可以。
        % 2.调整廓线条数(需Horizontal_Averaging和Layer_Top_Altitude配合使用)
        start = [indA 0];
        edges = [indB -9];
        variable = 'Horizontal_Averaging'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Horizontal_Averaging] = readHDF(filename,variable,start,edges);
        variable = 'Layer_Top_Altitude'; % 水平平均（表示该层次检测到时所需要的水平平均量0,5,20,80）
        [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
        top_right_80km = nan(size(Layer_Top_Altitude));        % 官方80km检测出的层次
        for i=1:size(Horizontal_Averaging,1)
            for j=1:size(Horizontal_Averaging,2)
                if Horizontal_Averaging(i,j) ==80
                    top_right_80km(i,j) = Layer_Top_Altitude(i,j);
                end
            end
        end
        residue = mod(size(top_right_80km,1),16);% 表示要去掉residue条廓线。
        % 遍历每行直到找到与目标行（第一行的的一个非nan数）连起一共16行的都具有同样数的起始行。
        bingo = 0;
        for i=1:size(top_right_80km,1)
            target = top_right_80km(i,~isnan(top_right_80km(i,:)));
            if isempty(target)
                continue;
            end
            repetition = 1;
            for int = 1:length(target)
                for j = i+1:size(top_right_80km,1)
                    if find(top_right_80km(j,:)==target(int))
                        repetition = repetition+1;
                    else
                        break;
                    end
                end
            end
            if repetition == 16
                bingo = 1;
                start_ave_row = i;
                break;
            end
        end
        if bingo == 1
            before_cut = mod(start_ave_row-1,16);
            after_cut = residue - before_cut;
        else
            % 手动查看top_right_80km_change字段后，屏幕要求输入两个数（开始廓线改变量，结尾廓线改变量）表示前后要减去的廓线条数。必为正值，正常连续相同的有16条。
            before_cut = input('please input a number:');
            after_cut = input('please input a number:');
        end
        indA = indA - before_cut;
        indB = indB - before_cut - after_cut; % 实际上就是indB - residue；
    else
        indA = profile_start_and_length(1)-1;
        indB = profile_start_and_length(2);
    end
    % 3.开始读取
    % 经纬度
    start = [indA 0];
    edges = [indB 1];
    variable = 'Longitude';
    [~, Lon] = readHDF(filename,variable,start,edges);
    variable = 'Latitude';
    [~, Lat] = readHDF(filename,variable,start,edges);
    lat_start_inwhole = find(lat_whole(:,1) == Lat(1,1));
    lat_end_inwhole = find(lat_whole(:,1) == Lat(end,1)); % 选中的廓线在总廓线中的终止位置
    ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
    % 特征分类标志
    try
        start = [indA 0];
        edges = [indB -9];
        variable = 'Feature_Classification_Flags';
        [~, Feature_Classification_Flags] = readHDF(filename,variable,start,edges);
    end
    % 4.输出
    output_CALIPSO_L2_data.fileName = filename;
    output_CALIPSO_L2_data.profile_number = indB;
    output_CALIPSO_L2_data.profile_start_end = ilat2;
    output_CALIPSO_L2_data.Lon = Lon;
    output_CALIPSO_L2_data.Lat = Lat; 
    try
        output_CALIPSO_L2_data.Feature_Classification_Flags = Feature_Classification_Flags;
    end
end 

%% 读取01kmCLay数据
if ~isempty(strfind(filename,'01kmCLay') )
    % 1.找到限制纬度区域内所对应的廓线（从第几条开始共多少条）
    variable = 'Latitude';
    [~, lat_whole] = readHDF(filename,variable);
    ilat(1) = find(round(lat_whole,4) == round(lat_lim(1),4),1);
    ilat(2) = find(round(lat_whole,4) == round(lat_lim(2),4),1);
    
    disp(['Reading CALIPSO L2：',filename])
    fprintf('New latitudes %f %f\n',lat_whole(ilat(1)),lat_whole(ilat(2)));
    indA = ilat(1)-1; % DECREMENT for readHDF!1!
    indB = (ilat(2)-ilat(1)+1);
    % 2.开始读取
    % 经纬度
    start = [indA 0];
    edges = [indB 1];
    variable = 'Longitude';
    [~, Lon] = readHDF(filename,variable,start,edges);
    variable = 'Latitude';
    [~, Lat] = readHDF(filename,variable,start,edges);
    lat_start_inwhole = find(round(lat_whole(:,1),4) == round(Lat(1,1),4)); % 选中的廓线在总廓线中的终止位置
    lat_end_inwhole = find(round(lat_whole(:,1),4) == round(Lat(end,1),4)); % 选中的廓线在总廓线中的终止位置
    ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
    % DEM地表高程
    start = [indA 0];
    edges = [indB -9];
    variable = 'DEM_Surface_Elevation';
    [~, DEM_Surface_Elevation] = readHDF(filename,variable,start,edges);
    % 激光雷达测得的地表高程
    try
        variable = 'Lidar_Surface_Elevation';
        [~, Lidar_Surface_Elevation] = readHDF(filename,variable,start,edges);
    catch
        variable = 'Surface_Top_Altitude_532';
        [~, Surface_Top_Altitude_532] = readHDF(filename,variable,start,edges);
        variable = 'Surface_Base_Altitude_532';
        [~, Surface_Base_Altitude_532] = readHDF(filename,variable,start,edges);
    end
    % 层顶高度
    variable = 'Layer_Top_Altitude';
    [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
    % 层底高度
    variable = 'Layer_Base_Altitude';
    [~, Layer_Base_Altitude] = readHDF(filename,variable,start,edges);
    % 每列的层次数目
    variable = 'Number_Layers_Found';
    [~, Number_Layers_Found] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射532
    variable = 'Integrated_Attenuated_Backscatter_532';
    [~, Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计532
    variable = 'Attenuated_Backscatter_Statistics_532';
    [~, Attenuated_Backscatter_Statistics_532] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射1064
    variable = 'Integrated_Attenuated_Backscatter_1064';
    [~, Integrated_Attenuated_Backscatter_1064] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计1064
    variable = 'Attenuated_Backscatter_Statistics_1064';
    [~, Attenuated_Backscatter_Statistics_1064] = readHDF(filename,variable,start,edges);
    % 整层总体体积去极化比
    variable = 'Integrated_Volume_Depolarization_Ratio';
    [~, Integrated_Volume_Depolarization_Ratio] = readHDF(filename,variable,start,edges);
    % 体积去极化比统计
    variable = 'Volume_Depolarization_Ratio_Statistics';
    [~, Volume_Depolarization_Ratio_Statistics] = readHDF(filename,variable,start,edges);
        % 层积分颗粒去极化比
    variable = 'Integrated_Particulate_Depolarization_Ratio';
    [~, Integrated_Particulate_Depolarization_Ratio] = readHDF(filename,variable,start,edges);
    % 层积分颗粒去极化比统计
    variable = 'Particulate_Depolarization_Ratio_Statistics';
    [~, Particulate_Depolarization_Ratio_Statistics] = readHDF(filename,variable,start,edges);       
    % 整层总体衰减总色比
    variable = 'Integrated_Attenuated_Total_Color_Ratio';
    [~, Integrated_Attenuated_Total_Color_Ratio] = readHDF(filename,variable,start,edges);
    % 衰减总色比统计
    variable = 'Attenuated_Total_Color_Ratio_Statistics';
    [~, Attenuated_Total_Color_Ratio_Statistics] = readHDF(filename,variable,start,edges);
    % CAD分数
    variable = 'CAD_Score';
    [~, CAD_Score] = readHDF(filename,variable,start,edges);
    % 层次分类标志
    variable = 'Feature_Classification_Flags';
    [~, Feature_Classification_Flags] = readHDF(filename,variable,start,edges);
    % 层顶温度
    variable = 'Layer_Top_Temperature';
    [~, Layer_Top_Temperature] = readHDF(filename,variable,start,edges);
     % 层底温度
    variable = 'Layer_Base_Temperature';
    [~, Layer_Base_Temperature] = readHDF(filename,variable,start,edges);
     % 层中心温度
    variable = 'Midlayer_Temperature';
    [~, Midlayer_Temperature] = readHDF(filename,variable,start,edges);
    % 层顶压强
    variable = 'Layer_Top_Pressure';
    [~, Layer_Top_Pressure] = readHDF(filename,variable,start,edges);
    % 层底压强
    variable = 'Layer_Base_Pressure';
    [~, Layer_Base_Pressure] = readHDF(filename,variable,start,edges);
    % 层中心压强
    variable = 'Midlayer_Pressure';
    [~, Midlayer_Pressure] = readHDF(filename,variable,start,edges);  
    % 地表类型
    variable = 'IGBP_Surface_Type';
    [~, IGBP_Surface_Type] = readHDF(filename,variable,start,edges);   
     % 对流层高度
    variable = 'Tropopause_Height';
    [~, Tropopause_Height] = readHDF(filename,variable,start,edges);    

    % 3.输出
    output_CALIPSO_L2_data.fileName                                = filename;
    output_CALIPSO_L2_data.profile_number                          = indB;
    output_CALIPSO_L2_data.profile_start_end                       = ilat2;
    output_CALIPSO_L2_data.Lon                                     = Lon;
    output_CALIPSO_L2_data.Lat                                     = Lat;
    output_CALIPSO_L2_data.DEM_Surface_Elevation                   = DEM_Surface_Elevation;
    try
        output_CALIPSO_L2_data.Lidar_Surface_Elevation             = Lidar_Surface_Elevation;
    catch
        output_CALIPSO_L2_data.Surface_Top_Altitude_532            = Surface_Top_Altitude_532;
        output_CALIPSO_L2_data.Surface_Base_Altitude_532           = Surface_Base_Altitude_532;
    end
    output_CALIPSO_L2_data.Layer_Top_Altitude                      = Layer_Top_Altitude;
    output_CALIPSO_L2_data.Layer_Base_Altitude                     = Layer_Base_Altitude;
    output_CALIPSO_L2_data.Number_Layers_Found                     = Number_Layers_Found;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_532   = Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_532   = Attenuated_Backscatter_Statistics_532;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_1064  = Integrated_Attenuated_Backscatter_1064;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_1064  = Attenuated_Backscatter_Statistics_1064;
    output_CALIPSO_L2_data.Integrated_Volume_Depolarization_Ratio  = Integrated_Volume_Depolarization_Ratio;
    output_CALIPSO_L2_data.Volume_Depolarization_Ratio_Statistics  = Volume_Depolarization_Ratio_Statistics;
    output_CALIPSO_L2_data.Integrated_Particulate_Depolarization_Ratio          = Integrated_Particulate_Depolarization_Ratio;
    output_CALIPSO_L2_data.Particulate_Depolarization_Ratio_Statistics         = Particulate_Depolarization_Ratio_Statistics;    
    output_CALIPSO_L2_data.Integrated_Attenuated_Total_Color_Ratio = Integrated_Attenuated_Total_Color_Ratio;
    output_CALIPSO_L2_data.Attenuated_Total_Color_Ratio_Statistics = Attenuated_Total_Color_Ratio_Statistics;
    output_CALIPSO_L2_data.CAD_Score                               = CAD_Score;
    output_CALIPSO_L2_data.Feature_Classification_Flags            = Feature_Classification_Flags;
    output_CALIPSO_L2_data.Layer_Top_Temperature                               = Layer_Top_Temperature;
    output_CALIPSO_L2_data.Layer_Base_Temperature                    = Layer_Base_Temperature;   
    output_CALIPSO_L2_data.Midlayer_Temperature                    = Midlayer_Temperature;   
    output_CALIPSO_L2_data.Layer_Top_Pressure                    = Layer_Top_Pressure;   
    output_CALIPSO_L2_data.Layer_Base_Pressure                   = Layer_Base_Pressure;   
    output_CALIPSO_L2_data.Midlayer_Pressure                    = Midlayer_Pressure;  
    output_CALIPSO_L2_data.IGBP_Surface_Type                    = IGBP_Surface_Type; 
    output_CALIPSO_L2_data.Tropopause_Height=Tropopause_Height;  

end

%% 读取333mCLay数据
if ~isempty(strfind(filename,'333mCLay') )
    % 1.找到限制纬度区域内所对应的廓线（从第几条开始共多少条）
    variable = 'Latitude';
    [~, lat_whole] = readHDF(filename,variable);
    ilat(1) = find(round(lat_whole,4) == round(lat_lim(1),4),1,'first');
    ilat(2) = find(round(lat_whole,4) == round(lat_lim(2),4),1,'last');
    
    disp(['Reading CALIPSO L2：',filename])
    fprintf('New latitudes %f %f\n',lat_whole(ilat(1)),lat_whole(ilat(2)));
    indA = ilat(1)-1; % DECREMENT for readHDF!1!
    indB = (ilat(2)-ilat(1)+1);
    % 2.开始读取
    % 经纬度
    start = [indA 0];
    edges = [indB 1];
    variable = 'Longitude';
    [~, Lon] = readHDF(filename,variable,start,edges);
    variable = 'Latitude';
    [~, Lat] = readHDF(filename,variable,start,edges);
    lat_start_inwhole = find(lat_whole(:,1) == Lat(1,1));
    lat_end_inwhole = find(lat_whole(:,1) == Lat(end,1)); % 选中的廓线在总廓线中的终止位置
    ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
    % DEM地表高程
    start = [indA 0];
    edges = [indB -9];
    variable = 'DEM_Surface_Elevation';
    [~, DEM_Surface_Elevation] = readHDF(filename,variable,start,edges);
    % 激光雷达测得的地表高程
    variable = 'Lidar_Surface_Elevation';
    [~, Lidar_Surface_Elevation] = readHDF(filename,variable,start,edges);
    % 层顶高度
    variable = 'Layer_Top_Altitude';
    [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
    % 层底高度
    variable = 'Layer_Base_Altitude';
    [~, Layer_Base_Altitude] = readHDF(filename,variable,start,edges);
    % 每列的层次数目
    variable = 'Number_Layers_Found';
    [~, Number_Layers_Found] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射532
    variable = 'Integrated_Attenuated_Backscatter_532';
    [~, Integrated_Attenuated_Backscatter_532] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计532
    variable = 'Attenuated_Backscatter_Statistics_532';
    [~, Attenuated_Backscatter_Statistics_532] = readHDF(filename,variable,start,edges);
    % 整层总体衰减后向散射1064
    variable = 'Integrated_Attenuated_Backscatter_1064';
    [~, Integrated_Attenuated_Backscatter_1064] = readHDF(filename,variable,start,edges);
    % 衰减后向散射统计1064
    variable = 'Attenuated_Backscatter_Statistics_1064';
    [~, Attenuated_Backscatter_Statistics_1064] = readHDF(filename,variable,start,edges);
    % 整层总体体积去极化比
    variable = 'Integrated_Volume_Depolarization_Ratio';
    [~, Integrated_Volume_Depolarization_Ratio] = readHDF(filename,variable,start,edges);
    % 体积去极化比统计
    variable = 'Volume_Depolarization_Ratio_Statistics';
    [~, Volume_Depolarization_Ratio_Statistics] = readHDF(filename,variable,start,edges);
    % 整层总体衰减总色比
    variable = 'Integrated_Attenuated_Total_Color_Ratio';
    [~, Integrated_Attenuated_Total_Color_Ratio] = readHDF(filename,variable,start,edges);
    % 衰减总色比统计
    variable = 'Attenuated_Total_Color_Ratio_Statistics';
    [~, Attenuated_Total_Color_Ratio_Statistics] = readHDF(filename,variable,start,edges);
    % 层次分类标志
    variable = 'Feature_Classification_Flags';
    [~, Feature_Classification_Flags] = readHDF(filename,variable,start,edges);
    % 3.输出
    output_CALIPSO_L2_data.fileName                                = filename;
    output_CALIPSO_L2_data.profile_number                          = indB;
    output_CALIPSO_L2_data.profile_start_end                       = ilat2;
    output_CALIPSO_L2_data.Lon                                     = Lon;
    output_CALIPSO_L2_data.Lat                                     = Lat;
    output_CALIPSO_L2_data.DEM_Surface_Elevation                   = DEM_Surface_Elevation;
    output_CALIPSO_L2_data.Lidar_Surface_Elevation                 = Lidar_Surface_Elevation;
    output_CALIPSO_L2_data.Layer_Top_Altitude                      = Layer_Top_Altitude;
    output_CALIPSO_L2_data.Layer_Base_Altitude                     = Layer_Base_Altitude;
    output_CALIPSO_L2_data.Number_Layers_Found                     = Number_Layers_Found;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_532   = Integrated_Attenuated_Backscatter_532;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_532   = Attenuated_Backscatter_Statistics_532;
    output_CALIPSO_L2_data.Integrated_Attenuated_Backscatter_1064  = Integrated_Attenuated_Backscatter_1064;
    output_CALIPSO_L2_data.Attenuated_Backscatter_Statistics_1064  = Attenuated_Backscatter_Statistics_1064;
    output_CALIPSO_L2_data.Integrated_Volume_Depolarization_Ratio  = Integrated_Volume_Depolarization_Ratio;
    output_CALIPSO_L2_data.Volume_Depolarization_Ratio_Statistics  = Volume_Depolarization_Ratio_Statistics;
    output_CALIPSO_L2_data.Integrated_Attenuated_Total_Color_Ratio = Integrated_Attenuated_Total_Color_Ratio;
    output_CALIPSO_L2_data.Attenuated_Total_Color_Ratio_Statistics = Attenuated_Total_Color_Ratio_Statistics;
    output_CALIPSO_L2_data.Feature_Classification_Flags            = Feature_Classification_Flags;
end

%% 读取333mMLay数据
if ~isempty(strfind(filename,'333mMLay') )
    % 1.找到限制纬度区域内所对应的廓线（从第几条开始共多少条）
    variable = 'Latitude';
    [~, lat_whole] = readHDF(filename,variable);
    ilat(1) = find(round(lat_whole,4) == round(lat_lim(1),4),1,'first');
    ilat(2) = find(round(lat_whole,4) == round(lat_lim(2),4),1,'last');
    
    disp(['Reading CALIPSO L2：',filename])
    fprintf('New latitudes %f %f\n',lat_whole(ilat(1)),lat_whole(ilat(2)));
    indA = ilat(1)-1; % DECREMENT for readHDF!1!
    indB = (ilat(2)-ilat(1)+1);
    % 2.开始读取
    % 经纬度
    start = [indA 0];
    edges = [indB 1];
    variable = 'Longitude';
    [~, Lon] = readHDF(filename,variable,start,edges);
    variable = 'Latitude';
    [~, Lat] = readHDF(filename,variable,start,edges);
    lat_start_inwhole = find(lat_whole(:,1) == Lat(1,1));
    lat_end_inwhole = find(lat_whole(:,1) == Lat(end,1)); % 选中的廓线在总廓线中的终止位置
    ilat2 = [lat_start_inwhole,lat_end_inwhole]; % 选中的廓线在原始文件中的位置（起止）
    % DEM地表高程
    start = [indA 0];
    edges = [indB -9];
    variable = 'DEM_Surface_Elevation';
    [~, DEM_Surface_Elevation] = readHDF(filename,variable,start,edges);
    % 激光雷达检测到地表回波的顶底位置
%     variable = 'Surface_Top_Altitude_532';
%     [~, Surface_Top_Altitude_532] = readHDF(filename,variable,start,edges);
%     variable = 'Surface_Base_Altitude_532';
%     [~, Surface_Base_Altitude_532] = readHDF(filename,variable,start,edges);
    % 每列的层次数目
    variable = 'Number_Layers_Found';
    [~, Number_Layers_Found] = readHDF(filename,variable,start,edges);
    % 层次分类标志
%     variable = 'Feature_Classification_Flags';
%     [~, Feature_Classification_Flags] = readHDF(filename,variable,start,edges);
    % 层顶高度
%     variable = 'Layer_Top_Altitude';
%     [~, Layer_Top_Altitude] = readHDF(filename,variable,start,edges);
%     % 层底高度
%     variable = 'Layer_Base_Altitude';
%     [~, Layer_Base_Altitude] = readHDF(filename,variable,start,edges);
    % 3.输出
    output_CALIPSO_L2_data.fileName = filename;
    output_CALIPSO_L2_data.profile_number = indB;
    output_CALIPSO_L2_data.profile_start_end = ilat2;
    output_CALIPSO_L2_data.Lon = Lon;
    output_CALIPSO_L2_data.Lat = Lat;
    output_CALIPSO_L2_data.DEM_Surface_Elevation = DEM_Surface_Elevation;
    output_CALIPSO_L2_data.Number_Layers_Found = Number_Layers_Found;
%     output_CALIPSO_L2_data.Feature_Classification_Flags = Feature_Classification_Flags;
%     output_CALIPSO_L2_data.Surface_Top_Altitude_532 = Surface_Top_Altitude_532;
%     output_CALIPSO_L2_data.Surface_Base_Altitude_532 = Surface_Base_Altitude_532;
%     output_CALIPSO_L2_data.Layer_Top_Altitude = Layer_Top_Altitude;
%     output_CALIPSO_L2_data.Layer_Base_Altitude = Layer_Base_Altitude;
end
end
