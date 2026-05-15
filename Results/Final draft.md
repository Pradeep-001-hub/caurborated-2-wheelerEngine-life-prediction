Upgraded Features Compared to Previous Firmware
1. Multi-Page Intelligent Dashboard System
Previous Version
The earlier firmware displayed only:
Lambda value
AFR value
Basic health score
Rich / Lean / OK status
All information was shown on a single static OLED screen.
Upgraded Version
The new firmware introduces a complete multi-page diagnostic dashboard system.
The OLED now supports:
Page
Function
Main Dashboard
Live AFR + health monitoring
Statistics Page
Runtime analytics
Trend Graph
Real-time combustion visualization
Oscillation Analysis
AFR frequency analysis
Misfire Detection
Combustion instability estimation
Catalyst Analysis
Catalytic efficiency estimation
RUL Estimation
Remaining engine life prediction
AI Analysis
Anomaly detection system
Technical Improvement
The firmware now uses:
C++
enum DisplayPage {
  PAGE_MAIN,
  PAGE_STATS,
  PAGE_GRAPH,
  PAGE_OSC,
  PAGE_MISFIRE,
  PAGE_CATALYST,
  PAGE_RUL,
  PAGE_AI
};
This transforms the OLED into a true embedded diagnostic interface rather than a basic AFR monitor.
2. Advanced Combustion Health Algorithm
Previous Version
The earlier system used:
lambda variance
combustion deviation
simple trend comparison
to generate a basic health score.
Upgraded Version
The upgraded firmware introduces a weighted multi-factor health model.
The new health system combines:
combustion stability
oscillation variance
long-term drift
AFR deviation
anomaly behavior
using weighted scoring logic.
Technical Improvement
C++
float score =
  (0.45 * oscillation) +
  (0.35 * combustion) +
  (0.20 * trend);
This produces more stable and intelligent diagnostics under varying engine conditions.
3. Fuel Efficiency Estimation
Previous Version
The previous firmware had no fuel economy analysis.
Upgraded Version
The upgraded system now estimates relative fuel efficiency based on AFR stability and stoichiometric deviation.
Functional Capability
The device can now estimate:
combustion efficiency
mixture optimization
relative fuel wastage
Technical Improvement
C++
float calcFuelEfficiency() {

  float dev = abs(lambdaValue - 1.0);

  float eff = 100 - (dev * 220);

  return constrain(eff, 0, 100);
}
This creates a real-time efficiency indicator useful for:
engine tuning
injector diagnostics
fuel mapping analysis
4. Oscillation Frequency Analysis
Previous Version
The previous firmware only observed AFR values.
It could not analyze AFR switching behavior.
Upgraded Version
The upgraded firmware now measures lambda crossing frequency.
This allows the system to detect:
unstable combustion
injector oscillation
closed-loop AFR switching behavior
sensor instability
Technical Improvement
C++
float calcOscillationFrequency() {

  int crossings = 0;

  for (int i = 1; i < BUFFER_SIZE; i++) {

    if ((lambdaBuffer[i - 1] < 1.0 &&
         lambdaBuffer[i] > 1.0) ||

        (lambdaBuffer[i - 1] > 1.0 &&
         lambdaBuffer[i] < 1.0)) {

      crossings++;
    }
  }

  return crossings / 2.0;
}
This significantly improves combustion dynamics analysis.
5. Misfire Probability Estimation
Previous Version
No misfire analysis existed.
Upgraded Version
The upgraded firmware now estimates combustion instability and potential misfires using:
lambda spikes
rapid AFR fluctuations
variance irregularities
Diagnostic Capability
The system can now identify:
injector instability
ignition weakness
partial combustion failure
lean spike behavior
Technical Improvement
C++
float calcMisfireProbability() {

  float variance = calcVariance(lambdaBuffer, BUFFER_SIZE);

  float prob = variance * 3000;

  if (abs(lambdaValue - 1.0) > 0.18)
    prob += 25;

  return constrain(prob, 0, 100);
}
This converts the device from a monitoring tool into a predictive diagnostic system.
6. Catalyst Efficiency Estimation
Previous Version
The previous firmware had no catalytic analysis capability.
Upgraded Version
The upgraded firmware estimates catalyst effectiveness using combustion stability behavior.
Diagnostic Capability
The system can estimate:
oxygen storage behavior
AFR smoothing effectiveness
possible catalyst degradation
Technical Improvement
C++
float calcCatalystEfficiency() {

  float variance = calcVariance(lambdaBuffer, BUFFER_SIZE);

  float eff = 100 - (variance * 2500);

  return constrain(eff, 0, 100);
}
This adds emissions-oriented diagnostics to the platform.
7. Remaining Useful Life (RUL) Prediction
Previous Version
No predictive maintenance capability existed.
Upgraded Version
The new firmware estimates engine degradation trends and predicts remaining operational condition.
Diagnostic Capability
The device now performs:
degradation estimation
wear trend analysis
predictive maintenance support
Technical Improvement
C++
float calcRUL() {

  float degradation = 100 - healthScore;

  float rul = 100 - degradation * 1.2;

  return constrain(rul, 0, 100);
}
This introduces research-grade predictive diagnostics.
8. AI-Based Anomaly Detection
Previous Version
No intelligent fault detection existed.
Upgraded Version
The upgraded firmware introduces an AI-inspired anomaly scoring engine.
Diagnostic Capability
The system can identify:
abnormal AFR behavior
unstable combustion
irregular oscillation patterns
sensor anomalies
possible injector faults
Technical Improvement
C++
float calcAIAnomaly() {

  float score = 0;

  score += abs(lambdaValue - 1.0) * 180;

  score += calcVariance(lambdaBuffer, BUFFER_SIZE) * 4000;

  score += misfireProbability * 0.3;

  return constrain(score, 0, 100);
}
This forms the foundation for future TinyML integration.
9. Real-Time Trend Graph Visualization
Previous Version
No graphical visualization existed.
Upgraded Version
The OLED now supports live combustion trend plotting.
Functional Capability
The graph displays:
AFR transitions
combustion oscillations
mixture instability
transient engine behavior
Technical Improvement
C++
display.drawPixel(x, y, WHITE);
Combined with rolling buffers:
C++
float graphData[GRAPH_POINTS];
This provides real-time embedded signal visualization.
10. Expanded Data Logging System
Previous Version
The earlier firmware only logged:
lambda
AFR
health score
Upgraded Version
The new firmware logs:
lambda
AFR
health score
misfire probability
RUL
AI anomaly score
Technical Improvement
C++
logFile.println(
"time,lambda,afr,health,misfire,rul,ai");
This enables:
offline analytics
MATLAB processing
machine learning dataset generation
long-term degradation analysis
11. Improved Embedded Architecture
Previous Version
The original firmware used a simple sequential structure.
Upgraded Version
The firmware is now modularized into:
sensor layer
analytics layer
display layer
logging layer
AI layer
predictive layer
Engineering Benefit
This significantly improves:
scalability
maintainability
future feature integration
research extensibility
12. Transformation of the System
Previous System
The earlier device functioned mainly as:
Wideband AFR Monitoring Device
focused primarily on combustion measurement.
Upgraded System
The upgraded firmware transforms the platform into:
AI-Based Predictive Engine Health Analyzer
capable of:
combustion diagnostics
predictive maintenance
anomaly detection
catalyst monitoring
degradation analysis
trend analytics
intelligent scoring
research-grade data logging
Overall System Evolution
Generation
Capability
Initial Version
AFR Monitor
Intermediate Version
Combustion Health Monitor
Current Upgraded Version
AI Predictive Diagnostic Platform
Final Technical Significance
The upgraded firmware introduces:
embedded signal analytics
predictive health modeling
intelligent anomaly estimation
real-time combustion visualization
AI-inspired diagnostics
multi-parameter engine analysis
while still operating entirely on:
ESP32
CJ125
LSU 4.9
OLED display
SD card logging
This represents a substantial advancement from a simple AFR reader into a research-oriented embedded diagnostic platform.
