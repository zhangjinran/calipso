function [Block_Feature_AL] = Fun_Make_ALay_Block(ALay_05km)

        L2_ALayer = Fun_get_over_5km_resolution_offical_inf_cl_For_Aerosol(ALay_05km);
        topbin_right_5km_AL = L2_ALayer.topbin_right_5km_AL;
        basebin_right_5km_AL = L2_ALayer.basebin_right_5km_AL;
        topbin_right_20km_AL = L2_ALayer.topbin_right_20km_AL;
        basebin_right_20km_AL = L2_ALayer.basebin_right_20km_AL;
        topbin_right_80km_AL = L2_ALayer.topbin_right_80km_AL;
        basebin_right_80km_AL = L2_ALayer.basebin_right_80km_AL;
        topbin_cell_AL = {topbin_right_5km_AL, topbin_right_20km_AL, topbin_right_80km_AL};
        basebin_cell_AL = {basebin_right_5km_AL, basebin_right_20km_AL, basebin_right_80km_AL};
        %层属性 读取Feature Classification Flag参数
        %找到确定气溶胶类型的bit位数
        AL_5km_Feature_Classification_Flags = L2_ALayer.AL_5km_Feature_Classification_Flags;
        Tropospheric_Type_Cur = AL_5km_Feature_Classification_Flags;
        umask_CA = uint16(7);
        Tropospheric_Type_Cur = uint16(Tropospheric_Type_Cur);
        Tropospheric_Type_Cur = bitand(umask_CA,Tropospheric_Type_Cur);%bin2dec(CL_Flags_F(:,6:7));        %
        Tropospheric_Type_Cur = double(Tropospheric_Type_Cur);
        Tropospheric_Type_5km = Tropospheric_Type_Cur;
        %5km
        umask = uint16(7);
        Aerosol_Type_Cur = AL_5km_Feature_Classification_Flags;
        Aerosol_Type_Cur = uint16(Aerosol_Type_Cur);
        Aerosol_Type_Cur = bitshift(Aerosol_Type_Cur,-9);%dec2bin(CL_Flags_F,16);
        Aerosol_Type_Cur = bitand(umask,Aerosol_Type_Cur);%bin2dec(CL_Flags_F(:,10:12));        %
        Aerosol_Type_Cur = double(Aerosol_Type_Cur);
        Aerosol_Type_5km = Aerosol_Type_Cur;
        %20km
        AL_20km_Feature_Classification_Flags = L2_ALayer.AL_20km_Feature_Classification_Flags;
        Tropospheric_Type_Cur = AL_20km_Feature_Classification_Flags;
        umask_CA = uint16(7);
        Tropospheric_Type_Cur = uint16(Tropospheric_Type_Cur);
        Tropospheric_Type_Cur = bitand(umask_CA,Tropospheric_Type_Cur);%bin2dec(CL_Flags_F(:,6:7));        %
        Tropospheric_Type_Cur = double(Tropospheric_Type_Cur);
        Tropospheric_Type_20km = Tropospheric_Type_Cur;
        %20km
        umask = uint16(7);
        Aerosol_Type_Cur = AL_20km_Feature_Classification_Flags;
        Aerosol_Type_Cur = uint16(Aerosol_Type_Cur);
        Aerosol_Type_Cur = bitshift(Aerosol_Type_Cur,-9);%dec2bin(CL_Flags_F,16);
        Aerosol_Type_Cur = bitand(umask,Aerosol_Type_Cur);%bin2dec(CL_Flags_F(:,10:12));        %
        Aerosol_Type_Cur = double(Aerosol_Type_Cur);
        Aerosol_Type_20km = Aerosol_Type_Cur;

        %80km
        AL_80km_Feature_Classification_Flags = L2_ALayer.AL_80km_Feature_Classification_Flags;
        Tropospheric_Type_Cur = AL_80km_Feature_Classification_Flags;
        umask_CA = uint16(7);
        Tropospheric_Type_Cur = uint16(Tropospheric_Type_Cur);
        Tropospheric_Type_Cur = bitand(umask_CA,Tropospheric_Type_Cur);%bin2dec(CL_Flags_F(:,6:7));        %
        Tropospheric_Type_Cur = double(Tropospheric_Type_Cur);
        Tropospheric_Type_80km = Tropospheric_Type_Cur;
        %80km
        umask = uint16(7);
        Aerosol_Type_Cur = AL_80km_Feature_Classification_Flags;
        Aerosol_Type_Cur = uint16(Aerosol_Type_Cur);
        Aerosol_Type_Cur = bitshift(Aerosol_Type_Cur,-9);%dec2bin(CL_Flags_F,16);
        Aerosol_Type_Cur = bitand(umask,Aerosol_Type_Cur);%bin2dec(CL_Flags_F(:,10:12));        %
        Aerosol_Type_Cur = double(Aerosol_Type_Cur);
        Aerosol_Type_80km = Aerosol_Type_Cur;

        %气溶胶子类型还需要区分对流层、平流层
        Classification_Result_Cell = {Aerosol_Type_5km,Aerosol_Type_20km,Aerosol_Type_80km,...
            Tropospheric_Type_5km,Tropospheric_Type_20km,Tropospheric_Type_80km};
        Block_Feature_AL = Fun_Make_Block(topbin_cell_AL,basebin_cell_AL,Classification_Result_Cell,'Aerosol');
        