
------
PHASE 1 — Parts & Procurement
A. Sensor & Driver
Part
Spec
Source
Approx Cost
Bosch LSU 4.9 wideband O2 sensor
Genuine, 6-pin
Local auto parts / IndiaMart
₹1800–2500
CJ125 breakout board
With onboard LDO
AliExpress / Robu.in
₹400–600
B. Microcontroller & Display
Part
Spec
Source
Approx Cost
ESP32 DevKit v1
38-pin
Robu / Amazon
₹350–500
SSD1306 OLED
128×64, I2C
Robu / Amazon
₹150–200
C. Power
Part
Spec
Source
Approx Cost
LiPo battery
3.7V, 2000mAh, flat
Amazon / local RC shop
₹300–400
TP4056 module
With protection circuit (the blue 2-chip one)
Amazon / Robu
₹50
MT3608 boost converter
3.7V → 5V output
Amazon / Robu
₹60
D. Probe Hardware
Part
Spec
Notes
Stainless steel tube
304 grade, 16mm OD, 1mm wall, ~20cm long
Metal shop or plumbing supplier
M18×1.5 weld-on O2 sensor bung
Stainless
Exhaust shop or IndiaMart
Hose clamp
35–50mm adjustable
Hardware store
Silicone high-temp cable
6-wire, 60–80cm, rated >200°C
Auto electrical shop
Ceramic wool / heat wrap tape
For cable exit grommet
Auto shop
E. Enclosure & Misc
Part
Notes
ABS project box ~100×60×35mm
Local electronics shop
Rocker switch (SPST)
Power ON/OFF
Tactile pushbutton ×2
HOLD + RESET
SD card module (optional)
SPI, micro SD
Perfboard / small PCB
For wiring
M3 screws, standoffs, heat shrink, JST connectors
Hardware shop
------
PHASE 2 — Probe Tube Fabrication
This is the only part needing an outside person — an exhaust welder or fabricator.
What to tell the fabricator:
"I have a stainless M18×1.5 bung. I need you to weld it onto the side of this 16mm stainless tube, about 6–7cm from one end, at a slight angle (~15° toward the open end)."
Why the angle?
So exhaust gas flows across the sensor tip naturally rather than straight-on or dead-still.
After welding — you do this:
Thread the LSU 4.9 sensor into the bung hand-tight, then tighten with a 22mm wrench (40–50 Nm, firm but not brutal)
Route sensor cable out the rear end of the tube (away from the engine side)
Wrap ceramic wool around the cable exit point — this is your heat grommet
Wrap heat tape over the wool to secure it
Code
Hose clamp goes around the outside of the tailpipe to hold the probe in place.
PHASE 3 — Electronics Assembly
Step 1 — Understand the CJ125 board
Your CJ125 board handles all the complex LSU 4.9 stuff — heater PWM, pump current, Nernst voltage. You just talk to it over SPI.
CJ125 pins you care about:
| CJ125 Pin | Function |
|---|---|
| VCC | 12V (or 5V — check your board's regulator) |
| GND | Ground |
| CSN | SPI Chip Select |
| SCK | SPI Clock |
| MOSI | SPI data in |
| MISO | SPI data out |
| UN | Nernst cell voltage output (analog) |
| IA | Pump current output (analog) |
Most CJ125 breakout boards have a 5V LDO onboard — confirm yours before connecting.
Step 2 — Power architecture
Code
The LSU 4.9 heater needs ~12V ideally. However — CJ125 boards designed for 5V input do manage the heater with what's available. It will work at 5V input but warmup will be slower (~120 sec instead of ~20 sec). This is acceptable for your use case. If you want faster warmup, add a second MT3608 boosted to 12V only for the CJ125 heater rail.
PHASE 4 — Wiring
Full wiring table:
LSU 4.9 → CJ125 (standard pinout):
| LSU 4.9 Wire | Color | CJ125 Terminal |
|---|---|---|
| Pin 1 — IP | Black | IP |
| Pin 2 — VGND | Grey | VGND |
| Pin 3 — H- | White | H- |
| Pin 4 — H+ | Red | H+ |
| Pin 5 — VM | Yellow | VM |
| Pin 6 — UN | Green | UN |
CJ125 → ESP32:
| CJ125 | ESP32 GPIO |
|---|---|
| CSN | GPIO 5 |
| SCK | GPIO 18 |
| MOSI | GPIO 23 |
| MISO | GPIO 19 |
| UN (analog) | GPIO 34 |
| IA (analog) | GPIO 35 |
| GND | GND |
| VCC | 5V |
OLED → ESP32:
| OLED | ESP32 |
|---|---|
| SDA | GPIO 21 |
| SCL | GPIO 22 |
| VCC | 3.3V |
| GND | GND |
SD Card → ESP32 (optional):
| SD Module | ESP32 |
|---|---|
| CS | GPIO 15 |
| MOSI | GPIO 23 |
| SCK | GPIO 18 |
| MISO | GPIO 19 |
| VCC | 5V |
| GND | GND |
Buttons:
| Button | ESP32 GPIO | Other end |
|---|---|---|
| HOLD | GPIO 12 | GND (use INPUT_PULLUP) |
| RESET/SESSION | GPIO 13 | GND (use INPUT_PULLUP) |
Power switch: in series between LiPo (+) and MT3608 input.
------
PHASE 3 — First Run & Calibration
Before you power on:
[ ] Double-check all wiring against Phase 4 table
[ ] Confirm MT3608 output is 5V (measure with multimeter before connecting ESP32)
[ ] LSU 4.9 seated firmly in probe bung (torqued, not loose)
First power-on (bench, no exhaust):
Power ON → OLED should light up and show WARMUP screen
Wait 90 seconds → should transition to reading screen
At open air, lambda should read ~1.40–1.60 (excess oxygen, lean) — this is correct
Cover the sensor tip loosely with your hand → reading should shift slightly richer
On the bike:
Insert probe ~10cm into tailpipe, tighten hose clamp gently
Power ON device
Start engine, let idle
Wait for 90-second warmup countdown
Warm idle should read λ 0.95–1.05 on a healthy carbureted engine
Blip throttle → watch lambda swing rich briefly, then recover
Press HOLD to freeze a reading
Press RESET to start a fresh session
What readings mean:
Lambda
AFR (petrol)
Diagnosis
< 0.85
< 12.5
Very rich — choke stuck / float flooding
0.85–0.95
12.5–14.0
Rich — jets slightly large or air filter blocked
0.95–1.05
14.0–15.4
Healthy — near stoich
1.05–1.15
15.4–16.9
Lean — air leak or lean jetting
> 1.15
> 16.9
Very lean — serious air leak or fuel delivery issue
What to Build / Do Next (in order)
Order parts (1–3 days)
Get probe tube fabricated at exhaust shop (1 hour)
Bench test power circuit with multimeter
Upload firmware, verify OLED works
First live bike test

