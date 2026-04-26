function results = analyse_engine_health(data, save_fig)
%ANALYSE_ENGINE_HEALTH  Analyses exhaust gas trends and health degradation.

if nargin < 2, save_fig = false; end

% Emission thresholds (Euro 6 equivalent)
CO_LIMIT  = 1000;
HC_LIMIT  = 100;
NOx_LIMIT = 180;
LAM_LO    = 0.97;
LAM_HI    = 1.03;

stage_labels = {'New','Normal Wear','Accel. Wear','Critical'};
stage_colors = [0.18 0.80 0.44; 0.95 0.77 0.06; 0.90 0.49 0.13; 0.91 0.30 0.24];

%% Violations
co_viol  = sum(data.CO_ppm  > CO_LIMIT);
hc_viol  = sum(data.HC_ppm  > HC_LIMIT);
nox_viol = sum(data.NOx_ppm > NOx_LIMIT);
lam_viol = sum(data.lambda < LAM_LO | data.lambda > LAM_HI);
n = height(data);

fprintf('\n  Emission Violations:\n');
fprintf('    CO  : %d (%.1f%%)\n', co_viol,  co_viol/n*100);
fprintf('    HC  : %d (%.1f%%)\n', hc_viol,  hc_viol/n*100);
fprintf('    NOx : %d (%.1f%%)\n', nox_viol, nox_viol/n*100);
fprintf('    λ OOB: %d (%.1f%%)\n', lam_viol, lam_viol/n*100);

%% Rolling health average
win = 50;
health_roll = movmean(data.health_index, win);
dH_dt = gradient(health_roll) ./ gradient(data.hour);

%% Plot
fig = figure('Name','Engine Health Analysis','Position',[100 100 1300 900]);

% Color array per point
c_array = stage_colors(data.stage+1, :);

subplot(3,2,1)
scatter(data.hour, data.lambda, 4, c_array, 'filled', 'MarkerFaceAlpha', 0.6);
yline(1.0, 'k--', 'λ=1', 'LineWidth', 1);
yline(LAM_LO, ':','Color',[0.5 0.5 0.5]);
yline(LAM_HI, ':','Color',[0.5 0.5 0.5]);
xlabel('Engine Hours'); ylabel('Lambda (λ)');
title('Lambda Drift Over Engine Life'); grid on;

subplot(3,2,2)
plot(data.hour, data.combustion_eff, 'Color', [0.27 0.51 0.71], 'LineWidth', 1.2);
xlabel('Engine Hours'); ylabel('Efficiency [%]');
title('Combustion Efficiency'); grid on;

subplot(3,2,3)
plot(data.hour, data.CO_ppm,  'r',  'LineWidth', 1, 'DisplayName','CO');  hold on;
plot(data.hour, data.HC_ppm,  'Color',[1 0.6 0], 'LineWidth', 1, 'DisplayName','HC');
plot(data.hour, data.NOx_ppm, 'm',  'LineWidth', 1, 'DisplayName','NOx');
yline(CO_LIMIT,  'r--',  'LineWidth', 0.8);
yline(HC_LIMIT,  '--',   'Color',[1 0.6 0], 'LineWidth', 0.8);
yline(NOx_LIMIT, 'm--',  'LineWidth', 0.8);
xlabel('Engine Hours'); ylabel('[ppm]');
title('Exhaust Emissions (dashed = Euro 6 limit)');
legend('Location','northwest'); grid on;

subplot(3,2,4)
plot(data.hour, data.health_index, 'Color',[0.7 0.7 0.7], 'LineWidth', 0.8); hold on;
plot(data.hour, health_roll, 'g', 'LineWidth', 2, 'DisplayName','Rolling Mean');
yline(30, 'r--', 'Critical (30)', 'LineWidth', 1);
xlabel('Engine Hours'); ylabel('Health Index (0–100)');
title('Engine Health Index'); legend; grid on;

subplot(3,2,5)
for s = 0:3
    idx = data.stage == s;
    histogram(data.AFR(idx), 30, 'FaceColor', stage_colors(s+1,:), ...
              'FaceAlpha', 0.6, 'DisplayName', stage_labels{s+1}); hold on;
end
xline(14.7, 'k--', 'AFR=14.7', 'LineWidth', 1);
xlabel('Air-Fuel Ratio'); ylabel('Count');
title('AFR Distribution by Stage');
legend('Location','northwest','FontSize',8); grid on;

subplot(3,2,6)
plot(data.hour, dH_dt, 'Color',[0.6 0.1 0.1], 'LineWidth', 1);
yline(0, 'k', 'LineWidth', 0.5);
xlabel('Engine Hours'); ylabel('dHealth/dt');
title('Rate of Health Degradation'); grid on;

sgtitle('Engine Health Analysis — O₂/Lambda Sensor Exhaust Diagnostics', ...
        'FontSize', 13, 'FontWeight', 'bold');

if save_fig
    if ~exist('results','dir'), mkdir('results'); end
    saveas(fig, 'results/engine_health_analysis.png');
end

results.final_health  = data.health_index(end);
results.co_violations = co_viol;
results.hc_violations = hc_viol;
results.nox_violations= nox_viol;
results.health_roll   = health_roll;
end