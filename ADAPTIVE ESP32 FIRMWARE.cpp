#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define VIB_PIN 32
#define LAMBDA_PIN 34

#define OLED_SDA 21
#define OLED_SCL 22
#define OLED_ADDR 0x3C

Adafruit_SSD1306 display(128, 64, &Wire, -1);

enum BikeMode { IDLE, REV, RIDE };
enum SysState { WARMUP, LEARN, RUN };

SysState state = WARMUP;
BikeMode mode = IDLE;

float baseLambda = 1.0;
float baseVib = 0.0;

#define BUF 10
float lambdaBuf[BUF];
int lidx = 0;

#define VBUF 64
float vibBuf[VBUF];
int vidx = 0;

float lastLambda = 1.0;

float stableCount = 0;

float readLambda() {
  int r = analogRead(LAMBDA_PIN);
  float v = (r / 4095.0) * 3.3;
  return constrain(1.0 + (v - 1.5) * 0.25, 0.7, 1.3);
}

float readVib() {
  int r = analogRead(VIB_PIN);
  return (r / 4095.0) * 3.3;
}

float filterLambda(float x) {
  lambdaBuf[lidx++] = x;
  if (lidx >= BUF) lidx = 0;

  float s = 0;
  for (int i = 0; i < BUF; i++) s += lambdaBuf[i];
  return s / BUF;
}

void addVib(float v) {
  vibBuf[vidx++] = v;
  if (vidx >= VBUF) vidx = 0;
}

float vibEnergy() {
  float e = 0;
  for (int i = 1; i < VBUF; i++) {
    float d = vibBuf[i] - vibBuf[i - 1];
    e += d * d;
  }
  return e / VBUF;
}

float lambdaVar() {
  float m = 0;
  for (int i = 0; i < BUF; i++) m += lambdaBuf[i];
  m /= BUF;

  float v = 0;
  for (int i = 0; i < BUF; i++) {
    float d = lambdaBuf[i] - m;
    v += d * d;
  }
  return v / BUF;
}

float rocLambda(float cur) {
  float r = abs(cur - lastLambda);
  lastLambda = cur;
  return r;
}

BikeMode detectMode(float ve, float lv, float roc) {

  if (ve < 0.2 && lv < 0.01) return IDLE;
  if (ve > 0.5 || roc > 0.05) return REV;
  return RIDE;
}

BikeMode stableMode(BikeMode m) {
  static BikeMode last = IDLE;
  static int c = 0;

  if (m == last) c++;
  else c = 0;

  if (c > 5) last = m;

  return last;
}

void adaptiveLearn(float l, float v, BikeMode m) {

  if (m == IDLE && state == LEARN) {

    baseLambda = 0.98 * baseLambda + 0.02 * l;
    baseVib = 0.98 * baseVib + 0.02 * v;

    stableCount++;
  }

  if (stableCount > 200) state = RUN;
}

float health(float l, float v) {

  float le = abs(l - baseLambda);
  float ve = abs(v - baseVib);

  float h = 100 - (le * 120) - (ve * 80);

  if (mode == REV) h *= 0.8;
  if (mode == IDLE) h *= 1.05;

  return constrain(h, 0, 100);
}

void show(float l, float h) {

  display.clearDisplay();
  display.setTextSize(1);

  display.setCursor(0,0);
  display.print("MODE: ");
  if (mode == IDLE) display.print("IDLE");
  if (mode == REV) display.print("REV");
  if (mode == RIDE) display.print("RIDE");

  display.setCursor(0,15);
  display.print("Lambda: ");
  display.print(l, 3);

  display.setCursor(0,30);
  display.print("Health: ");
  display.print(h, 1);

  display.setCursor(0,45);

  if (h > 80) display.print("GOOD");
  else if (h > 50) display.print("OK");
  else display.print("FAULT");

  display.display();
}

void setup() {
  Serial.begin(115200);

  Wire.begin(OLED_SDA, OLED_SCL);
  display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR);

  display.clearDisplay();
  display.display();

  state = LEARN;
}

void loop() {

  float rawL = readLambda();
  float l = filterLambda(rawL);

  float v = readVib();
  addVib(v);

  float ve = vibEnergy();
  float lv = lambdaVar();
  float roc = rocLambda(l);

  BikeMode m = detectMode(ve, lv, roc);
  mode = stableMode(m);

  adaptiveLearn(l, v, mode);

  if (state == RUN) {
    float h = health(l, v);
    show(l, h);
  }

  delay(100);
}