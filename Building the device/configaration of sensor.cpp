#pragma once

// ─── SPI / CJ125 ───────────────────────────────────────────
#define CJ125_CSN_PIN     5
#define CJ125_SCK_PIN     18
#define CJ125_MOSI_PIN    23
#define CJ125_MISO_PIN    19
#define CJ125_UN_PIN      34
#define CJ125_IA_PIN      35

// ─── I2C / OLED ────────────────────────────────────────────
#define OLED_SDA          21
#define OLED_SCL          22
#define OLED_ADDRESS      0x3C

// ─── BUTTONS ───────────────────────────────────────────────
#define BTN_HOLD          12
#define BTN_RESET         13

// ─── SD CARD ───────────────────────────────────────────────
#define SD_CS_PIN         15
#define ENABLE_SD         true

// ─── SENSOR WARMUP ─────────────────────────────────────────
#define WARMUP_SECONDS    90

// ─── AFR CONSTANTS ─────────────────────────────────────────
#define STOICH_AFR        14.7f
#define LAMBDA_LEAN_LIMIT 1.10f
#define LAMBDA_RICH_LIMIT 0.90f

// ─── CJ125 REGISTER DEFS ───────────────────────────────────
#define CJ125_INIT_REG1   0x2800
#define CJ125_DIAG_REG    0x6C00