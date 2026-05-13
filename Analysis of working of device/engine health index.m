%% ================= ENGINE HEALTH INDEX SIMULATION =================
clear all; close all; clc;

%% ================= TIME SETUP =================
T = 1:1:300;   % simulation time (seconds)

%% ================= SYNTHETIC SENSOR DATA =================
% AFR signal (normal + disturbance + degradation)
AFR_stoich = 14.7;

AFR = AFR_stoich + 0.8*sin(0.05*T) + 0.5*randn(1,length(T));

% simulate gradual engine degradation
AFR = AFR + linspace(0, 1.5, length(T));

% Temperature signal (engine thermal behavior)
Temp_opt = 90;
Temp = 85 + 10*sin(0.03*T) + 2*randn(1,length(T));

% simulate overheating trend
Temp = Temp + linspace(0, 8, length(T));

%% ================= INITIALIZATION =================
S_AFR = zeros(1,length(T));
S_Stability = zeros(1,length(T));
S_Thermal = zeros(1,length(T));
S_Combustion = zeros(1,length(T));
EHI = zeros(1,length(T));

window = 10; % rolling window for stability

%% ================= MAIN COMPUTATION LOOP =================
for t = 1:length(T)
    
    % ----- AFR Score -----
    k1 = 0.8;
    S_AFR(t) = exp(-k1 * abs(AFR(t) - AFR_stoich));
    
    % ----- Stability Score -----
    if t > window
        sigma = std(AFR(t-window:t));
        mu = mean(AFR(t-window:t));
        S_Stability(t) = 1 - (sigma / (mu + 1e-6));
    else
        S_Stability(t) = 1;
    end
    
    % ----- Thermal Score -----
    k2 = 0.01;
    S_Thermal(t) = exp(-k2 * (Temp(t) - Temp_opt)^2);
    
    % ----- Combustion Quality Score -----
    % simulate rich/lean cycles
    if AFR(t) > 15.5 || AFR(t) < 13.5
        S_Combustion(t) = 0.6;
    else
        S_Combustion(t) = 1;
    end
    
    % ----- Trend Score -----
    if t > 1
        dE = abs(AFR(t) - AFR(t-1));
    else
        dE = 0;
    end
    
    k3 = 0.3;
    S_Trend = exp(-k3 * dE);
    
    % ----- Final Engine Health Index -----
    EHI(t) = 0.30*S_AFR(t) + ...
             0.25*S_Stability(t) + ...
             0.15*S_Thermal(t) + ...
             0.15*S_Combustion(t) + ...
             0.15*S_Trend;
end

%% ================= NORMALIZE TO 100 SCALE =================
EHI = EHI * 100;

%% ================= PLOTTING =================

figure;
plot(T, AFR);
title('AFR Signal');
xlabel('Time (s)');
ylabel('AFR');

figure;
plot(T, Temp);
title('Engine Temperature');
xlabel('Time (s)');
ylabel('Temperature (°C)');

figure;
plot(T, EHI);
title('Engine Health Index (EHI)');
xlabel('Time (s)');
ylabel('Health Index (0 - 100)');
grid on;

%% ================= HEALTH CLASSIFICATION =================
for i = 1:length(EHI)
    if EHI(i) > 80
        status(i) = 3; % Healthy
    elseif EHI(i) > 60
        status(i) = 2; % Moderate
    else
        status(i) = 1; % Poor
    end
end

figure;
stairs(T, status);
ylim([0 4]);
title('Engine Health State Classification');
xlabel('Time (s)');
ylabel('State (1=Poor, 2=Moderate, 3=Healthy)');
grid on;
