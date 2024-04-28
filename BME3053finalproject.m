clc; clear;
%% Initialize
%columns to extract
cols_ext = [1,27, 28, 30, 31];
%extract file
t = readtable("R1T1.tsv", "FileType","text",'Delimiter', '\t');
%extract start times
labst = t(strcmp(t.Sensor, ''), :);
labst = labst(:, [1,14]);
%extract eyetracking data
eyet = t(strcmp(t.Sensor, 'Eye Tracker'), :);
% %extract colums with pupil position
eyet = eyet(:,cols_ext);
timedif = [];
ylefteye = [];
xlefteye = [];
rows_to_delete = [];
for i = 1:(height(eyet)-1)
    % Check if both current and next rows have numeric values
    if isnumeric(eyet.PupilPositionLeftX_HUCSMm_(i)) && isnumeric(eyet.PupilPositionLeftX_HUCSMm_(i+1))  && ~isnan(eyet.PupilPositionLeftX_HUCSMm_(i)) && ~isnan(eyet.PupilPositionLeftX_HUCSMm_(i+1))
        timesi = eyet{i+1,1} - eyet{i,1};
        timedif = [timedif; timesi];
        xpositioni = abs(eyet{i+1,2} - eyet{i,2});
        xlefteye = [xlefteye; xpositioni];
        ypositioni = abs(eyet{i+1,3} - eyet{i,3});
        ylefteye = [ylefteye; ypositioni];
    else
        % Store index of row to delete
        rows_to_delete = [rows_to_delete, i];
    end
end
% Delete rows from eyet
eyet(rows_to_delete, :) = [];
% Form the final data
alldata = horzcat(timedif, xlefteye, ylefteye);
velocityx = alldata(:,2)./alldata(:,1);
velocityy = alldata(:,3)./alldata(:,1);
alldata = horzcat(timedif, xlefteye, ylefteye, velocityx, velocityy);
alldata_table = array2table(alldata, 'VariableNames', {'Time Difference (ms)', 'yvelocity Position Difference (um)', 'Y Position Difference (um)', 'yvelocity Velocity (mm/s)', 'Y Velocity (mm/s)'});
velocity_magnitude = sqrt(velocityx.^2 + velocityy.^2);
alldata_table.Overall_Velocity_Magnitude = velocity_magnitude;
blinks = table2array(alldata_table(:, 5));
x = 1:length(blinks);
saccades = table2array(alldata_table(:,6));
plot(x,saccades)
hold on
plot(x,blinks)
xlim([0 1000])
legend('Saccades', 'Blinks')
title('Saccades and Blinks')
xlabel('Time(ms)')
ylabel('Velocity')
percentile_85 = prctile(saccades, 85);
percentile_90 = prctile(saccades, 90);
% Define parameters for peak detection
minPeakDistance_blink = 100;
minPeakWidth_blink = 10; % Scale minimum peak width
maxPeakWidth_blink = 320; % Scale maximum peak width
minProminence_blink = percentile_85;
% Define parameters for saccade peak detection
minPeakDistance_saccade = 100;
minPeakWidth_saccade = 4; % Scale minimum peak width
maxPeakWidth_saccade = 40; % Scale maximum peak width
minProminence_saccade = percentile_90;
% Detect peaks for blinks and saccades
[peaks_blink, locs_blink, widths_blink, proms_blink] = findpeaks(blinks, ...
    'MinPeakDistance', minPeakDistance_blink, ...
    'MinPeakWidth', minPeakWidth_blink, ...
    'MaxPeakWidth', maxPeakWidth_blink, ...
    'MinPeakProminence', minProminence_blink);
% Detect peaks for saccades
[peaks_saccade, locs_saccade, widths_saccade, proms_saccade] = findpeaks(saccades, ...
    'MinPeakDistance', minPeakDistance_saccade, ...
    'MinPeakWidth', minPeakWidth_saccade, ...
    'MaxPeakWidth', maxPeakWidth_saccade, ...
    'MinPeakProminence', minProminence_saccade);
% Create logical index to identify saccade peaks too close to blinks
exclude_index = false(size(locs_saccade));
for j = 1:numel(locs_blink)
    blink_time = locs_blink(j);
    exclude_index = exclude_index | (abs(locs_saccade - blink_time) <= 120);
end
% Filter out saccade peaks that are too close to blinks
peaks_saccade_filtered = peaks_saccade(~exclude_index);
locs_saccade_filtered = locs_saccade(~exclude_index);
% Plot saccades with filtered peaks
% Plot saccades with filtered peaks
figure;
plot(x, saccades);
hold on;
scatter(x(locs_saccade_filtered), peaks_saccade_filtered, 'ro', 'LineWidth', 2); % Red circles on saccade peaks
scatter(x(locs_blink), peaks_blink, 'go', 'LineWidth', 2); % Green circles on blink peaks
hold off;
title('Detection of Saccades and Blinks');
ylabel('Velocity');
xlabel('Time');
legend('Data', 'Filtered Saccade Peaks', 'Blink Peaks');
xlim([0 2250])
















