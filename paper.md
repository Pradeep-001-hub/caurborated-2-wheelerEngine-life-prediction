---
title: 'Engine Health Prediction Device for Carbureted Two-Wheelers'
tags:
  - cj125 chip
  - esp32 microcontroller
  - embedded-systems
  - engine-diagnostics
  - lambda-sensor
  - temperature sensor
  - LCD 
author:
  - name: koramutla pradeep
    orcid: 0009-0001-4852-0481
   affiliation: "1"
affiliations:
  - name: independent researcher
  - index:1
date: 18 June 2026
bibliography: paper.bib
---

## device portable and retrofit-compatible.
----

## Key Features

- No OBD dependency
- Standalone battery-backed operation
- Compact & portable (3D-printed enclosure)
- Low cost (approximately $65 USD)
- Historical data logging on SD card
- Adaptive self-calibration
---

## Validation
The MATLAB-based algorithm was validated using synthetic degradation scenarios (healthy baseline, progressive wear, critical degradation, and rich mixture faults).
----

## Repository Contents

- `firmware/`: Arduino sketches for ESP32
- `hardware/`: CAD models, schematics, and BOM
- `docs/`: Installation, calibration, and usage guides
- `validation/`: Test data and MATLAB scripts
  -

## introduction:

Modern vehicles benefit from sophisticated on-board diagnostic systems that monitor engine health in real-time. However, carbureted two-wheelers—which comprise millions of vehicles globally in developing regions—lack such monitoring capabilities. This paper presents a compact, portable, retrofit engine health prediction device that analyzes exhaust gas composition using a wideband lambda sensor to detect engine degradation, knocking events, and combustion quality without requiring OBD-II access or engine RPM data
-----

## Statement of Need

Carbureted two-wheelers (motorcycles, scooters, mopeds) represent a significant portion of global vehicles, particularly in Asia and Africa. Unlike modern fuel-injected engines with embedded diagnostics, carbureted engines provide no warning of health degradation, poor combustion, or impending mechanical failure. This lack of visibility forces owners to rely on reactive maintenance—waiting for catastrophic failure before intervention.

Engine knock, valve wear, spark plug degradation, and fuel delivery problems manifest as anomalies in exhaust gas composition long before mechanical failure occurs. A low-cost, standalone monitoring device that can be retrofitted to existing carbureted vehicles would enable:

- **Predictive Maintenance:** Detect engine problems before catastrophic failure
- **Fuel Efficiency Optimization:** Real-time feedback on combustion quality
- **Emission Monitoring:** Track exhaust gas parameters for regulatory compliance
- **Owner Empowerment:** Mechanics and enthusiasts gain visibility into engine state
-----

## Implementation

The device consists of three core components:

**Hardware:** An ESP32 microcontroller paired with a Bosch LSU 4.9 wideband oxygen sensor measures exhaust lambda (air-fuel ratio) in real-time. A buck converter steps down 12V vehicle power to 5V logic levels. An OLED display provides real-time feedback, and an SD card module logs historical data for trend analysis. A modular enclosure makes the device portable and retrofit-compatible.

**Firmware:** Two-file Arduino firmware (config.h + main.ino) implements:
- Adaptive lambda sensor calibration independent of engine RPM
- Weighted health scoring algorithm analyzing combustion stability, knock indicators, and baseline deviation
- EEPROM-based baseline persistence across power cycles
- SD card logging with timestamp and parameter aggregation
- Real-time OLED visualization of health metrics

**Control Algorithm:** The system establishes a baseline health profile during initial operation, then monitors deviation from baseline as an indicator of engine degradation. Knock detection is inferred from rapid transients in exhaust composition. Health scores integrate multiple parameters: combustion consistency (lambda variance), knock event frequency, and deviation from established baseline.
-------

## Key Features

- **No OBD Dependency:** Works on carbureted engines without diagnostic port
- **Standalone Operation:** Battery-backed OLED display functions independently
- **Compact & Portable:** 3D-printed enclosure fits vehicle toolkits
- **Low Cost:** Total BOM ~$65 USD; no licensing fees
- **Historical Logging:** SD card storage enables trend analysis and diagnostics
- **Adaptive Calibration:** Self-learning baseline reduces manual tuning

## Target Users

- Two-wheeler mechanics and service centers
- Automotive enthusiasts and DIY technicians
- Researchers in engine diagnostics and combustion monitoring
- Fleet operators managing carbureted vehicle fleets

## Validation

Initial prototype validation on test vehicles demonstrates feasible sensor integration, stable lambda measurement acquisition, and real-time health scoring with reasonable computational overhead on ESP32.

## Repository Contents

- **firmware/:** Arduino sketches for ESP32 (config.h, main.ino)
- **hardware/:** CAD models, schematic, BOM for laser-cut and 3D-printed components
- **docs/:** Installation, calibration, and usage guides
- **validation/:** Sample logs and test data from prototype vehicles
----

### MATLAB Algorithm
The core engine health prediction algorithm was developed and validated 
in MATLAB. The algorithm analyzes lambda (λ) sensor readings and validates 
against Euro 6 emission standards:
- CO threshold: 1000 ppm
- HC threshold: 100 ppm  
- NOx threshold: 180 ppm
- Lambda window: 0.97–1.03

The health index (0–100 scale) integrates:
- Combustion efficiency trends
- Emission violation frequency
- Lambda drift and stability
- Degradation rate (dHealth/dt)

### Firmware Implementation
The validated MATLAB algorithm was ported to Arduino/ESP32 for real-time 
deployment on carbureted two-wheelers using a Bosch LSU 4.9 wideband 
oxygen sensor.

### Hardware Design
Parametric 3D enclosure designed in OpenSCAD for ease of manufacturing 
and customization.
---
## MATLAB Validation & Synthetic Testing

The engine health prediction algorithm was validated using synthetic 
engine degradation scenarios representing real-world conditions:

1. **Healthy Baseline (500 hours):** Stable lambda, optimal combustion
2. **Normal to Accelerated Wear (2000 hours):** Progressive degradation
3. **Critical Degradation (3000 hours):** Long-term failure trajectory
4. **Rich Mixture Fault (1500 hours):** Diagnostic anomaly detection

The algorithm detects:
- Lambda (λ) drift and instability
- Emission violations (CO, HC, NOx vs Euro 6 limits)
- Combustion efficiency decline
- Health index degradation rate (dHealth/dt)
- Remaining useful life (RUL) prediction

See `Simulation of sensor/` folder for MATLAB scripts and generated results.
-----
## Complete System Architecture

### Algorithm Layer (MATLAB)
- `generate_synthetic_engine_data.m`: Generates 4 realistic degradation scenarios
- `analyse_engine_health.m`: Core health index calculation & validation
- `plot_dashboard.m`: Real-time monitoring dashboard
  -

### Scenarios Validated
1. Healthy baseline (500 hours) — stable operation
2. Normal → accelerated wear (2000 hours) — realistic degradation
3. Critical stage (3000 hours) — failure trajectory
4. Rich mixture fault (1500 hours) — diagnostic anomaly

### Implementation Layer (ESP32 Firmware)
Arduino-compatible code porting validated algorithm to embedded platform.

### Hardware Layer (OpenSCAD)
Parametric 3D-printable enclosure for field deployment.
---

### Reproducibility
All MATLAB scripts, firmware, and CAD designs are in the public repository.
Complete synthetic datasets and generated dashboards included.
-----
## Future Work

Planned extensions include Bluetooth connectivity for smartphone visualization, ML-based knock detection algorithms, and expanded sensor fusion (temperature, pressure) for enhanced diagnostics.
----

## Acknowledgments

Development was enabled by open-source tools including Arduino, ESP-IDF, and the broader embedded systems community.
