```text
┌──────────────────────────┐
                 │   BIKE 12V BATTERY       │
                 └──────────┬───────────────┘
                            │
                     [ 1A–3A FUSE ]
                            │
                 ┌──────────▼──────────┐
                 │  BUCK CONVERTER     │
                 │  12V → 5V STABLE    │
                 └──────────┬──────────┘
                            │ 5V
                 ┌──────────▼──────────┐
                 │       ESP32         │
                 │   (MAIN BRAIN)      │
                 └──────────┬──────────┘
                            │
     ┌──────────────────────┼────────────────────────┐
     │                      │                        │
┌────▼─────┐        ┌──────▼──────┐        ┌──────▼──────┐
│ OLED     │        │ VIBRATION   │        │  SD CARD    │
│ DISPLAY  │        │ SENSOR      │        │ (OPTIONAL)  │
└──────────┘        └─────────────┘        └─────────────┘
     │                      │                        │
 I2C (SDA/SCL)        GPIO32 / ADC        SPI (CS,SCK,MISO,MOSI)


                 ┌────────────────────────────┐
                 │   CJ125 LAMBDA MODULE     │
                 │ (with LSU 4.9 sensor)      │
                 └──────────┬─────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
     SPI SCK            SPI MISO           SPI MOSI
        │                   │                   │
        └────────────── ESP32 SPI ─────────────┘

     + 12V HEATER POWER (ONLY TO CJ125 MODULE)
     + ALL GNDs CONNECT TO COMMON GROUND
