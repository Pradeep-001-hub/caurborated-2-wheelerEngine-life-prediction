%% SYNTHETIC ENGINE HEALTH DATA: Generate & Visualize
%
% This script generates 4 realistic engine degradation scenarios and
% creates publication-ready plots for your MDPI/IEEE Sensors paper.
%
% Run this to generate:
%   - dashboard_healthy.png
%   - analysis_worn.png
%   - analysis_critical.png
%   - analysis_rich_fault.png

clear; clc; close all;

fprintf('\n╔════════════════════════════════════════════════════════════════════╗\n');
fprintf('║   SYNTHETIC ENGINE HEALTH DATASET GENERATOR                       ║\n');
fprintf('║   Carbureted Two-Wheeler Engine Diagnostics                       ║\n');
fprintf('╚════════════════════════════════════════════════════════════════════╝\n');

%% SCENARIO 1: Healthy New Engine (Baseline Reference)
fprintf('\n[1/4] NEW ENGINE (Baseline - Stable Operation)\n');
data_healthy = generate_synthetic_engine_data('healthy', 500);
analyse_engine_health(data_healthy, true);  % saves plot
plot_dashboard(data_healthy, true);

%% SCENARIO 2: Normal Wear → Accelerated Wear (2000 hours)
fprintf('\n[2/4] NORMAL & ACCELERATED WEAR (Life Cycle Progression)\n');
data_worn = generate_synthetic_engine_data('worn', 2000);
analyse_engine_health(data_worn, true);
plot_dashboard(data_worn, true);

%% SCENARIO 3: Progressive Degradation to Critical (3000 hours)
fprintf('\n[3/4] CRITICAL DEGRADATION (Long-Term Failure)\n');
data_critical = generate_synthetic_engine_data('critical', 3000);
analyse_engine_health(data_critical, true);
plot_dashboard(data_critical, true);

%% SCENARIO 4: Sudden Rich Mixture Fault
fprintf('\n[4/4] RICH MIXTURE FAULT (Diagnostic Anomaly)\n');
data_rich = generate_synthetic_engine_data('rich_fault', 1500);
analyse_engine_health(data_rich, true);
plot_dashboard(data_rich, true);

fprintf('\n✓ All scenarios generated successfully!\n');
fprintf('  Check results/ folder for PNG files.\n\n');

%% Comparative Summary Statistics
fprintf('╔════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                    COMPARATIVE RESULTS SUMMARY                    ║\n');
fprintf('╚════════════════════════════════════════════════════════════════════╝\n');

scenarios = {'Healthy (500h)', 'Worn (2000h)', 'Critical (3000h)', 'Rich Fault (1500h)'};
data_sets = {data_healthy, data_worn, data_critical, data_rich};

fprintf('\n%20s | %12s | %12s | %12s | %12s\n', 'Scenario', 'Λ Range', 'Health Δ', 'CO Max', 'Final Stage');
fprintf('%s\n', repmat('-', 75, 1));

stage_names = {'NEW', 'NORMAL', 'ACCEL', 'CRITICAL'};
for k = 1:4
    d = data_sets{k};
    lambda_range = sprintf('%.2f–%.2f', min(d.lambda), max(d.lambda));
    health_delta = sprintf('%.0f → %.0f', d.health_index(1), d.health_index(end));
    co_max = sprintf('%.0f ppm', max(d.CO_ppm));
    final_stage = stage_names{d.stage(end) + 1};
    
    fprintf('%20s | %12s | %12s | %12s | %12s\n', ...
            scenarios{k}, lambda_range, health_delta, co_max, final_stage);
end

fprintf('\n');
end


%% ─────────────────────────────────────────────────────────────────────
%  HELPER: Plot Dashboard (uses your existing function)
%% ─────────────────────────────────────────────────────────────────────

function plot_dashboard(data, save_fig)
%PLOT_DASHBOARD  Engine life monitoring dashboard.

if nargin < 2, save_fig = false; end

stage_colors = [0.18 0.80 0.44; 0.95 0.77 0.06; 0.90 0.49 0.13; 0.91 0.30 0.24];
stage_labels = {'NEW','NORMAL WEAR','ACCEL. WEAR','CRITICAL'};

latest = data(end,:);
stg    = latest.stage + 1;   % 1-indexed

fig = figure('Name','Engine Dashboard','Position',[50 50 1400 800], ...
             'Color',[0.10 0.10 0.14]);

%% Status banner
ax0 = subplot('Position',[0.02 0.88 0.96 0.08]);
patch([0 1 1 0],[0 0 1 1], stage_colors(stg,:), 'Parent',ax0);
text(0.5, 0.5, sprintf('ENGINE STATUS:  %s   |   Health: %.1f%%   |   RUL: %.0f hrs', ...
     stage_labels{stg}, latest.health_index, latest.RUL_hours), ...
     'Units','normalized','HorizontalAlignment','center', ...
     'FontSize',14,'FontWeight','bold','Color','w','Parent',ax0);
axis(ax0,'off');

%% KPI tiles
kpi = {
    'Lambda (λ)',       latest.lambda,         0.8,  1.2,  'λ';
    'Air-Fuel Ratio',   latest.AFR,            10,   18,   'AFR';
    'Comb. Efficiency', latest.combustion_eff, 60,   100,  '%';
    'CO Level',         latest.CO_ppm,         0,    5000, 'ppm';
};

for k = 1:4
    ax = subplot('Position', [0.02+(k-1)*0.245, 0.60, 0.22, 0.25]);
    set(ax,'Color',[0.13 0.13 0.18]);
    val  = kpi{k,2}; vmin = kpi{k,3}; vmax = kpi{k,4};
    pct  = min(1, max(0, (val-vmin)/(vmax-vmin)));
    col  = [pct, 1-pct, 0.2];   % green → red

    % Semicircle gauge
    th = linspace(pi, 0, 200);
    plot(ax, cos(th), sin(th), 'Color',[0.3 0.3 0.3], 'LineWidth', 10); hold(ax,'on');
    th_f = linspace(pi, pi - pct*pi, 200);
    plot(ax, cos(th_f), sin(th_f), 'Color', col, 'LineWidth', 10);
    text(ax, 0, -0.1, sprintf('%.2f', val),  'HorizontalAlignment','center', ...
         'FontSize',18,'FontWeight','bold','Color','w');
    text(ax, 0, -0.45, kpi{k,5}, 'HorizontalAlignment','center','FontSize',10,'Color',[0.7 0.7 0.7]);
    text(ax, 0,  0.7,  kpi{k,1}, 'HorizontalAlignment','center','FontSize',10,'FontWeight','bold','Color','w');
    xlim(ax,[-1.3 1.3]); ylim(ax,[-0.7 1.1]); axis(ax,'off');
end

%% Health trend
ax_h = subplot('Position',[0.02 0.08 0.46 0.45]);
set(ax_h,'Color',[0.13 0.13 0.18],'XColor','w','YColor','w');
plot(ax_h, data.hour, data.health_index, 'Color',[0.5 0.5 0.5], 'LineWidth',0.8); hold(ax_h,'on');
plot(ax_h, data.hour, movmean(data.health_index,50), 'Color',[0.18 0.80 0.44], 'LineWidth',2);
yline(ax_h, 30,'r--','LineWidth',1);
xlabel(ax_h,'Hours','Color','w'); ylabel(ax_h,'Health Index','Color','w');
title(ax_h,'Health Index Over Life','Color','w'); grid(ax_h,'on');
ax_h.GridColor = [0.3 0.3 0.3];

%% Emissions trend
ax_e = subplot('Position',[0.52 0.08 0.46 0.45]);
set(ax_e,'Color',[0.13 0.13 0.18],'XColor','w','YColor','w');
plot(ax_e, data.hour, data.CO_ppm,  'r',  'LineWidth',1,'DisplayName','CO');  hold(ax_e,'on');
plot(ax_e, data.hour, data.HC_ppm,  'Color',[1 0.6 0],'LineWidth',1,'DisplayName','HC');
plot(ax_e, data.hour, data.NOx_ppm, 'm',  'LineWidth',1,'DisplayName','NOx');
xlabel(ax_e,'Hours','Color','w'); ylabel(ax_e,'[ppm]','Color','w');
title(ax_e,'Exhaust Emissions','Color','w');
legend(ax_e,'TextColor','w','Color',[0.2 0.2 0.2],'FontSize',8);
grid(ax_e,'on'); ax_e.GridColor = [0.3 0.3 0.3];

if save_fig
    if ~exist('results','dir'), mkdir('results'); end
    saveas(fig,'results/dashboard.png');
    fprintf('  Dashboard saved → results/dashboard.png\n');
end
end


%% ─────────────────────────────────────────────────────────────────────
%  HELPER: Engine Health Analysis (uses your existing function)
%% ─────────────────────────────────────────────────────────────────────

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
