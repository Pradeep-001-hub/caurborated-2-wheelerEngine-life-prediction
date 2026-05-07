%% ENGINE HEALTH PREDICTION DEVICE - MATLAB SIMULATION
% LSU 4.9 Wideband Lambda Sensor + Health Scoring Algorithm
% Copy and paste into MATLAB, run directly

clear all; close all; clc;

%% ==================== CONFIGURATION ====================

% Health Score Weighting
WEIGHT_KNOCKING = 0.45;           % Knocking detection (45%)
WEIGHT_COMBUSTION = 0.35;         % Combustion quality (35%)
WEIGHT_TREND = 0.20;              % Trend degradation (20%)

% LSU 4.9 Sensor Parameters
LSU_MIN_VOLTAGE = 0.5;            % V @ AFR 10 (rich)
LSU_MAX_VOLTAGE = 4.5;            % V @ AFR 20 (lean)
LSU_LAMBDA_MIN = 0.68;            % Lambda @ 10 AFR
LSU_LAMBDA_MAX = 1.36;            % Lambda @ 20 AFR
ADC_RESOLUTION = 4095;            % ESP32 12-bit ADC
ADC_MAX_VOLTAGE = 3.3;            % ESP32 ADC max

% Knocking Detection Thresholds
KNOCK_LAMBDA_THRESHOLD = 0.15;    % Lambda oscillation amplitude
KNOCK_SENSITIVITY = 0.08;         % Detect knocking if variance > this

% Combustion Quality Thresholds
LAMBDA_TARGET = 1.0;              % Stoichiometric
COMBUSTION_QUALITY_THRESHOLD = 0.12; % Max lambda variance

% Simulation Parameters
SAMPLE_RATE = 10;                 % Hz
SIMULATION_TIME = 120;            % seconds
NUM_SAMPLES = SAMPLE_RATE * SIMULATION_TIME;
time = linspace(0, SIMULATION_TIME, NUM_SAMPLES);
dt = 1 / SAMPLE_RATE;

fprintf('\n========== ENGINE HEALTH PREDICTION SIMULATION ==========\n');
fprintf('Sample Rate: %d Hz | Simulation Time: %d s\n', SAMPLE_RATE, SIMULATION_TIME);
fprintf('Weights: Knock=%.0f%% | Combustion=%.0f%% | Trend=%.0f%%\n', ...
    WEIGHT_KNOCKING*100, WEIGHT_COMBUSTION*100, WEIGHT_TREND*100);
fprintf('=========================================================\n\n');

%% ==================== SCENARIO 1: NORMAL OPERATION ====================

fprintf('SCENARIO 1: Normal Operation (Steady Cruise)\n');

% Normal engine: lambda ~1.0 with slight oscillation + noise
lambda_normal = 1.0 + 0.02 * sin(2*pi*0.5*time) + 0.01 * randn(1, NUM_SAMPLES);
lambda_normal = max(LSU_LAMBDA_MIN, min(LSU_LAMBDA_MAX, lambda_normal));

% Convert lambda to voltage (CJ125 output)
voltage_normal = lambda_to_voltage(lambda_normal);

% Calculate health score
[health_normal, knock_normal, combustion_normal, trend_normal, afr_normal] = ...
    calculate_health_score(lambda_normal);

fprintf('  Avg Health Score: %.1f/100\n', mean(health_normal));
fprintf('  Knocking Score: %.1f\n', mean(knock_normal));
fprintf('  Combustion Score: %.1f\n', mean(combustion_normal));
fprintf('  Trend Score: %.1f\n\n', mean(trend_normal));

%% ==================== SCENARIO 2: KNOCKING EVENT ====================

fprintf('SCENARIO 2: Engine Knocking (Rich Excursions)\n');

% Simulate knocking: rapid lambda oscillations
knock_pattern = zeros(1, NUM_SAMPLES);
knock_pattern(30*SAMPLE_RATE:50*SAMPLE_RATE) = 1;  % Knocking from 30-50s

lambda_knock = 1.0 + 0.02 * sin(2*pi*0.5*time) + 0.01 * randn(1, NUM_SAMPLES);
% Add knock oscillations
lambda_knock = lambda_knock + knock_pattern .* (0.15 * sin(2*pi*8*time));
lambda_knock = max(LSU_LAMBDA_MIN, min(LSU_LAMBDA_MAX, lambda_knock));

voltage_knock = lambda_to_voltage(lambda_knock);
[health_knock, knock_knock, combustion_knock, trend_knock, afr_knock] = ...
    calculate_health_score(lambda_knock);

fprintf('  Avg Health Score: %.1f/100\n', mean(health_knock));
fprintf('  Knocking Score: %.1f (DEGRADED)\n', mean(knock_knock));
fprintf('  Combustion Score: %.1f\n', mean(combustion_knock));
fprintf('  Trend Score: %.1f\n\n', mean(trend_knock));

%% ==================== SCENARIO 3: FOULED ENGINE (DEGRADATION) ====================

fprintf('SCENARIO 3: Engine Fouling (Gradual Degradation)\n');

% Simulate slow degradation: baseline drifts lean, combustion instability increases
lambda_foul = 1.0 + 0.02 * sin(2*pi*0.5*time) + 0.01 * randn(1, NUM_SAMPLES);
% Drift lean over time (fouled plugs, worn carburetor)
lambda_foul = lambda_foul + 0.002 * time;
% Increase variance (combustion becomes unstable)
lambda_foul = lambda_foul + 0.05 * sin(2*pi*1.5*time) .* (time / SIMULATION_TIME);
lambda_foul = max(LSU_LAMBDA_MIN, min(LSU_LAMBDA_MAX, lambda_foul));

voltage_foul = lambda_to_voltage(lambda_foul);
[health_foul, knock_foul, combustion_foul, trend_foul, afr_foul] = ...
    calculate_health_score(lambda_foul);

fprintf('  Avg Health Score: %.1f/100 (DECLINING)\n', mean(health_foul));
fprintf('  Knocking Score: %.1f\n', mean(knock_foul));
fprintf('  Combustion Score: %.1f (DEGRADED)\n', mean(combustion_foul));
fprintf('  Trend Score: %.1f (NEGATIVE TREND)\n\n', mean(trend_foul));

%% ==================== SCENARIO 4: RICH MIXTURE ====================

fprintf('SCENARIO 4: Rich Mixture (Carburetor Issue)\n');

% Simulate rich running: lambda < 1.0 constantly
lambda_rich = 0.85 + 0.02 * sin(2*pi*0.5*time) + 0.01 * randn(1, NUM_SAMPLES);
lambda_rich = max(LSU_LAMBDA_MIN, min(LSU_LAMBDA_MAX, lambda_rich));

voltage_rich = lambda_to_voltage(lambda_rich);
[health_rich, knock_rich, combustion_rich, trend_rich, afr_rich] = ...
    calculate_health_score(lambda_rich);

fprintf('  Avg Health Score: %.1f/100\n', mean(health_rich));
fprintf('  Knocking Score: %.1f\n', mean(knock_rich));
fprintf('  Combustion Score: %.1f (POOR - TOO RICH)\n', mean(combustion_rich));
fprintf('  Trend Score: %.1f\n\n', mean(trend_rich));

%% ==================== PLOTTING ====================

figure('Position', [100 100 1400 900]);

% Subplot 1: Lambda over time - all scenarios
subplot(3,3,1);
plot(time, lambda_normal, 'g-', 'LineWidth', 1.5); hold on;
plot(time, lambda_knock, 'r-', 'LineWidth', 1.5);
plot(time, lambda_foul, 'b-', 'LineWidth', 1.5);
plot(time, lambda_rich, 'm-', 'LineWidth', 1.5);
yline(1.0, 'k--', 'LineWidth', 1);
ylabel('Lambda (λ)');
title('Sensor Output - Lambda');
legend('Normal', 'Knocking', 'Fouled', 'Rich', 'Stoichiometric');
grid on;

% Subplot 2: AFR over time
subplot(3,3,2);
plot(time, afr_normal, 'g-', 'LineWidth', 1.5); hold on;
plot(time, afr_knock, 'r-', 'LineWidth', 1.5);
plot(time, afr_foul, 'b-', 'LineWidth', 1.5);
plot(time, afr_rich, 'm-', 'LineWidth', 1.5);
yline(14.7, 'k--', 'LineWidth', 1);
ylabel('AFR');
title('Air-Fuel Ratio');
legend('Normal', 'Knocking', 'Fouled', 'Rich');
grid on;

% Subplot 3: Voltage (CJ125 output)
subplot(3,3,3);
plot(time, voltage_normal, 'g-', 'LineWidth', 1.5); hold on;
plot(time, voltage_knock, 'r-', 'LineWidth', 1.5);
plot(time, voltage_foul, 'b-', 'LineWidth', 1.5);
plot(time, voltage_rich, 'm-', 'LineWidth', 1.5);
ylabel('Voltage (V)');
title('CJ125 Analog Output');
legend('Normal', 'Knocking', 'Fouled', 'Rich');
grid on;

% Subplot 4: Health Score - Normal
subplot(3,3,4);
plot(time, health_normal, 'g-', 'LineWidth', 2);
ylabel('Health Score');
title('Scenario 1: Normal Operation');
ylim([0 100]);
grid on;
xlabel('Time (s)');

% Subplot 5: Health Score - Knocking
subplot(3,3,5);
plot(time, health_knock, 'r-', 'LineWidth', 2);
ylabel('Health Score');
title('Scenario 2: Knocking Event');
ylim([0 100]);
grid on;
xlabel('Time (s)');

% Subplot 6: Health Score - Fouled
subplot(3,3,6);
plot(time, health_foul, 'b-', 'LineWidth', 2);
ylabel('Health Score');
title('Scenario 3: Engine Fouled');
ylim([0 100]);
grid on;
xlabel('Time (s)');

% Subplot 7: Knocking Score Comparison
subplot(3,3,7);
scenarios = {'Normal', 'Knocking', 'Fouled', 'Rich'};
knock_avg = [mean(knock_normal), mean(knock_knock), mean(knock_foul), mean(knock_rich)];
bar(knock_avg, 'FaceColor', [1 0.3 0.3]);
set(gca, 'XTickLabel', scenarios);
ylabel('Knock Score');
title('Knocking Component (45% weight)');
ylim([0 100]);
grid on;

% Subplot 8: Combustion Quality Comparison
subplot(3,3,8);
combustion_avg = [mean(combustion_normal), mean(combustion_knock), mean(combustion_foul), mean(combustion_rich)];
bar(combustion_avg, 'FaceColor', [0.3 0.7 1]);
set(gca, 'XTickLabel', scenarios);
ylabel('Combustion Score');
title('Combustion Quality (35% weight)');
ylim([0 100]);
grid on;

% Subplot 9: Overall Health Comparison
subplot(3,3,9);
health_avg = [mean(health_normal), mean(health_knock), mean(health_foul), mean(health_rich)];
colors = [0.2 0.8 0.2; 0.8 0.2 0.2; 0.2 0.2 0.8; 0.8 0.2 0.8];
bar(health_avg, 'FaceColor', 'flat');
for i = 1:4
    set(gca, 'Children', get(gca, 'Children'));
end
set(gca, 'XTickLabel', scenarios);
ylabel('Overall Health Score');
title('Overall Engine Health Score');
ylim([0 100]);
grid on;

sgtitle('Engine Health Prediction - Simulation Results', 'FontSize', 14, 'FontWeight', 'bold');

%% ==================== SENSITIVITY ANALYSIS ====================

fprintf('\n========== SENSITIVITY ANALYSIS ==========\n');

% Vary knock sensitivity
knock_sens_range = linspace(0.04, 0.15, 10);
health_vs_knock_sens = zeros(1, length(knock_sens_range));

for i = 1:length(knock_sens_range)
    % Recalculate with different knock sensitivity (simplified)
    knock_score_temp = 100 * (1 - min(1, var(lambda_knock) / knock_sens_range(i)));
    health_vs_knock_sens(i) = WEIGHT_KNOCKING * knock_score_temp + ...
                               WEIGHT_COMBUSTION * mean(combustion_knock) + ...
                               WEIGHT_TREND * mean(trend_knock);
end

figure;
subplot(1,3,1);
plot(knock_sens_range, health_vs_knock_sens, 'r-o', 'LineWidth', 2);
xlabel('Knock Sensitivity Threshold');
ylabel('Health Score');
title('Sensitivity to Knock Detection');
grid on;

% Vary combustion quality threshold
combust_thresh_range = linspace(0.05, 0.25, 10);
health_vs_combust = zeros(1, length(combust_thresh_range));

for i = 1:length(combust_thresh_range)
    combust_score_temp = 100 * (1 - min(1, var(lambda_foul) / combust_thresh_range(i)));
    health_vs_combust(i) = WEIGHT_KNOCKING * mean(knock_foul) + ...
                           WEIGHT_COMBUSTION * combust_score_temp + ...
                           WEIGHT_TREND * mean(trend_foul);
end

subplot(1,3,2);
plot(combust_thresh_range, health_vs_combust, 'b-o', 'LineWidth', 2);
xlabel('Combustion Quality Threshold');
ylabel('Health Score');
title('Sensitivity to Combustion Quality');
grid on;

% Weight comparison
subplot(1,3,3);
weights_matrix = [
    WEIGHT_KNOCKING, WEIGHT_COMBUSTION, WEIGHT_TREND;
    0.5, 0.3, 0.2;
    0.3, 0.4, 0.3;
];
weight_names = {'Current', 'Alt 1', 'Alt 2'};
x = 1:3;
b = bar(weights_matrix);
set(gca, 'XTickLabel', weight_names);
ylabel('Weight');
title('Weight Configuration Options');
legend('Knock', 'Combustion', 'Trend');
grid on;

fprintf('Knock sensitivity range: %.3f to %.3f\n', knock_sens_range(1), knock_sens_range(end));
fprintf('Combustion threshold range: %.3f to %.3f\n', combust_thresh_range(1), combust_thresh_range(end));
fprintf('Analysis complete.\n\n');

%% ==================== FUNCTIONS ====================

function voltage = lambda_to_voltage(lambda)
    % Convert lambda to CJ125 output voltage
    % Linear mapping: lambda 0.68 -> 0.5V, lambda 1.36 -> 4.5V
    voltage = 0.5 + (lambda - 0.68) / (1.36 - 0.68) * (4.5 - 0.5);
    voltage = max(0.5, min(4.5, voltage)); % Clamp to valid range
end

function lambda = voltage_to_lambda(voltage)
    % Convert CJ125 voltage to lambda
    lambda = 0.68 + (voltage - 0.5) / (4.5 - 0.5) * (1.36 - 0.68);
    lambda = max(0.68, min(1.36, lambda)); % Clamp
end

function afr = lambda_to_afr(lambda)
    % Convert lambda to air-fuel ratio (gasoline)
    afr = 14.7 * lambda;
end

function [health_score, knock_score, combustion_score, trend_score, afr, lambda_filt] = ...
    calculate_health_score(lambda)
    % Calculate weighted health score from lambda data
    
    WEIGHT_KNOCKING = 0.45;
    WEIGHT_COMBUSTION = 0.35;
    WEIGHT_TREND = 0.20;
    KNOCK_SENSITIVITY = 0.08;
    LAMBDA_TARGET = 1.0;
    COMBUSTION_THRESHOLD = 0.12;
    
    % Filter lambda signal (moving average)
    lambda_filt = movmean(lambda, 5);
    
    % Convert to AFR
    afr = lambda_to_afr(lambda_filt);
    
    % 1. KNOCKING SCORE (45%)
    % High variance = more knocking
    lambda_variance = movvar(lambda_filt, 10);
    knock_score = 100 * max(0, 1 - lambda_variance / KNOCK_SENSITIVITY);
    
    % 2. COMBUSTION QUALITY SCORE (35%)
    % Measure deviation from stoichiometric (lambda = 1.0)
    lambda_deviation = abs(lambda_filt - LAMBDA_TARGET);
    combustion_quality = 100 * max(0, 1 - mean(lambda_deviation) / COMBUSTION_THRESHOLD);
    combustion_score = repmat(combustion_quality, 1, length(lambda));
    
    % 3. TREND DEGRADATION SCORE (20%)
    % Compare current to baseline (first 20% of data)
    baseline_end = max(20, round(length(lambda) * 0.2));
    baseline = mean(lambda_filt(1:baseline_end));
    current_avg = movmean(lambda_filt, 50);
    trend_degradation = abs(current_avg - baseline);
    trend_score = 100 * max(0, 1 - trend_degradation * 10); % Scale for visibility
    
    % OVERALL HEALTH SCORE (weighted combination)
    health_score = WEIGHT_KNOCKING * knock_score + ...
                   WEIGHT_COMBUSTION * combustion_score + ...
                   WEIGHT_TREND * trend_score;
    
    % Clamp to 0-100
    health_score = max(0, min(100, health_score));
    knock_score = max(0, min(100, knock_score));
    combustion_score = max(0, min(100, combustion_score));
    trend_score = max(0, min(100, trend_score));
end
