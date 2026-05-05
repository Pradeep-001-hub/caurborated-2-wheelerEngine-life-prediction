#include <Arduino.h>
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <SD.h>
#include "config.h"

Adafruit_SSD1306 display(128, 64, &Wire, -1);

bool   holdActive    = false;
bool   sensorReady   = false;
float  heldLambda    = 0.0f;
float  sessionMin    = 9.99f;
float  sessionMax    = 0.0f;
float  sessionSum    = 0.0f;
int    sessionCount  = 0;
unsigned long startMs   = 0;
unsigned long lastLogMs = 0;
File   logFile;

// ─── CJ125 SPI ─────────────────────────────────────────────
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

// ─── LAMBDA CALCULATION ────────────────────────────────────
float calcLambda() {
  int rawUN = analogRead(CJ125_UN_PIN);
  int rawIA = analogRead(CJ125_IA_PIN);

  float vUN = (rawUN / 4095.0f) * 3.3f;
  float vIA = (rawIA / 4095.0f) * 3.3f;

  float Ip_mA  = (vIA - 1.5f) / 0.1f;
  float lambda = 1.0f + (Ip_mA * 0.015f);
  lambda = constrain(lambda, 0.65f, 1.60f);
  return lambda;
}

// ─── DISPLAY ───────────────────────────────────────────────
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
  display.setCursor(30, 45);
  display.print("Wait: ");
  display.print(secondsLeft);
  display.print("s");
  display.display();
}

void showReading(float lambda) {
  float afr = lambda * STOICH_AFR;
  String status;
  if      (lambda < LAMBDA_RICH_LIMIT) status = "  RICH  ";
  else if (lambda > LAMBDA_LEAN_LIMIT) status = "  LEAN  ";
  else                                  status = "   OK   ";

  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 0);
  if (holdActive) display.println("     *** HOLD ***    ");
  else            display.println("  ENGINE HEALTH PROBE");
  display.drawLine(0, 10, 127, 10, WHITE);

  display.setCursor(0, 13);
  display.print("Lambda: ");
  display.setTextSize(2);
  display.setCursor(0, 22);
  display.print(lambda, 3);

  display.setTextSize(1);
  display.setCursor(75, 13);
  display.print("AFR:");
  display.setCursor(75, 23);
  display.print(afr, 1);

  display.fillRect(0, 42, 128, 12, WHITE);
  display.setTextColor(BLACK);
  display.setCursor(28, 44);
  display.setTextSize(1);
  display.print(status);
  display.setTextColor(WHITE);

  display.setCursor(0, 57);
  display.print("Lo:");
  display.print(sessionMin, 2);
  display.print(" Hi:");
  display.print(sessionMax, 2);

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

// ─── SD LOGGING ────────────────────────────────────────────
void initSD() {
  if (!ENABLE_SD) return;
  if (!SD.begin(SD_CS_PIN)) return;
  char fname[20];
  int idx = 0;
  do { sprintf(fname, "/session%02d.csv", idx++); }
  while (SD.exists(fname) && idx < 100);
  logFile = SD.open(fname, FILE_WRITE);
  if (logFile) {
    logFile.println("time_s,lambda,afr,status");
    logFile.flush();
  }
}

void logToSD(float lambda) {
  if (!ENABLE_SD || !logFile) return;
  unsigned long t = (millis() - startMs) / 1000;
  float afr = lambda * STOICH_AFR;
  String st = (lambda < LAMBDA_RICH_LIMIT) ? "RICH" :
              (lambda > LAMBDA_LEAN_LIMIT)  ? "LEAN" : "OK";
  logFile.print(t);        logFile.print(",");
  logFile.print(lambda, 4); logFile.print(",");
  logFile.print(afr, 2);   logFile.print(",");
  logFile.println(st);
  logFile.flush();
}

// ─── SETUP ─────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  pinMode(BTN_HOLD,  INPUT_PULLUP);
  pinMode(BTN_RESET, INPUT_PULLUP);

  SPI.begin(CJ125_SCK_PIN, CJ125_MISO_PIN, CJ125_MOSI_PIN);
  SPI.setFrequency(1000000);
  SPI.setDataMode(SPI_MODE1);
  pinMode(CJ125_CSN_PIN, OUTPUT);
  digitalWrite(CJ125_CSN_PIN, HIGH);

  analogReadResolution(12);

  Wire.begin(OLED_SDA, OLED_SCL);
  display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS);
  display.setTextColor(WHITE);
  display.clearDisplay();
  display.display();

  cj125Init();
  initSD();

  startMs = millis();
}

// ─── LOOP ──────────────────────────────────────────────────
void loop() {
  unsigned long now = millis();
  int elapsedSec = (now - startMs) / 1000;

  if (elapsedSec < WARMUP_SECONDS) {
    showWarmup(WARMUP_SECONDS - elapsedSec);
    delay(500);
    return;
  }

  if (!cj125Healthy()) {
    showError("CJ125 fault");
    delay(1000);
    return;
  }
  sensorReady = true;

  if (digitalRead(BTN_HOLD) == LOW) {
    holdActive = !holdActive;
    if (holdActive) heldLambda = calcLambda();
    delay(300);
  }

  if (digitalRead(BTN_RESET) == LOW) {
    sessionMin   = 9.99f;
    sessionMax   = 0.0f;
    sessionSum   = 0.0f;
    sessionCount = 0;
    holdActive   = false;
    startMs      = millis();
    delay(300);
    return;
  }

  float lambda = holdActive ? heldLambda : calcLambda();

  if (!holdActive) {
    sessionMin = min(sessionMin, lambda);
    sessionMax = max(sessionMax, lambda);
    sessionSum  += lambda;
    sessionCount++;
  }

  showReading(lambda);

  if (!holdActive && (now - lastLogMs >= 2000)) {
    logToSD(lambda);
    lastLogMs = now;
  }

  delay(200);
}