---
title: 'Engine Health Prediction Device for Carbureted Two-Wheelers'
tags:
  - arduino
  - esp32
  - embedded-systems
  - engine-diagnostics
  - lambda-sensor
  - cj125
authors:
  - name: Koramutla Pradeep
    orcid: 0009-0001-4852-0481
    affiliation: "1"
affiliations:
  - name: Independent Researcher
    index: 1
date: 18 June 2026
bibliography: 4.paper.bib
---

# Engine Health Prediction Device for Carbureted Two-Wheelers

## Summary

Modern vehicles benefit from sophisticated on-board diagnostic systems that monitor engine health in real-time. However, carbureted two-wheelers — which comprise millions of vehicles globally in developing regions — lack such monitoring capabilities. This paper presents a compact, portable, retrofit engine health prediction device that analyzes exhaust gas composition using a wideband lambda sensor to detect engine degradation, knocking events, and combustion quality without requiring OBD-II access or engine RPM data.

## Statement of Need

Carbureted two-wheelers (motorcycles, scooters, mopeds) represent a significant portion of global vehicles, particularly in Asia and Africa. Unlike modern fuel-injected engines with embedded diagnostics, carbureted engines provide no warning of health degradation, poor combustion, or impending mechanical failure. This lack of visibility forces owners to rely on reactive maintenance.

Engine knock, valve wear, spark plug degradation, and fuel delivery problems manifest as anomalies in exhaust gas composition long before mechanical failure occurs. A low-cost, standalone monitoring device would enable predictive maintenance, fuel efficiency optimization, emission monitoring, and owner empowerment.

## Implementation

**Hardware:** ESP32 microcontroller with Bosch LSU 4.9 wideband oxygen sensor measures exhaust lambda (\(\lambda\)) in real-time.

**Firmware:** Arduino-compatible code with adaptive calibration, health scoring, and data logging.

**Algorithm:** Baseline health profiling and deviation monitoring for degradation and knock detection.

## Validation

The algorithm was validated in MATLAB using synthetic degradation scenarios and ported to ESP32.

## Repository Contents

- Firmware, hardware designs, documentation, and validation scripts are available in the repository.

## Future Work

Bluetooth integration, ML-based knock detection, and additional sensor fusion.

## Acknowledgments

Thanks to the open-source community and tools like Arduino and ESP-IDF.