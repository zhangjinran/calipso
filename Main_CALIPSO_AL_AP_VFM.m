clc; clear; close all;
pause(0)

% ====================== Image output settings ======================
global SAVE_PATH IMAGE_SAVE_PATH
subfolder = 'testfreq';  % Change this to select the output folder
project_root = fileparts(mfilename('fullpath'));
SAVE_PATH = fullfile(project_root, 'result', subfolder);
try
    diary('off');  % Release a previous debug log if the last run stopped early.
catch
end
if exist(SAVE_PATH, 'dir')
    [removed_output_dir, remove_msg] = rmdir(SAVE_PATH, 's');
    if ~removed_output_dir
        warning('Could not remove output folder "%s": %s', SAVE_PATH, remove_msg);
        subfolder = sprintf('%s_%s', subfolder, datestr(now, 'yyyymmdd_HHMMSS'));
        SAVE_PATH = fullfile(project_root, 'result', subfolder);
    end
end
if ~exist(SAVE_PATH, 'dir')
    mkdir(SAVE_PATH);
end
IMAGE_SAVE_PATH = fullfile(SAVE_PATH, 'images');
BLOCK_SAVE_PATH = fullfile(SAVE_PATH, 'blocks');
LOG_SAVE_PATH = fullfile(SAVE_PATH, 'logs');
if ~exist(IMAGE_SAVE_PATH, 'dir'), mkdir(IMAGE_SAVE_PATH); end
if ~exist(BLOCK_SAVE_PATH, 'dir'), mkdir(BLOCK_SAVE_PATH); end
if ~exist(LOG_SAVE_PATH, 'dir'), mkdir(LOG_SAVE_PATH); end
fprintf('Images will be saved to: %s\n', IMAGE_SAVE_PATH);
frequency_log_path = fullfile(LOG_SAVE_PATH, 'frequency_debug.txt');
diary(frequency_log_path);
fprintf('Frequency debug log: %s\n', frequency_log_path);
% ==========================================================
%% Global variables
global Lidar_Data_Altitudes
global Number_of_particles;
global Day_Night_Flag;
global fileTime
global Z
%% Data loading
%% Find files matching date, lat/lon, and day/night criteria
addpath(genpath('F:\CALIPSO_Code_new\'))
file_path = 'Z:\';
year_start = 2007; year_end = 2008;
year_select = year_start:year_end;  % Year folder selection; supports multiple years
date_lim             = [20070101000000,20070102000000];% date limit (start/end), note: if month-day-hour-min-sec omitted, defaults to 0101000000
day_night_flag       = 'all';                         % day/night/all
lon_lim              =  [70,135];                  % longitude limits [start, end]
lat_lim              =   [15,55] ;  % latitude limits [start, end]
[aod_block, cnt_block, lon_centers, lat_centers, lon_edges, lat_edges]=create_empty_aod_grid(lon_lim,lat_lim);
[aod_classified_block, cnt_classified_block, ~, ~, ~, ~]=create_empty_classified_aod_grid(lon_lim,lat_lim);
[freq_block, freq_cnt_block, ~, ~, ~, ~]=create_empty_freq_grid(lon_lim,lat_lim);

nlat = length(lat_centers);
nlon = length(lon_centers);
% 1. Read China boundary shapefile
china_shp = shaperead(fullfile(fileparts(mfilename('fullpath')), char([20013 21326 20154 27665 20849 21644 22269]), [char([20013 21326 20154 27665 20849 21644 22269]) '.shp']));

% 2. Initialize time-series structures for trend analysis (block based)
ts_aod = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges);       % AOD time series
ts_aod_total = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges);  % Total classified AOD time series
ts_aod_anthro = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges); % Anthropogenic classified AOD time series
ts_aod_natural = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges); % Natural classified AOD time series
ts_freq_total = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges); % Total aerosol frequency time series
ts_freq_anthro = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges); % Anthropogenic aerosol frequency time series
ts_freq_natural = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges); % Natural aerosol frequency time series

% Time interval tracking
interval_type = 'day';  % Supported values: 'month', 'quarter', 'year', 'week', 'day'
last_interval = '';
freq_debug_enabled = true;  % Enable frequency diagnostics
fast_debug_mode = true;       % Use fast file selection, but process all selected files
debug_stop_on_error = false;  % Keep processing so final frequency plots are still produced
debug_frequency_plots_only = true;
debug_frequency_plot_categories = {'Total', 'Anthropogenic'};
skip_final_plots = debug_frequency_plots_only;  % Skip spatial frequency maps in debug mode
skip_trend_analysis = false;    % Keep time-series trend output available in debug mode

% Interval accumulation variables, independent from the final plotting grids
[aod_interval, cnt_interval, ~, ~, ~, ~] = create_empty_aod_grid(lon_lim, lat_lim);
[aod_classified_interval, cnt_classified_interval, ~, ~, ~, ~] = create_empty_classified_aod_grid(lon_lim, lat_lim);
[freq_interval, freq_cnt_interval, ~, ~, ~, ~] = create_empty_freq_grid(lon_lim, lat_lim);

% Failed-file statistics
failed_count = 0;
failed_files = {};

% 2. Plot initial empty maps
% plot_aod_block(aod_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp);
% plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Total');
% plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Anthropogenic');
% plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Natural');
% plot_classified_aod_block(aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Total');
% plot_classified_aod_block(aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Anthropogenic');
% plot_classified_aod_block(aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Natural');


%Output list of files meeting criteria
[outputselect,int]= Fun_output_a_list_of_criteria_1(file_path,year_select,date_lim,day_night_flag,lon_lim,lat_lim);

if isempty(outputselect)
    error("The outputselect is empty!");
end

files_to_process = length(outputselect);
if fast_debug_mode
    fprintf("FAST DEBUG MODE: processing all %d selected files; frequency plots only.\n", ...
        files_to_process);
end


if int > 0
    % ====================== Performance Profiler ======================
    if ~fast_debug_mode
        profile on;
    end
    total_start = tic;
    % ====================================================================
    
    %%%%%
    fprintf("Total files: %.2d",length(outputselect))
    for iii = 1:files_to_process %
        % ====================== Single file timer ======================
        fprintf('\n==================== Processing file %d ====================\n', iii);
        file_start = tic;
        
        File_select = outputselect{iii};
        if(size(File_select,2)<3)
            continue;
        end
        profile_start_and_length = [nan,nan];
        flag = 0;
        mycell = cell(1,10);
        lat_lim_temp              =   lat_lim ; %reset in each loop, otherwise modified                
        
        % ====================== Data reading timer ======================
        read_start = tic;
        try
        for j = 1:size(File_select,2)
            filename  = [File_select(j).filePath,'\',File_select(j).name];
            
            if strcmp(File_select(j).type,'L1')
               
                lzx = find(~cellfun(@isempty, mycell),1,'first');
               
                if ~isempty(lzx)
                    [mycell{File_select(j).Field_priority}] = Fun_getCALIPSO_L1(filename,mycell{lzx}.Lat(1,1),mycell{lzx}.Lat(end,3));
                else
                    [mycell{File_select(j).Field_priority}] = Fun_getCALIPSO_L1(filename,min(lat_lim),max(lat_lim));
                end
                flag = File_select(j).Field_priority;
            else
                if flag ~= 0
                    switch char(File_select(j).type)
                        case  'VFM'
                            a = 7;
                        case  'CLay_01km'
                            a = 1;
                        otherwise
                            a = 0;
                    end
                    lat_lim_temp = [mycell{flag}.Lat(1+a),mycell{flag}.Lat(end-a)];
                end
                L2Temp = Fun_getCALIPSO_L2(filename,lat_lim_temp,profile_start_and_length);
                if ~isempty(L2Temp)
                    mycell{File_select(j).Field_priority} = L2Temp; 
                end
                switch char(File_select(j).type)
                    case  'VFM'
                    otherwise
                        if ~isempty(File_select(j).Field_priority)
                            profile_start_and_length = [mycell{File_select(j).Field_priority}.profile_start_end(1),...
                                mycell{File_select(j).Field_priority}.profile_number];
                        end
                end
            end
        end
        read_time = toc(read_start);
        fprintf('Data reading time: %.2f sec\n', read_time);
        

        %% Variable assignment
        
        %%%Assign variables using loop
        data_name={'ALay_05km','CLay_05km','Mlay_05km',' L2_CPro','L2_APro','L1','VFM',' CLay_01km','MLay_333m'};
        
        % ====================== Variable assignment timer ======================
        assign_start = tic;
        for ii =1:length(data_name)
           eval([data_name{ii},'=struct();'])
           if ~isempty(mycell{ii})
               eval([data_name{ii},'=mycell{ii};']);
           end
        end
        assign_time = toc(assign_start);
        fprintf('Variable assignment time: %.2f sec\n', assign_time);

        %% Parameters

        %%% Extract time information
        indTime              = strfind(filename,'.');
        fileTime            = filename(indTime(1):indTime(2));
        indTime1    = strfind(fileTime,'T');              % Locate two dots in filename (content between dots is time info)
        fileTime1  = fileTime(2:end-1);   % Extract time info from filename
      

        
        lims = [1,length(VFM.Lat)];%VFM.profile_start_end;
        type = 'type';% 'type','all','qa','phase','phaseqa','tropospheric aerosol','cloud','stratospheric aerosol','subtype','typeqa','averaging'
        
        % ====================== Surface mask calculation timer ======================
        mask_start = tic;
        surface_mask=Select_surface_From_VFM(VFM.Feature_Classification_Flags,lims,type);
        mask_time = toc(mask_start);
        fprintf('Surface mask calculation time: %.2f sec\n', mask_time);

        % ====================== AOD calculation timer ======================
        aod_start = tic;
        [aod_block, cnt_block]=calculate_aod(surface_mask,ALay_05km,aod_block,cnt_block,lon_edges,lat_edges);
        aod_time = toc(aod_start);
        fprintf('AOD calculation time: %.2f sec\n', aod_time);

        % ====================== Aerosol frequency statistics ======================
        freq_start = tic;
        freq_debug = struct('enabled', freq_debug_enabled, ...
    'label', sprintf('global file %d', iii), 'source', filename);
[freq_block, freq_cnt_block] = calculate_freq(...
    VFM, ALay_05km, surface_mask, freq_block, freq_cnt_block, ...
    lon_edges, lat_edges, freq_debug);
        freq_time = toc(freq_start);
        fprintf('Aerosol frequency statistics time: %.2f sec\n', freq_time);
        
        % ====================== Classified AOD calculation ======================
        if ~isempty(fieldnames(L2_APro)) && ~isempty(fieldnames(ALay_05km))
            class_aod_start = tic;
            [aod_classified_block, cnt_classified_block] = calculate_classified_aod(...
                VFM, L2_APro, ALay_05km, surface_mask, ...
                aod_classified_block, cnt_classified_block, ...
                lon_edges, lat_edges);
            class_aod_time = toc(class_aod_start);
            fprintf('Classified AOD calculation time: %.2f sec\n', class_aod_time);
        end

% ====================== Interval accumulation using calculate functions ======================
        [aod_interval, cnt_interval] = calculate_aod(surface_mask, ALay_05km, aod_interval, cnt_interval, lon_edges, lat_edges);
        freq_debug.label = sprintf('interval file %d', iii);
[freq_interval, freq_cnt_interval] = calculate_freq(...
    VFM, ALay_05km, surface_mask, freq_interval, freq_cnt_interval, ...
    lon_edges, lat_edges, freq_debug);
        
% Classified AOD interval accumulation
        if ~isempty(fieldnames(L2_APro)) && ~isempty(fieldnames(ALay_05km))
            [aod_classified_interval, cnt_classified_interval] = calculate_classified_aod(...
                VFM, L2_APro, ALay_05km, surface_mask, ...
                aod_classified_interval, cnt_classified_interval, ...
                lon_edges, lat_edges);
        end
        
% ====================== Collect time interval data =======================
        [datetime_val, ~, ~] = get_time_from_filename(filename);
        if ~isnat(datetime_val)
            [is_new_interval, interval_key] = check_time_interval(datetime_val, last_interval, interval_type);
            
            if is_new_interval && ~isempty(last_interval)
% Entering a new interval
                fprintf('Entering new %s: %s -> %s\n', interval_type, last_interval, interval_key);
                
               
                
% Timestamp for the end of the previous interval
                last_interval_date = get_interval_end_date(last_interval, interval_type);
                
% Append interval data. AOD is a mean; frequency is normalized below.
                ts_aod = ts_append_block(ts_aod, last_interval_date, aod_interval);
                ts_aod_total = ts_append_block(ts_aod_total, last_interval_date, aod_classified_interval(:,:,1));
                ts_aod_anthro = ts_append_block(ts_aod_anthro, last_interval_date, aod_classified_interval(:,:,2));
                ts_aod_natural = ts_append_block(ts_aod_natural, last_interval_date, aod_classified_interval(:,:,3));
                freq_interval_result = calculate_freq_final(freq_interval, freq_cnt_interval);
                ts_freq_total = ts_append_block(ts_freq_total, last_interval_date, freq_interval_result(:,:,1));
                ts_freq_anthro = ts_append_block(ts_freq_anthro, last_interval_date, freq_interval_result(:,:,2));
                ts_freq_natural = ts_append_block(ts_freq_natural, last_interval_date, freq_interval_result(:,:,3));
                
% Reset interval accumulators
                [aod_interval, cnt_interval, ~, ~, ~, ~] = create_empty_aod_grid(lon_lim, lat_lim);
                [aod_classified_interval, cnt_classified_interval, ~, ~, ~, ~] = create_empty_classified_aod_grid(lon_lim, lat_lim);
                [freq_interval, freq_cnt_interval, ~, ~, ~, ~] = create_empty_freq_grid(lon_lim, lat_lim);
            end
            
% Update interval key
            last_interval = interval_key;
        end

        % ====================== Single file total timer ======================
        total_file_time = toc(file_start);
        fprintf('Single file total time: %.2f sec\n', total_file_time);
        fprintf('=====================================================\n');
        
        
        % ====================== Performance summary ======================
        if iii == files_to_process
            fprintf('\n============== All files processing complete ==============\n');
            fprintf('Total processing time: %.2f sec\n', toc(total_start));
            % Turn off profiler and open viewer
            profile off;
            if ~fast_debug_mode
                profile viewer;
            end
        end
        
        continue;%temporarily added
        
        
        
        
        if ~isempty(fieldnames(L2_APro))&&~isempty(fieldnames(ALay_05km))
            Lidar_Data_Altitudes = L2_APro.Altitudes_Profile;
            Z=ALay_05km.lidar_Data_Altitude;
            % Create dictionary
            L2_APro_data_dict = dictionary;
            
            
            % 532nm total attenuated backscatter
            L2_APro_data_dict("TAB_532")            = {L2_APro.Total_Backscatter_Coefficient_532};             
            
            % 532nm perpendicular attenuated backscatter
            L2_APro_data_dict("VAB_532")            = {L2_APro.Perpendicular_Backscatter_Coefficient_532};     
            
            % 1064nm total attenuated backscatter
            L2_APro_data_dict("AB_1064")            = {L2_APro.Backscatter_Coefficient_1064};                   
            
            
            Number_of_particles   = L2_APro.profile_number;   % Number of profiles
            Latitude = ALay_05km.Lat;
            Longitude = ALay_05km.Lon;
            Day_Night_Flag = "all";%day/night
            %% Average to 5km resolution data
           
            %%%
         
            % Get layer positions from L2 product
            output_above_5km_M = Fun_get_over_5km_resolution_offical_inf_cl_For_Aerosol(ALay_05km);
            %5km 20km 80km
            topbin_right_5km           = output_above_5km_M.topbin_right_5km_AL;
            basebin_right_5km          = output_above_5km_M.basebin_right_5km_AL;
            topbin_right_20km           = output_above_5km_M.topbin_right_20km_AL;
            basebin_right_20km          = output_above_5km_M.basebin_right_20km_AL;
            topbin_right_80km           = output_above_5km_M.topbin_right_80km_AL;
            basebin_right_80km          = output_above_5km_M.basebin_right_80km_AL;
            topbin_cell = {topbin_right_5km,topbin_right_20km,topbin_right_80km};
            basebin_cell = {basebin_right_5km,basebin_right_20km,basebin_right_80km};
            %%%
            %This only uses ALay data to draw the contour of the profile, not detailed data.
            
            %%% Plotting related to L1, AL and AP
            %% Layer detection results plotting, mainly profile results
           % 1. Get all dict keys (rename to avoid conflicts)
            dict_keys = keys(L2_APro_data_dict);
            
            % 2. Iterate through each key
            for i = 1:length(dict_keys)
                % Get current key
                key = dict_keys{i};   % Use { } here!
                
                % Get data (dict stores cells, so use {}{1})
                data = L2_APro_data_dict{key};
    
                % Replace underscores with spaces for plot title
                title_name = replace(key, '_', ' ');
                
                % Plot
                %Fun_Layer_Plot(Latitude, Lidar_Data_Altitudes, data', topbin_cell, basebin_cell,title_name);

                 %% Display profile info, click on figure to show corresponding TAB info
                %This function plots TAB pseudo-color map with colorbar matching CALIPSO
                %Fun_Layer_Plot_Profile(Latitude,Lidar_Data_Altitudes,data',topbin_cell,basebin_cell,title_name);
               
            end
             
           
        end  
      
          
        
        
        
        
       

        

        
        %%%%%%%%%%
        
        %% Official aerosol subtype plotting
        Block_Feature_AL=Fun_Make_ALay_Block(ALay_05km);
        
        Lat_5km=ALay_05km.Lat;
        %Cloud_Phase_plot(Block_Feature_AL,'Aerosol',Lat(:,2),12);
        lims = [1,length(Lat_5km)];
        Lidar_Data_Altitudes=ALay_05km.lidar_Data_Altitude;
        Cloud_Phase_plot(Block_Feature_AL,lims,'Aerosol',Lat_5km(:,2),9,fileTime1);

        %%%VFM related plotting
        %% VFM Plotting
        lims = [1,length(VFM.Lat)];%VFM.profile_start_end;
        type = 'type';% 'type','all','qa','phase','phaseqa','tropospheric aerosol','cloud','stratospheric aerosol','subtype','typeqa','averaging'
        lat=VFM.Lat;
        [block,TypeText]=vfm_plot_V1_1(VFM.Feature_Classification_Flags,lims,type,lat(lims(1):lims(2)),fileTime1,File_select);
        %%%
        

     catch ME
% Print the error details and continue with the next file
            fprintf(2, '  Error: %s\n', ME.message);
            for stack_idx = 1:numel(ME.stack)
                fprintf(2, '    at %s (line %d)\n', ...
                    ME.stack(stack_idx).name, ME.stack(stack_idx).line);
            end
% Plotting is handled once after the loop
            % plot_aod_block(aod_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp);
            % plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Total');
            % plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Anthropogenic');
            % plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Natural');
            % plot_classified_aod_block(aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Total');
            % plot_classified_aod_block(aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Anthropogenic');
            % plot_classified_aod_block(aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Natural');
         if debug_stop_on_error
             rethrow(ME)
         end
         failed_count = failed_count + 1;
         failed_files{end+1} = filename;
         fprintf("Failed file: %s\n", filename);
                continue;
        end
        end % <-- End of for iii = ... loop
end % <-- End of if int > 0

if ~skip_final_plots
    if debug_frequency_plots_only
        for plot_idx = 1:numel(debug_frequency_plot_categories)
            plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, ...
                lon_edges, lat_edges, china_shp, debug_frequency_plot_categories{plot_idx});
        end
    else
        plot_aod_block(aod_block,lon_centers,lat_centers,lon_edges,lat_edges,china_shp)
        plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Total');
        plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Anthropogenic');
        plot_freq_block(freq_block, freq_cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Natural');
        plot_classified_aod_block(aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Total');
        plot_classified_aod_block(aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Anthropogenic');
        plot_classified_aod_block(aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, 'Natural');
    end
end

% ====================== Process final interval =======================
if  any(cnt_interval(:) > 0)
    fprintf('Processing final %s: %s\n', interval_type, last_interval);
    
% Timestamp
    last_interval_date = get_interval_end_date(last_interval, interval_type);
    
% Append final interval data
    ts_aod = ts_append_block(ts_aod, last_interval_date, aod_interval);
    ts_aod_total = ts_append_block(ts_aod_total, last_interval_date, aod_classified_interval(:,:,1));
    ts_aod_anthro = ts_append_block(ts_aod_anthro, last_interval_date, aod_classified_interval(:,:,2));
    ts_aod_natural = ts_append_block(ts_aod_natural, last_interval_date, aod_classified_interval(:,:,3));
    freq_interval_result = calculate_freq_final(freq_interval, freq_cnt_interval);
    ts_freq_total = ts_append_block(ts_freq_total, last_interval_date, freq_interval_result(:,:,1));
    ts_freq_anthro = ts_append_block(ts_freq_anthro, last_interval_date, freq_interval_result(:,:,2));
    ts_freq_natural = ts_append_block(ts_freq_natural, last_interval_date, freq_interval_result(:,:,3));
end

if ~skip_trend_analysis
% ====================== Trend analysis (block based) =======================
 if debug_frequency_plots_only
     ts_run_analysis(ts_freq_total, china_shp, 'Total Aerosol Frequency', false);
 else
     ts_run_analysis(ts_aod, china_shp, 'AOD');
     ts_run_analysis(ts_aod_total, china_shp, 'Total Classified AOD');
     ts_run_analysis(ts_aod_anthro, china_shp, 'Anthropogenic Classified AOD');
     ts_run_analysis(ts_aod_natural, china_shp, 'Natural Classified AOD');
     ts_run_analysis(ts_freq_total, china_shp, 'Total Aerosol Frequency');
     ts_run_analysis(ts_freq_anthro, china_shp, 'Anthropogenic Aerosol Frequency');
     ts_run_analysis(ts_freq_natural, china_shp, 'Natural Aerosol Frequency');
 end

end

% ====================== Failed-file summary =======================
fprintf('\n============== Failed-file summary ==============\n');
fprintf('Total files: %d\n', length(outputselect));
fprintf('Successfully processed: %d\n', length(outputselect) - failed_count);
fprintf('Failed files: %d\n', failed_count);
if failed_count > 0
    fprintf('Failed-file list:\n');
    for i = 1:failed_count
        fprintf('  %d. %s\n', i, failed_files{i});
    end
end
fprintf('===========================================\n');

% ====================== Final block snapshot =======================
% Save final blocks once, after all processing and trend calculations.
blocks_mat_path = fullfile(BLOCK_SAVE_PATH, 'final_blocks.mat');
blocks_metadata = struct('created_at', datetime('now'), 'project_root', project_root, ...
    'interval_type', interval_type, 'year_select', year_select, 'date_lim', date_lim, ...
    'lon_lim', lon_lim, 'lat_lim', lat_lim, ...
    'total_selected_files', length(outputselect), 'failed_count', failed_count, ...
    'failed_files', {failed_files}, 'output_folder', SAVE_PATH);
try
    save(blocks_mat_path, 'aod_block', 'cnt_block', 'aod_classified_block', 'cnt_classified_block', ...
        'freq_block', 'freq_cnt_block', 'aod_interval', 'cnt_interval', ...
        'aod_classified_interval', 'cnt_classified_interval', 'freq_interval', 'freq_cnt_interval', ...
        'lon_centers', 'lat_centers', 'lon_edges', 'lat_edges', ...
        'ts_aod', 'ts_aod_total', 'ts_aod_anthro', 'ts_aod_natural', ...
        'ts_freq_total', 'ts_freq_anthro', 'ts_freq_natural', 'blocks_metadata', '-v7.3');
    if ~isfile(blocks_mat_path), error('MAT file was not found after save.'); end
    fprintf('Final blocks saved to: %s\n', blocks_mat_path);
catch ME
    fprintf(2, 'Final block save failed: %s\n', ME.message);
end
diary('off');




