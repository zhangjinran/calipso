function altitudes = get_vfm_altitudes()
    % 功能：获取VFM垂直格点对应的高度数组
    % 输出：altitudes - 545×1向量，对应VFM的545个垂直格点高度（km）
    % 结构：
    %   1-55:   20-30 km (55个格点，从30km向下到20km)
    %   56-255: 8-20 km (200个格点，从20km向下到8km)
    %   256-545: 0-8 km (290个格点，从8km向下到0km)
    
    % 20-30km: 55个格点，从30km向下到20km
    alt1 = linspace(30, 20, 55);
    
    % 8-20km: 200个格点，从20km向下到8km
    alt2 = linspace(20, 8, 200);
    
    % 0-8km: 290个格点，从8km向下到0km
    alt3 = linspace(8, 0, 290);
    
    % 合并
    altitudes = [alt1, alt2, alt3];
end
