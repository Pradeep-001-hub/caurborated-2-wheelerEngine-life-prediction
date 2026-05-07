// ============================================================
// ENGINE HEALTH PREDICTION DEVICE - COMPLETE FIRMWARE
// ESP32 + CJ125 + LSU 4.9 + OLED + SD Card
// ============================================================

#include <Arduino.h>
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <SD.h>
#include <EEPROM.h>

// ============================================================
// CONFIGURATION
// ============================================================

// SPI / CJ125
#define CJ125_CSN_PIN     5
#define CJ125_SCK_PIN     18
#define CJ125_MOSI_PIN    23
#define CJ125_MISO_PIN    19
#define CJ125_UN_PIN      34
#define CJ125_IA_PIN      35

// I2C / OLED
#define OLED_SDA          21
#define OLED_SCL          22
#define OLED_ADDRESS      0x3C

// Buttons
#define BTN_HOLD          12
#define BTN_RESET         13

// SD Card
#define SD_CS_PIN         15
#define ENABLE_SD         true

// Sensor warmup
#define WARMUP_SECONDS    90

// AFR Constants
#define STOICH_AFR        14.7f
#define LAMBDA_LEAN_LIMIT 1.10f
#define LAMBDA_RICH_LIMIT 0.90f
#define LAMBDA_TARGET     1.0f

// CJ125 Register Definitions
#define CJ125_INIT_REG1   0x2800
#define CJ125_DIAG_REG    0x6C00

// Health Scoring Weights
#define WEIGHT_KNOCKING     0.45f
#define WEIGHT_COMBUSTION   0.35f
#define WEIGHT_TREND        0.20f

// Health Thresholds
#define KNOCK_SENSITIVITY   0.08f
#define COMBUSTION_THRESHOLD 0.12f
#define HISTORY_SIZE        100
#define BUFFER_SIZE         20

// EEPROM Addresses
#define EEPROM_BASELINE_ADDR 0
#define EEPROM_SIZE          512

// ============================================================
// GLOBAL VARIABLES
// ============================================================

Adafruit_SSD1306 display(128, 64, &Wire, -1);

// State variables
bool holdActive = false;
bool sensorReady = false;
bool baselineSet = false;
float heldLambda = 0.0f;
float sessionMin = 9.99f;
float sessionMax = 0.0f;
float sessionSum = 0.0f;
int sessionCount = 0;
float baselineLambda = 1.0f;
float currentHealthScore = 0.0f;

// Timing
unsigned long startMs = 0;
unsigned long lastLogMs = 0;

// Buffers for health calculation
float lambdaBuffer[BUFFER_SIZE];
int bufferIndex = 0;
float lambdaHistory[HISTORY_SIZE];
int historyIndex = 0;

// File handling
File logFile;

// ============================================================
// CJ125 COMMUNICATION
// ============================================================

uint16_t cj125Send(uint16_t data) {
  digitalWrite(CJ125_CSN_PIN, LOW);
  delayMicroseconds(10);
  uint16_t result = SPI.transfer16(data);
  delayMicroseconds(10);
  digitalWrite(CJ125_CSN_PIN, HIGH);
  return result;
}

void cj125Init() {
  cj125Send(CJ125_INIT_REG1);
  delay(100);
}

bool cj125Healthy() {
  uint16_t diag = cj125Send(CJ125_DIAG_REG);
  return (diag & 0xFF) == 0x28;
}

// ============================================================
// LAMBDA CALCULATION
// ============================================================

float calcLambda() {
  int rawUN = analogRead(CJ125_UN_PIN);
  int rawIA = analogRead(CJ125_IA_PIN);

  float vUN = (rawUN / 4095.0f) * 3.3f;
  float vIA = (rawIA / 4095.0f) * 3.3f;

  // CJ125 transfer function
  float Ip_mA = (vIA - 1.5f) / 0.1f;
  float lambda = 1.0f + (Ip_mA * 0.015f);
  lambda = constrain(lambda, 0.65f, 1.60f);
  
  return lambda;
}

// ============================================================
// HEALTH SCORING ALGORITHM
// ============================================================

// Update lambda history for trend analysis
void updateHistory(float lambda) {
  lambdaHistory[historyIndex] = lambda;
  historyIndex = (historyIndex + 1) % HISTORY_SIZE;
}

// Calculate variance (knock detection)
float calcVariance(float* data, int size) {
  if (size < 2) return 0;
  
  float mean = 0;
  for (int i = 0; i < size; i++) {
    mean += data[i];
  }
  mean /= size;
  
  float variance = 0;
  for (int i = 0; i < size; i++) {
    variance += (data[i] - mean) * (data[i] - mean);
  }
  
  return variance / size;
}

// Knocking score (45%) - detects rapid lambda oscillations
float calcKnockScore(float* lambdaData, int size) {
  float variance = calcVariance(lambdaData, size);
  
  if (variance > KNOCK_SENSITIVITY) {
    float score = 100.0f - (variance / KNOCK_SENSITIVITY) * 100.0f;
    return max(0.0f, score);
  }
  
  return 100.0f;
}

// Combustion quality score (35%) - deviation from stoichiometric
float calcCombustionScore(float lambda) {
  float deviation = abs(lambda - LAMBDA_TARGET);
  
  if (deviation > COMBUSTION_THRESHOLD) {
    float score = 100.0f - (deviation / COMBUSTION_THRESHOLD) * 100.0f;
    return max(0.0f, score);
  }
  
  return 100.0f;
}

// Trend degradation score (20%) - compares to baseline
float calcTrendScore() {
  if (!baselineSet) {
    return 100.0f;
  }
  
  // Calculate current average from history
  float currentAvg = 0;
  for (int i = 0; i < HISTORY_SIZE; i++) {
    currentAvg += lambdaHistory[i];
  }
  currentAvg /= HISTORY_SIZE;
  
  // Calculate drift from baseline
  float drift = abs(currentAvg - baselineLambda);
  float trendScore = 100.0f - (drift * 100.0f);
  
  return constrain(trendScore, 0.0f, 100.0f);
}

// Overall health score (weighted combination)
float calcHealthScore(float* lambdaData, int size) {
  float knockScore = calcKnockScore(lambdaData, size);
  float combustionScore = calcCombustionScore(lambdaData[size - 1]);
  float trendScore = calcTrendScore();
  
  float health = (WEIGHT_KNOCKING * knockScore) +
                 (WEIGHT_COMBUSTION * combustionScore) +
                 (WEIGHT_TREND * trendScore);
  
  return constrain(health, 0.0f, 100.0f);
}

// Set baseline lambda value (call after warmup)
void setBaseline() {
  float sum = 0;
  for (int i = 0; i < HISTORY_SIZE; i++) {
    sum += lambdaHistory[i];
  }
  baselineLambda = sum / HISTORY_SIZE;
  baselineSet = true;
  
  // Save to EEPROM
  saveBaselineToEEPROM(baselineLambda);
  
  Serial.print("Baseline set: ");
  Serial.println(baselineLambda, 3);
}

// Load baseline from EEPROM
void loadBaseline() {
  EEPROM.begin(EEPROM_SIZE);
  EEPROM.get(EEPROM_BASELINE_ADDR, baselineLambda);
  EEPROM.end();
  
  if (baselineLambda > 0.5f && baselineLambda < 1.5f) {
    baselineSet = true;
    Serial.print("Baseline loaded: ");
    Serial.println(baselineLambda, 3);
  }
}

// Save baseline to EEPROM
void saveBaselineToEEPROM(float baseline) {
  EEPROM.begin(EEPROM_SIZE);
  EEPROM.put(EEPROM_BASELINE_ADDR, baseline);
  EEPROM.commit();
  EEPROM.end();
}

// ============================================================
// DISPLAY FUNCTIONS
// ============================================================

void showWarmup(int secondsLeft) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("  ENGINE HEALTH PROBE");
  display.drawLine(0, 10, 127, 10, WHITE);
  display.setTextSize(2);
  display.setCursor(20, 20);
  display.print("WARMUP");
  display.setTextSize(1);
  display.setCursor(25, 45);
  display.print("Wait: ");
  display.print(secondsLeft);
  display.print("s");
  display.display();
}

void showReading(float lambda, float healthScore) {
  float afr = lambda * STOICH_AFR;
  String status;
  
  if (lambda < LAMBDA_RICH_LIMIT) {
    status = "  RICH  ";
  } else if (lambda > LAMBDA_LEAN_LIMIT) {
    status = "  LEAN  ";
  } else {
    status = "   OK   ";
  }

  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 0);
  
  if (holdActive) {
    display.println("     *** HOLD ***    ");
  } else {
    display.println("  ENGINE HEALTH PROBE");
  }
  
  display.drawLine(0, 10, 127, 10, WHITE);

  // Lambda display
  display.setCursor(0, 13);
  display.print("L:");
  display.setTextSize(2);
  display.setCursor(0, 22);
  display.print(lambda, 3);

  // AFR display
  display.setTextSize(1);
  display.setCursor(75, 13);
  display.print("AFR:");
  display.setCursor(75, 23);
  display.print(afr, 1);

  // Status bar
  display.fillRect(0, 42, 128, 12, WHITE);
  display.setTextColor(BLACK);
  display.setCursor(28, 44);
  display.setTextSize(1);
  display.print(status);
  display.setTextColor(WHITE);

  // Health score
  display.setCursor(0, 57);
  display.print("H:");
  display.print((int)healthScore);
  display.print("%");
  
  // Session stats
  display.setCursor(75, 57);
  display.print("L:");
  display.print(sessionMin, 2);

  display.display();
}

void showError(String msg) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(10, 20);
  display.println("  SENSOR ERROR");
  display.setCursor(10, 35);
  display.println(msg);
  display.display();
}

void showBaselineSet() {
  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(15, 20);
  display.println("BASELINE");
  display.setCursor(25, 40);
  display.println("SET");
  display.display();
  delay(2000);
}

// ============================================================
// SD CARD FUNCTIONS
// ============================================================

void initSD() {
  if (!ENABLE_SD) return;
  
  if (!SD.begin(SD_CS_PIN)) {
    Serial.println("SD card initialization failed!");
    return;
  }
  
  char fname[20];
  int idx = 0;
  
  do {
    sprintf(fname, "/session%02d.csv", idx++);
  } while (SD.exists(fname) && idx < 100);
  
  logFile = SD.open(fname, FILE_WRITE);
  
  if (logFile) {
    logFile.println("time_s,lambda,afr,health,status");
    logFile.flush();
    Serial.print("Logging to: ");
    Serial.println(fname);
  }
}

void logToSD(float lambda, float healthScore) {
  if (!ENABLE_SD || !logFile) return;
  
  unsigned long t = (millis() - startMs) / 1000;
  float afr = lambda * STOICH_AFR;
  
  String st = (lambda < LAMBDA_RICH_LIMIT) ? "RICH" :
              (lambda > LAMBDA_LEAN_LIMIT) ? "LEAN" : "OK";
  
  logFile.print(t);
  logFile.print(",");
  logFile.print(lambda, 4);
  logFile.print(",");
  logFile.print(afr, 2);
  logFile.print(",");
  logFile.print(healthScore, 1);
  logFile.print(",");
  logFile.println(st);
  
  logFile.flush();
}

// ============================================================
// SETUP
// ============================================================

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n=== ENGINE HEALTH PREDICTION DEVICE ===");
  Serial.println("Starting initialization...");

  // Button pins
  pinMode(BTN_HOLD, INPUT_PULLUP);
  pinMode(BTN_RESET, INPUT_PULLUP);

  // SPI for CJ125
  SPI.begin(CJ125_SCK_PIN, CJ125_MISO_PIN, CJ125_MOSI_PIN);
  SPI.setFrequency(1000000);
  SPI.setDataMode(SPI_MODE1);
  pinMode(CJ125_CSN_PIN, OUTPUT);
  digitalWrite(CJ125_CSN_PIN, HIGH);
  
  Serial.println("✓ SPI initialized");

  // ADC resolution
  analogReadResolution(12);
  
  Serial.println("✓ ADC initialized (12-bit)");

  // I2C / OLED
  Wire.begin(OLED_SDA, OLED_SCL);
  display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS);
  display.setTextColor(WHITE);
  display.clearDisplay();
  display.display();
  
  Serial.println("✓ OLED initialized");

  // CJ125 initialization
  cj125Init();
  
  Serial.println("✓ CJ125 initialized");

  // SD card
  initSD();
  
  Serial.println("✓ SD card ready");

  // Load baseline from EEPROM
  loadBaseline();
  
  Serial.println("✓ Baseline loaded");
  Serial.println("=== Ready to start ===\n");

  startMs = millis();
}

// ============================================================
// MAIN LOOP
// ============================================================

void loop() {
  unsigned long now = millis();
  int elapsedSec = (now - startMs) / 1000;

  // Warmup phase
  if (elapsedSec < WARMUP_SECONDS) {
    showWarmup(WARMUP_SECONDS - elapsedSec);
    delay(500);
    return;
  }

  // Check sensor health
  if (!cj125Healthy()) {
    showError("CJ125 fault");
    delay(1000);
    return;
  }
  
  sensorReady = true;

  // Set baseline after warmup (once)
  if (!baselineSet && elapsedSec == WARMUP_SECONDS) {
    setBaseline();
    showBaselineSet();
  }

  // Button: HOLD (freeze reading)
  if (digitalRead(BTN_HOLD) == LOW) {
    holdActive = !holdActive;
    if (holdActive) {
      heldLambda = calcLambda();
    }
    delay(300);
  }

  // Button: RESET (clear session stats)
  if (digitalRead(BTN_RESET) == LOW) {
    sessionMin = 9.99f;
    sessionMax = 0.0f;
    sessionSum = 0.0f;
    sessionCount = 0;
    holdActive = false;
    startMs = millis();
    delay(300);
    return;
  }

  // Read lambda
  float lambda = holdActive ? heldLambda : calcLambda();

  // Add to buffer for health calculation
  lambdaBuffer[bufferIndex] = lambda;
  bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;

  // Update history for trend analysis
  updateHistory(lambda);

  // Calculate health score
  currentHealthScore = calcHealthScore(lambdaBuffer, BUFFER_SIZE);

  // Update session statistics
  if (!holdActive) {
    sessionMin = min(sessionMin, lambda);
    sessionMax = max(sessionMax, lambda);
    sessionSum += lambda;
    sessionCount++;
  }

  // Display reading with health score
  showReading(lambda, currentHealthScore);

  // Log to SD card (every 2 seconds)
  if (!holdActive && (now - lastLogMs >= 2000)) {
    logToSD(lambda, currentHealthScore);
    lastLogMs = now;
  }

  delay(200);
}

