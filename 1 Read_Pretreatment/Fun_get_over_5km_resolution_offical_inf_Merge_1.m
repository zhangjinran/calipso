function [output] = Fun_get_over_5km_resolution_offical_inf_Merge(CLay_05km,ALay_05km)
% 此函数用于读取官方不同分辨率产品信息，km转为bin，按固定格式输出结构体。即为产品信息的统一化。(此函数适用于5km(包括5km)以上分辨率的数据)
% 此方法未读取混合层数据，而是分别读取5km气溶胶层和5km云层数据并将其合并）
% 输入信息：
% CLay_05km：    5km云层
% ALay_05km：    5km气溶胶层
%% START
global Z;
% 提取官方产品中5km云层：
True_horizontal_resolution_1 = CLay_05km.Horizontal_Averaging;                      % 实际层次检测到时的真正水平分辨率，15列
Top_given_1                  = CLay_05km.Layer_Top_Altitude;                        % 5km报告中的所有层顶，15列
Base_given_1                 = CLay_05km.Layer_Base_Altitude;                       % 5km报告中的所有层底，15列
Top_given_1_ss                  = CLay_05km.ssLayer_Top_Altitude;                   % 333m报告中的所有层顶，单列
Base_given_1_ss                  = CLay_05km.ssLayer_Base_Altitude  ;               % 333m报告中的所有层底，单列
flag_Base_Extend_given_1     = CLay_05km.Layer_Base_Extended;                       % 层底是否延伸，15列
T2_532_given_1               = CLay_05km.Measured_Two_Way_Transmittance_532;        % 报告中的双向透过率
T2_Region_532_given_1        = CLay_05km.Two_Way_Transmittance_Measurement_Region;  % 报告中的双向透过率计算区域
Int_Att_Backscat_532_given_1 = CLay_05km.Integrated_Attenuated_Backscatter_532;     % 报告中的层次衰减散射的积分
DEM_given                    = CLay_05km.DEM_Surface_Elevation(:,3);                  % (5km云和气溶胶产品中相同)报告中的每5km廓线范围内地表高程的平均值（仅在检测地表回波时作为参考）（外部输入）
Opacity_Flag_given_1               = CLay_05km.Opacity_Flag;                        %层次透明度
ExtinctionQC_532_given_1      = CLay_05km.ExtinctionQC_532;                        %消光反演质量控制
Initial_532_Lidar_Ratio_given_1=CLay_05km.Initial_532_Lidar_Ratio;         %反演时所用的初始532激光雷达比
Final_532_Lidar_Ratio_given_1   =CLay_05km.Final_532_Lidar_Ratio;             %反演的最终激光雷达比：用作与我们反演结果的对比
Layer_Effective_532_Multiple_Scattering_Factor_given_1=CLay_05km.Layer_Effective_532_Multiple_Scattering_Factor;%层有效多重散射因子
try
    Surface_Top_532_given_1  = CLay_05km.Lidar_Surface_Elevation(:,3);              % 探测到的地表回波的起始位置(5km层次探测得到的地表信息实际上是1km和333m产品的统计信息第3列平均值作为5km地表回波层顶)5km云和气溶胶产品报告的地表回波位置相同
    Surface_Base_532_given_1 = CLay_05km.Lidar_Surface_Elevation(:,7);              % 探测到的地表回波的终止位置(5km层次探测得到的地表信息实际上是1km和333m产品的统计信息第7列平均值作为5km地表回波层底)5km云和气溶胶产品报告的地表回波位置相同
catch
    Surface_Top_532_given_1  = CLay_05km.Surface_Top_Altitude_532;
    Surface_Base_532_given_1 = CLay_05km.Surface_Base_Altitude_532;
end
% 提取官方产品中5km气溶胶层
True_horizontal_resolution_2 = ALay_05km.Horizontal_Averaging;                      % 实际层次检测到时的真正水平分辨率，15列
Top_given_2                  = ALay_05km.Layer_Top_Altitude;                        % 5km报告中的所有层顶，15列
Base_given_2                 = ALay_05km.Layer_Base_Altitude;                       % 5km报告中的所有层底，15列
Top_given_2_ss                  = ALay_05km.ssLayer_Top_Altitude;                   % 333m报告中的所有层顶，单列
Base_given_2_ss                  = ALay_05km.ssLayer_Base_Altitude  ;               % 333m报告中的所有层底，单列
flag_Base_Extend_given_2     = ALay_05km.Layer_Base_Extended;                       % 层底是否延伸，15列
T2_532_given_2               = ALay_05km.Measured_Two_Way_Transmittance_532;        % 报告中的双向透过率
T2_Region_532_given_2        = ALay_05km.Two_Way_Transmittance_Measurement_Region;  % 报告中的双向透过率计算区域
Int_Att_Backscat_532_given_2 = ALay_05km.Integrated_Attenuated_Backscatter_532;     % 报告中的层次衰减散射的积分
Opacity_Flag_given_2         = ALay_05km.Opacity_Flag;
ExtinctionQC_532_given_2      = ALay_05km.ExtinctionQC_532;                        %消光反演质量控制
Initial_532_Lidar_Ratio_given_2=ALay_05km.Initial_532_Lidar_Ratio;         %反演时所用的初始532激光雷达比
Final_532_Lidar_Ratio_given_2   =ALay_05km.Final_532_Lidar_Ratio;             %反演的最终激光雷达比：用作与我们反演结果的对比
Layer_Effective_532_Multiple_Scattering_Factor_given_2=ALay_05km.Layer_Effective_532_Multiple_Scattering_Factor;%层有效多重散射因子

% 预分配内存
top_right_5km                    = nan(size(Top_given_1));
base_right_5km                   = nan(size(Top_given_1));
base_extended_5km                = nan(size(Top_given_1));
topbin_right_5km                 = nan(size(Top_given_1));
basebin_right_5km                = nan(size(Top_given_1));
T2_532_5km_right                 = nan(size(Top_given_1));
T2_Region_532_5km_right           = nan(size(T2_Region_532_given_1));
Int_Att_Backscat_532_5km_right   = nan(size(Top_given_1));
Opacity_Flag_5km                 = nan(size(Top_given_1));
ExtinctionQC_532_5km      = nan(size(Top_given_1));
Initial_532_Lidar_Ratio_5km=nan(size(Top_given_1));        %反演时所用的初始532激光雷达比
Final_532_Lidar_Ratio_5km   =nan(size(Top_given_1));            %反演的最终激光雷达比：用作与我们反演结果的对比
Layer_Effective_532_Multiple_Scattering_Factor_5km=nan(size(Top_given_1));%层有效多重散射因子

top_right_20km                   = nan(size(Top_given_1));
base_right_20km                  = nan(size(Top_given_1));
base_extended_20km               = nan(size(Top_given_1));
topbin_right_20km                = nan(size(Top_given_1));
basebin_right_20km               = nan(size(Top_given_1));
T2_532_20km_right                = nan(size(Top_given_1));
T2_Region_532_20km_right          = nan(size(T2_Region_532_given_1));
Int_Att_Backscat_532_20km_right  = nan(size(Top_given_1));
DEM_20km_given                   = nan(size(DEM_given,1)/4,1);
Opacity_Flag_20km                 = nan(size(Top_given_1));
ExtinctionQC_532_20km      = nan(size(Top_given_1));
Initial_532_Lidar_Ratio_20km=nan(size(Top_given_1));        %反演时所用的初始532激光雷达比
Final_532_Lidar_Ratio_20km   =nan(size(Top_given_1));            %反演的最终激光雷达比：用作与我们反演结果的对比
Layer_Effective_532_Multiple_Scattering_Factor_20km=nan(size(Top_given_1));%层有效多重散射因子

top_right_80km                   = nan(size(Top_given_1));
base_right_80km                  = nan(size(Top_given_1));
base_extended_80km               = nan(size(Top_given_1));
topbin_right_80km                = nan(size(Top_given_1));
basebin_right_80km               = nan(size(Top_given_1));
T2_532_80km_right                = nan(size(Top_given_1));
T2_Region_532_80km_right         = nan(size(T2_Region_532_given_1));
Int_Att_Backscat_532_80km_right  = nan(size(Top_given_1));
DEM_80km_given                   = nan(size(DEM_given,1)/16,1);
Opacity_Flag_80km                = nan(size(Top_given_1));
ExtinctionQC_532_80km            = nan(size(Top_given_1));
Initial_532_Lidar_Ratio_80km     = nan(size(Top_given_1));        %反演时所用的初始532激光雷达比
Final_532_Lidar_Ratio_80km       = nan(size(Top_given_1));            %反演的最终激光雷达比：用作与我们反演结果的对比
Layer_Effective_532_Multiple_Scattering_Factor_80km=nan(size(Top_given_1));%层有效多重散射因子
top_right_333m_ss                 = nan(size(Top_given_1_ss));
base_right_333m_ss                = nan(size(Top_given_1_ss));
topbin_right_333m_ss              = nan(size(Top_given_1_ss));
basebin_right_333m_ss             = nan(size(Top_given_1_ss));   


% 官方333m分辨率检测出的层次
for i=1:size(Top_given_1_ss,1)
    int = 1;
    for j=1:size(Top_given_1_ss,2)
        if Top_given_1_ss(i,j)~=-9999
            top_right_333m_ss(i,int)                  = Top_given_1_ss(i,j);
            base_right_333m_ss(i,int)                 = Base_given_1_ss(i,j);
            topbin_right_333m_ss(i,int)               = find(Z==top_right_333m_ss(i,int),1,'last');% 得到原始层顶高度对应的距离箱bin信息
            basebin_right_333m_ss(i,int)              = find(Z==base_right_333m_ss(i,int),1,'last');% 得到原始层底高度对应的距离箱bin信息
            int = int+1;
        end
    end
end



% 5km产品中所有分辨率下的层次全部查找bin（以便画在同一条廓线上）
allTopbin_given=nan(size(Top_given_1));
allBasebin_given=nan(size(Top_given_1));
for i = 1:size(Top_given_1,1)
    for j = 1:size(Top_given_1,2)
        if Top_given_1(i,j)~=-9999
            allTopbin_given(i,j)   = find(Z==Top_given_1(i,j),1,'last');
            allBasebin_given(i,j)  = find(Z==Base_given_1(i,j),1,'last');
        else
            break;
        end
    end
    for int = 1:size(Top_given_2,2)
        if Top_given_2(i,int)~=-9999
            allTopbin_given(i,j-1+int)  = find(Z==Top_given_2(i,int),1,'last');
            allBasebin_given(i,j-1+int) = find(Z==Base_given_2(i,int),1,'last');
        else
            break;
        end
    end
end
% 5km水平分辨率检测出的地表回波起止位置对应的bin（气溶胶和云完全相同，故直接用云层报告中的地表起止位置即可）
Surface_Top_given_bin            = nan(size(Surface_Top_532_given_1));
Surface_Base_given_bin           = nan(size(Surface_Base_532_given_1));
for i = 1:size(Surface_Top_532_given_1)
    if Surface_Top_532_given_1(i) ~= -9999
        Surface_Top_given_bin(i,1)  = find(Z >= Surface_Top_532_given_1(i),1,'last'); % 这里因为是平均值未必在雷达固定高度序列上能找到唯一对应的值，故找平均值接近的大一点的值代替
        Surface_Base_given_bin(i,1) = find(Z >= Surface_Base_532_given_1(i),1,'last');
    else
        Surface_Top_given_bin(i,1)  = nan;
        Surface_Base_given_bin(i,1) = nan;
    end
end
% 官方5km分辨率检测出的层次
for i=1:size(True_horizontal_resolution_1,1)
    int = 1;
    for j=1:size(True_horizontal_resolution_1,2)
        if True_horizontal_resolution_1(i,j) ==5
            top_right_5km(i,int)                     = Top_given_1(i,j);
            base_right_5km(i,int)                    = Base_given_1(i,j);
            base_extended_5km(i,int)                 = flag_Base_Extend_given_1(i,j);
            topbin_right_5km(i,int)                  = find(Z==top_right_5km(i,int),1,'last');% 得到原始层顶高度对应的距离箱bin信息
            if topbin_right_5km(i,int)>288 && mod(topbin_right_5km(i,int),2)==0
                topbin_right_5km(i,int)=topbin_right_5km(i,int)-1;
            end
            basebin_right_5km(i,int)                 = find(Z==base_right_5km(i,int),1,'last');% 得到原始层底高度对应的距离箱bin信息
            T2_532_5km_right(i,int)                  = T2_532_given_1(i,j);  % 报告中的双向透过率
            T2_Region_532_5km_right(i,2*int-1:2*int) = T2_Region_532_given_1(i,2*j-1:2*j);% 报告中的双向透过率计算区域
            Int_Att_Backscat_532_5km_right(i,int)    = Int_Att_Backscat_532_given_1(i,j);% 报告中的层次衰减散射的积分
            Opacity_Flag_5km(i,int)                  = Opacity_Flag_given_1(i,j);% 报告中的层次透明度
            ExtinctionQC_532_5km(i,int)              = ExtinctionQC_532_given_1(i,j);%消光质量控制描述
            Initial_532_Lidar_Ratio_5km(i,int)       =Initial_532_Lidar_Ratio_given_1(i,j);        %反演时所用的初始532激光雷达比
            Final_532_Lidar_Ratio_5km(i,int)         =Final_532_Lidar_Ratio_given_1(i,j);            %反演的最终激光雷达比：用作与我们反演结果的对比
            Layer_Effective_532_Multiple_Scattering_Factor_5km(i,int) =Layer_Effective_532_Multiple_Scattering_Factor_given_1(i,j);%层有效多重散射因子
            int = int+1;
        end
    end
    for jj = 1:size(True_horizontal_resolution_2,2)
        if True_horizontal_resolution_2(i,jj) == 5
            top_right_5km(i,int)                     = Top_given_2(i,jj);
            base_right_5km(i,int)                    = Base_given_2(i,jj);
            base_extended_5km(i,int)                 = flag_Base_Extend_given_1(i,jj);
            topbin_right_5km(i,int)                  = find(Z==top_right_5km(i,int),1,'last');% 得到原始层顶高度对应的距离箱bin信息
            if topbin_right_5km(i,int)>288 && mod(topbin_right_5km(i,int),2)==0
                topbin_right_5km(i,int)=topbin_right_5km(i,int)-1;
            end
            basebin_right_5km(i,int)                 = find(Z==base_right_5km(i,int),1,'last');% 得到原始层底高度对应的距离箱bin信息
            T2_532_5km_right(i,int)                  = T2_532_given_2(i,jj);  % 报告中的双向透过率
            T2_Region_532_5km_right(i,2*int-1:2*int) = T2_Region_532_given_2(i,2*jj-1:2*jj);% 报告中的双向透过率计算区域
            Int_Att_Backscat_532_5km_right(i,int)    = Int_Att_Backscat_532_given_2(i,jj);% 报告中的层次衰减散射的积分
            Opacity_Flag_5km(i,int)                  = Opacity_Flag_given_2(i,jj);% 报告中的层次透明度
            ExtinctionQC_532_5km(i,int)       = ExtinctionQC_532_given_2(i,jj);
            Initial_532_Lidar_Ratio_5km(i,int)       =Initial_532_Lidar_Ratio_given_2(i,jj);        %反演时所用的初始532激光雷达比
            Final_532_Lidar_Ratio_5km(i,int)         =Final_532_Lidar_Ratio_given_2(i,jj);            %反演的最终激光雷达比：用作与我们反演结果的对比
            Layer_Effective_532_Multiple_Scattering_Factor_5km(i,int) =Layer_Effective_532_Multiple_Scattering_Factor_given_2(i,jj);%层有效多重散射因子
            int = int+1;
        end
    end
end

% 官方20km分辨率检测出的层次
for i=1:size(True_horizontal_resolution_1,1)
    int = 1;
    for j=1:size(True_horizontal_resolution_1,2)
        if True_horizontal_resolution_1(i,j) ==20
            top_right_20km(i,int)                     = Top_given_1(i,j);
            base_right_20km(i,int)                    = Base_given_1(i,j);
            base_extended_20km(i,int)                 = flag_Base_Extend_given_1(i,j);
            topbin_right_20km(i,int)                  = find(Z==top_right_20km(i,int),1,'last');% 得到原始层顶高度对应的距离箱bin信息
            if topbin_right_20km(i,int)>288 && mod(topbin_right_20km(i,int),2)==0
                topbin_right_20km(i,int)=topbin_right_20km(i,int)-1;
            end
            basebin_right_20km(i,int)                 = find(Z==base_right_20km(i,int),1,'last');% 得到原始层底高度对应的距离箱bin信息
            T2_532_20km_right(i,int)                  = T2_532_given_1(i,j);                % 报告中的双向透过率
            T2_Region_532_20km_right(i,2*int-1:2*int) = T2_Region_532_given_1(i,2*j-1:2*j); % 报告中的双向透过率计算区域
            Int_Att_Backscat_532_20km_right(i,int)    = Int_Att_Backscat_532_given_1(i,j);    % 报告中的层次衰减散射的积分
            Opacity_Flag_20km(i,int)                   = Opacity_Flag_given_1(i,j);% 报告中的层次透明度
            ExtinctionQC_532_20km(i,int)       = ExtinctionQC_532_given_1(i,j);
            Initial_532_Lidar_Ratio_20km(i,int)       =Initial_532_Lidar_Ratio_given_1(i,j);        %反演时所用的初始532激光雷达比
            Final_532_Lidar_Ratio_20km(i,int)         =Final_532_Lidar_Ratio_given_1(i,j);            %反演的最终激光雷达比：用作与我们反演结果的对比
            Layer_Effective_532_Multiple_Scattering_Factor_20km(i,int) =Layer_Effective_532_Multiple_Scattering_Factor_given_1(i,j);%层有效多重散射因子
            int = int+1;
        end
    end
    for jj = 1:size(True_horizontal_resolution_2,2)
        if True_horizontal_resolution_2(i,jj) == 20
            top_right_20km(i,int)                     = Top_given_2(i,jj);
            base_right_20km(i,int)                    = Base_given_2(i,jj);
            base_extended_20km(i,int)                 = flag_Base_Extend_given_2(i,jj);
            topbin_right_20km(i,int)                  = find(Z==top_right_20km(i,int),1,'last');% 得到原始层顶高度对应的距离箱bin信息
            if topbin_right_20km(i,int)>288 && mod(topbin_right_20km(i,int),2)==0
                topbin_right_20km(i,int)=topbin_right_20km(i,int)-1;
            end
            basebin_right_20km(i,int)                 = find(Z==base_right_20km(i,int),1,'last');% 得到原始层底高度对应的距离箱bin信息
            T2_532_20km_right(i,int)                  = T2_532_given_2(i,jj);  % 报告中的双向透过率
            T2_Region_532_20km_right(i,2*int-1:2*int) = T2_Region_532_given_2(i,2*jj-1:2*jj);% 报告中的双向透过率计算区域
            Int_Att_Backscat_532_20km_right(i,int)    = Int_Att_Backscat_532_given_2(i,jj);% 报告中的层次衰减散射的积分
            Opacity_Flag_20km(i,int)                  = Opacity_Flag_given_2(i,jj);% 报告中的层次透明度
            ExtinctionQC_532_20km(i,int)       = ExtinctionQC_532_given_2(i,jj);
            Initial_532_Lidar_Ratio_20km(i,int)       =Initial_532_Lidar_Ratio_given_2(i,jj);        %反演时所用的初始532激光雷达比
            Final_532_Lidar_Ratio_20km(i,int)         =Final_532_Lidar_Ratio_given_2(i,jj);            %反演的最终激光雷达比：用作与我们反演结果的对比
            Layer_Effective_532_Multiple_Scattering_Factor_20km(i,int) =Layer_Effective_532_Multiple_Scattering_Factor_given_2(i,jj);%层有效多重散射因子
            int = int+1;
        end
    end
end
% 获取输入数据的长度，并计算循环次数
n_rows = size(True_horizontal_resolution_1, 1);
num_windows = floor(n_rows / 4);

% 预分配输出数组的内存，提高效率
DEM_20km_given = zeros(num_windows, 1);

% 循环计算，使用 mean 并手动忽略 NaN 值
for i = 1:num_windows
    % 1. 提取当前4个点的窗口数据
    window_data = DEM_given(4*i-3 : 4*i);
    
    % 2. 过滤掉窗口数据中的 NaN 值，然后计算平均值
    %    这行代码的效果完全等同于 nanmean(window_data)
    DEM_20km_given(i) = mean(window_data(~isnan(window_data)));
end

[top_right_20km_changednum,Pos]                  = Fun_CheckOfficialProfileNumber(top_right_20km,'base_right_20km',20); % 已转换成合适条数的80km廓线层顶
base_right_20km_changednum                 = Fun_Assign_Profile_According_Position(base_right_20km,Pos,20); % 已转换成合适条数的80km廓线层顶
topbin_right_20km_changednum               = Fun_Assign_Profile_According_Position(topbin_right_20km,Pos,20); % 已转换成合适条数的20km廓线层顶
basebin_right_20km_changednum              = Fun_Assign_Profile_According_Position(basebin_right_20km,Pos,20); % 已转换成合适条数的20km廓线层顶
T2_532_20km_right_changednum               = Fun_Assign_Profile_According_Position(T2_532_20km_right,Pos,20); % 已转换成合适条数的80km廓线层顶
T2_Region_532_20km_right_changednum        = Fun_Assign_Profile_According_Position(T2_Region_532_20km_right,Pos,20); % 已转换成合适条数的80km廓线层顶
Int_Att_Backscat_532_20km_right_changednum = Fun_Assign_Profile_According_Position(Int_Att_Backscat_532_20km_right,Pos,20); % 已转换成合适条数的80km廓线层顶
Opacity_Flag_20km_right_changednum      = Fun_Assign_Profile_According_Position(Opacity_Flag_20km,Pos,20); % 已转换成合适条数的80km廓线层顶
ExtinctionQC_532_20km_right_changednum       =  Fun_Assign_Profile_According_Position(ExtinctionQC_532_20km,Pos,20);
Initial_532_Lidar_Ratio_20km_right_changednum       =  Fun_Assign_Profile_According_Position(Initial_532_Lidar_Ratio_20km,Pos,20);
Final_532_Lidar_Ratio_20km_right_changednum       =  Fun_Assign_Profile_According_Position(Final_532_Lidar_Ratio_20km,Pos,20);
Layer_Effective_532_MultI_Scat_Factor_20km_right_changednum       =  Fun_Assign_Profile_According_Position(Layer_Effective_532_Multiple_Scattering_Factor_20km,Pos,20);

% 官方80km检测出的层次
for i=1:size(True_horizontal_resolution_1,1)
    int = 1;
    for j=1:size(True_horizontal_resolution_1,2)
        if True_horizontal_resolution_1(i,j) ==80
            top_right_80km(i,int)                     = Top_given_1(i,j);
            base_right_80km(i,int)                    = Base_given_1(i,j);
            base_extended_80km(i,int)                 = flag_Base_Extend_given_1(i,j);
            topbin_right_80km(i,int)                  = find(Z==top_right_80km(i,int),1,'last');% 得到原始层顶高度对应的距离箱bin信息
            if topbin_right_80km(i,int)>288 && mod(topbin_right_80km(i,int),2)==0
                topbin_right_80km(i,int)=topbin_right_80km(i,int)-1;
            end
            basebin_right_80km(i,int)                 = find(Z==base_right_80km(i,int),1,'last');% 得到原始层底高度对应的距离箱bin信息
            T2_532_80km_right(i,int)                  = T2_532_given_1(i,j);  % 报告中的双向透过率
            T2_Region_532_80km_right(i,2*int-1:2*int) = T2_Region_532_given_1(i,2*j-1:2*j);% 报告中的双向透过率计算区域
            Int_Att_Backscat_532_80km_right(i,int)    = Int_Att_Backscat_532_given_1(i,j);% 报告中的层次衰减散射的积分
            Opacity_Flag_80km(i,int)                  = Opacity_Flag_given_1(i,j);% 报告中的层次透明度
            ExtinctionQC_532_80km(i,int)       = ExtinctionQC_532_given_1(i,j);
            Initial_532_Lidar_Ratio_80km(i,int)       =Initial_532_Lidar_Ratio_given_1(i,j);        %反演时所用的初始532激光雷达比
            Final_532_Lidar_Ratio_80km(i,int)         =Final_532_Lidar_Ratio_given_1(i,j);            %反演的最终激光雷达比：用作与我们反演结果的对比
            Layer_Effective_532_Multiple_Scattering_Factor_80km(i,int) =Layer_Effective_532_Multiple_Scattering_Factor_given_1(i,j);%层有效多重散射因子           
            int = int+1;
        end
    end
    for jj = 1:size(True_horizontal_resolution_2,2)
        if True_horizontal_resolution_2(i,jj) == 80
            top_right_80km(i,int)                     = Top_given_2(i,jj);
            base_right_80km(i,int)                    = Base_given_2(i,jj);
            base_extended_80km(i,int)                 = flag_Base_Extend_given_2(i,jj);
            topbin_right_80km(i,int)                  = find(Z==top_right_80km(i,int),1,'last');% 得到原始层顶高度对应的距离箱bin信息
            if topbin_right_80km(i,int)>288 && mod(topbin_right_80km(i,int),2)==0
                topbin_right_80km(i,int)=topbin_right_80km(i,int)-1;
            end
            basebin_right_80km(i,int)                 = find(Z==base_right_80km(i,int),1,'last');% 得到原始层底高度对应的距离箱bin信息
            T2_532_80km_right(i,int)                  = T2_532_given_2(i,jj);  % 报告中的双向透过率
            T2_Region_532_80km_right(i,2*int-1:2*int) = T2_Region_532_given_2(i,2*jj-1:2*jj);% 报告中的双向透过率计算区域
            Int_Att_Backscat_532_80km_right(i,int)    = Int_Att_Backscat_532_given_2(i,jj);% 报告中的层次衰减散射的积分
            Opacity_Flag_80km(i,int)                  = Opacity_Flag_given_2(i,jj);% 报告中的层次透明度
            ExtinctionQC_532_80km(i,int)       = ExtinctionQC_532_given_2(i,jj);
            Initial_532_Lidar_Ratio_80km(i,int)       =Initial_532_Lidar_Ratio_given_2(i,jj);        %反演时所用的初始532激光雷达比
            Final_532_Lidar_Ratio_80km(i,int)         =Final_532_Lidar_Ratio_given_2(i,jj);            %反演的最终激光雷达比：用作与我们反演结果的对比
            Layer_Effective_532_Multiple_Scattering_Factor_80km(i,int) =Layer_Effective_532_Multiple_Scattering_Factor_given_2(i,jj);%层有效多重散射因子                    
            int = int+1;
        end
    end
end
% 获取输入数据的长度，并计算循环次数
n_rows = size(True_horizontal_resolution_1, 1);
num_windows = floor(n_rows / 16);

% 预分配输出数组的内存，提高效率
DEM_80km_given = zeros(num_windows, 1);

% 循环计算，使用 mean 并手动忽略 NaN 值
for i = 1:num_windows
    % 1. 提取当前16个点的窗口数据
    window_data = DEM_given(16*i-15 : 16*i);
    
    % 2. 过滤掉窗口数据中的 NaN 值，然后计算平均值
    DEM_80km_given(i) = mean(window_data(~isnan(window_data)));
end

[top_right_80km_changednum,Pos]                  = Fun_CheckOfficialProfileNumber(top_right_80km,'base_right_80km',80); % 已转换成合适条数的80km廓线层顶
base_right_80km_changednum                 = Fun_Assign_Profile_According_Position(base_right_80km,Pos,80); % 已转换成合适条数的80km廓线层顶
topbin_right_80km_changednum               = Fun_Assign_Profile_According_Position(topbin_right_80km,Pos,80); % 已转换成合适条数的80km廓线层顶
basebin_right_80km_changednum              = Fun_Assign_Profile_According_Position(basebin_right_80km,Pos,80); % 已转换成合适条数的80km廓线层顶
T2_532_80km_right_changednum               = Fun_Assign_Profile_According_Position(T2_532_80km_right,Pos,80); % 已转换成合适条数的80km廓线层顶
T2_Region_532_80km_right_changednum        = Fun_Assign_Profile_According_Position(T2_Region_532_80km_right,Pos,80); % 已转换成合适条数的80km廓线层顶
Int_Att_Backscat_532_80km_right_changednum = Fun_Assign_Profile_According_Position(Int_Att_Backscat_532_80km_right,Pos,80); % 已转换成合适条数的80km廓线层顶
Opacity_Flag_80km_right_changednum      = Fun_Assign_Profile_According_Position(Opacity_Flag_80km,Pos,80); % 已转换成合适条数的80km廓线层顶
ExtinctionQC_532_80km_right_changednum       =  Fun_Assign_Profile_According_Position(ExtinctionQC_532_80km,Pos,80);
Initial_532_Lidar_Ratio_80km_right_changednum       =  Fun_Assign_Profile_According_Position(Initial_532_Lidar_Ratio_80km,Pos,80);
Final_532_Lidar_Ratio_80km_right_changednum       =  Fun_Assign_Profile_According_Position(Final_532_Lidar_Ratio_80km,Pos,80);
Layer_Effective_532_MultI_Scat_Factor_80km_right_changednum       =  Fun_Assign_Profile_According_Position(Layer_Effective_532_Multiple_Scattering_Factor_80km,Pos,80);


%% 输出
% 333m
output.top_right_333m_ss                   = top_right_333m_ss;
output.base_right_333m_ss                  = base_right_333m_ss;
output.topbin_right_333m_ss                = topbin_right_333m_ss;
output.basebin_right_333m_ss               = basebin_right_333m_ss;

% 5km
output.top_right_5km                   = top_right_5km;
output.base_right_5km                  = base_right_5km;
output.base_extended_5km               = base_extended_5km;
output.topbin_right_5km                = topbin_right_5km;
output.basebin_right_5km               = basebin_right_5km;
output.T2_532_right_5km                = T2_532_5km_right;
output.T2_Region_532_right_5km         = T2_Region_532_5km_right;
output.Int_Att_Backscat_532_right_5km  = Int_Att_Backscat_532_5km_right;
output.Opacity_Flag_right_5km  = Opacity_Flag_5km;
output.ExtinctionQC_532_right_5km=ExtinctionQC_532_5km;
output.Initial_532_Lidar_Ratio_right_5km =Initial_532_Lidar_Ratio_5km ;
output.Final_532_Lidar_Ratio_right_5km =Final_532_Lidar_Ratio_5km ;
output.Layer_Effective_532_Multiple_Scattering_Factor_right_5km =Layer_Effective_532_Multiple_Scattering_Factor_5km ;

output.Surface_Top_532_given_5km       = Surface_Top_532_given_1;
output.Surface_Base_532_given_5km      = Surface_Base_532_given_1;
output.Surface_Top_532_given_bin_5km   = Surface_Top_given_bin;
output.Surface_Base_532_given_bin_5km  = Surface_Base_given_bin;
output.DEM_given_5km  = DEM_given;

% 20km
output.top_right_20km                  = top_right_20km_changednum;
output.base_right_20km                 = base_right_20km_changednum;
output.topbin_right_20km               = topbin_right_20km_changednum;
output.basebin_right_20km              = basebin_right_20km_changednum;
output.topbin_right_20km_original      = topbin_right_20km;
output.basebin_right_20km_original     = basebin_right_20km;
output.T2_532_right_20km               = T2_532_20km_right_changednum;
output.T2_Region_532_right_20km        = T2_Region_532_20km_right_changednum;
output.Int_Att_Backscat_532_right_20km = Int_Att_Backscat_532_20km_right_changednum;
output.Opacity_Flag_right_20km  = Opacity_Flag_20km_right_changednum;
output.ExtinctionQC_532_right_20km=ExtinctionQC_532_20km_right_changednum;
output.Initial_532_Lidar_Ratio_right_20km =Initial_532_Lidar_Ratio_20km_right_changednum ;
output.Final_532_Lidar_Ratio_right_20km =Final_532_Lidar_Ratio_20km_right_changednum ;
output.Layer_Effective_532_Multiple_Scattering_Factor_right_20km =Layer_Effective_532_MultI_Scat_Factor_20km_right_changednum;
output.DEM_given_20km                  = DEM_20km_given;

% output.top_right_20km                  = top_right_20km;
% output.base_right_20km                 = base_right_20km;
% output.topbin_right_20km               = topbin_right_20km;
% output.basebin_right_20km              = basebin_right_20km;
% output.T2_532_right_20km               = T2_532_20km_right;
% output.T2_Region_532_right_20km        = T2_Region_532_20km_right;
% output.Int_Att_Backscat_532_right_20km = Int_Att_Backscat_532_20km_right;
% output.Opacity_Flag_right_20km  = Opacity_Flag_20km;
% output.ExtinctionQC_532_right_20km=ExtinctionQC_532_20km;
% output.Initial_532_Lidar_Ratio_right_20km =Initial_532_Lidar_Ratio_20km;
% output.Final_532_Lidar_Ratio_right_20km =Final_532_Lidar_Ratio_20km;
% output.Layer_Effective_532_Multiple_Scattering_Factor_right_20km =Layer_Effective_532_Multiple_Scattering_Factor_20km;
% output.DEM_given_20km                  = DEM_20km_given;


% 80km
output.top_right_80km                  = top_right_80km_changednum;
output.base_right_80km                 = base_right_80km_changednum;
output.topbin_right_80km               = topbin_right_80km_changednum;
output.basebin_right_80km              = basebin_right_80km_changednum;
output.topbin_right_80km_original      = topbin_right_80km;
output.basebin_right_80km_original     = basebin_right_80km;
output.T2_532_right_80km               = T2_532_80km_right_changednum;
output.T2_Region_532_right_80km        = T2_Region_532_80km_right_changednum;
output.Int_Att_Backscat_532_right_80km = Int_Att_Backscat_532_80km_right_changednum;
output.Opacity_Flag_right_80km  = Opacity_Flag_80km_right_changednum;
output.ExtinctionQC_532_right_80km=ExtinctionQC_532_80km_right_changednum;
output.Initial_532_Lidar_Ratio_right_80km =Initial_532_Lidar_Ratio_80km_right_changednum;
output.Final_532_Lidar_Ratio_right_80km =Final_532_Lidar_Ratio_80km_right_changednum;
output.Layer_Effective_532_Multiple_Scattering_Factor_right_80km =Layer_Effective_532_MultI_Scat_Factor_80km_right_changednum ;
output.DEM_given_80km                  = DEM_80km_given;

% output.top_right_80km                  = top_right_80km;
% output.base_right_80km                 = base_right_80km;
% output.topbin_right_80km               = topbin_right_80km;
% output.basebin_right_80km              = basebin_right_80km;
% output.T2_532_right_80km               = T2_532_80km_right;
% output.T2_Region_532_right_80km        = T2_Region_532_80km_right;
% output.Int_Att_Backscat_532_right_80km = Int_Att_Backscat_532_80km_right;
% output.Opacity_Flag_right_80km  = Opacity_Flag_80km;
% output.ExtinctionQC_532_right_80km=ExtinctionQC_532_80km;
% output.Initial_532_Lidar_Ratio_right_80km =Initial_532_Lidar_Ratio_80km;
% output.Final_532_Lidar_Ratio_right_80km =Final_532_Lidar_Ratio_80km;
% output.Layer_Effective_532_Multiple_Scattering_Factor_right_80km =Layer_Effective_532_Multiple_Scattering_Factor_80km;
% output.DEM_given_80km                  = DEM_80km_given;
end

