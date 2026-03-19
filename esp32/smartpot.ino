/*
 * SmartPot - Self Watering Plant System
 * ======================================
 * Hardware: ESP32, Capacitive Moisture Sensor, Relay, Mini Water Pump
 * Cloud:    Firebase Realtime Database
 * Power:    5V USB Wall Adapter (No battery needed for now)
 *
 * PIN LAYOUT:
 *   GPIO 34  -> Moisture Sensor AOUT (Analog Input)
 *   GPIO 25  -> Relay IN (to control pump)
 *   GPIO 26  -> HIGH-water probe (Reservoir FULL detector)
 *   GPIO 27  -> LOW-water probe  (Reservoir EMPTY detector)
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <time.h>

// =====================================================================
//  CONFIGURATION  — Fill these in
// =====================================================================
#define WIFI_SSID     "YOUR_WIFI_SSID"       // fill in your WiFi name
#define WIFI_PASS     "YOUR_WIFI_PASSWORD"   // fill in your WiFi password
#define API_KEY       "YOUR_FIREBASE_WEB_API_KEY"
#define DATABASE_URL  "https://smartpotnyxora-default-rtdb.asia-southeast1.firebasedatabase.app"

// =====================================================================
//  FEATURE FLAGS
// =====================================================================
// Set to true only after you physically wire the two water-level probes
// to GPIO 26 and GPIO 27. Keep false for now — pump will work without them.
#define USE_WATER_PROBES false

// =====================================================================
//  PIN DEFINITIONS
// =====================================================================
const int MOISTURE_PIN   = 34;   // Capacitive sensor analog output
const int RELAY_PIN      = 25;   // Relay control input
const int PROBE_LOW_PIN  = 27;   // LOW-water probe  (reservoir EMPTY)
const int PROBE_HIGH_PIN = 26;   // HIGH-water probe (reservoir FULL)

// =====================================================================
//  THRESHOLDS — calibrated from your physical BLE tests
// =====================================================================
// These match the values you tested with in your BLE code:
//   wetValue = 1200  (sensor submerged in water)
//   dryValue = 2600  (sensor in dry soil)
const int RAW_WATER              = 1200;  // sensor reading in water
const int RAW_AIR                = 3900;  // sensor reading in open air
const int MOISTURE_DRY_THRESHOLD = 2600;  // above this raw value → soil is dry → water it
const int PUMP_ON_SECONDS        = 3;     // seconds pump runs per cycle (same as BLE code)
const unsigned long PUMP_COOLDOWN_MS = 15000; // ms to wait after watering before re-checking

// =====================================================================
//  FIREBASE OBJECTS
// =====================================================================
FirebaseData   fbdo_write;
FirebaseData   fbdo_read;
FirebaseAuth   auth;
FirebaseConfig config;

// =====================================================================
//  STATE
// =====================================================================
bool          firebaseReady      = false;
unsigned long lastUploadMs        = 0;
const unsigned long UPLOAD_INTERVAL_MS = 3000; // Send sensor data every 3 seconds

// =====================================================================
//  HELPERS
// =====================================================================

// Returns a formatted IST timestamp string  e.g. "2026-03-08 14:30:05"
String getTimestamp() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "N/A";
  
  char buf[25];
  strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", &timeinfo);
  return String(buf);
}

// Returns moisture as a 0-100 percentage (100 = very wet, 0 = very dry)
int moisturePercent(int rawValue) {
  int pct = map(rawValue, RAW_AIR, RAW_WATER, 0, 100);
  return constrain(pct, 0, 100);
}

// Reads both water-level probes, returns "EMPTY", "OK", or "FULL"
//
// Probe wiring: one wire to GPIO (INPUT_PULLUP), other wire to GND.
// When the probe is submerged, water bridges GPIO to GND → pin reads LOW.
//
//  PROBE_LOW_PIN  — sit at the *bottom* of the reservoir (min safe level)
//  PROBE_HIGH_PIN — sit at the *top* (max safe level / overflow point)
//
//  Both HIGH → water below both probes → EMPTY
//  Low=LOW, High=HIGH → water between probes → OK
//  Both LOW → water above both probes → FULL
String reservoirStatus() {
#if USE_WATER_PROBES
  bool lowProbeWet  = (digitalRead(PROBE_LOW_PIN)  == LOW);
  bool highProbeWet = (digitalRead(PROBE_HIGH_PIN) == LOW);
  if (!lowProbeWet && !highProbeWet) return "EMPTY";
  if (lowProbeWet  && !highProbeWet) return "OK";
  return "FULL";
#else
  // Probes not wired yet — always report OK so pump is not blocked
  return "OK";
#endif
}

// Activate the water pump for PUMP_ON_SECONDS and log to Firebase history
void runPump(const String& triggerType) {
  Serial.printf("[PUMP] Running for %d seconds (trigger: %s)\n",
                PUMP_ON_SECONDS, triggerType.c_str());

  String ts = getTimestamp();

  // Turn pump ON (relay is ACTIVE-LOW: LOW = ON)
  digitalWrite(RELAY_PIN, LOW);
  delay(PUMP_ON_SECONDS * 1000);
  // Turn pump OFF
  digitalWrite(RELAY_PIN, HIGH);

  Serial.println("[PUMP] Stopped.");

  if (!firebaseReady) return;

  // Update last_watered timestamp
  Firebase.RTDB.setString(&fbdo_write, "/status/last_watered", ts);

  // Push a history event
  FirebaseJson event;
  event.add("time",    ts);
  event.add("type",    triggerType);
  Firebase.RTDB.pushJSON(&fbdo_write, "/history", &event);
}

// =====================================================================
//  SETUP
// =====================================================================
void setup() {
  Serial.begin(115200);

  // --- Pin modes ---
  pinMode(RELAY_PIN, OUTPUT);
#if USE_WATER_PROBES
  pinMode(PROBE_LOW_PIN,  INPUT_PULLUP);
  pinMode(PROBE_HIGH_PIN, INPUT_PULLUP);
#endif

  // Safety default: relay OFF (HIGH = relay coil off for active-low modules)
  digitalWrite(RELAY_PIN, HIGH);

  // --- WiFi ---
  Serial.printf("\n[WiFi] Connecting to %s", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\n[WiFi] Connected. IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("\n[WiFi] FAILED — running in offline mode.");
  }

  // --- NTP Time (IST = UTC+5:30 = 19800 seconds) ---
  configTime(19800, 0, "pool.ntp.org", "time.nist.gov");
  Serial.println("[Time] Syncing NTP...");
  struct tm t;
  if (getLocalTime(&t, 5000)) {
    Serial.printf("[Time] OK: %s\n", getTimestamp().c_str());
  } else {
    Serial.println("[Time] Could not sync, timestamps may show N/A");
  }

  // --- Firebase ---
  // Using open DB rules (no auth required) — simpler and avoids SSL issues
  config.database_url = DATABASE_URL;
  config.signer.test_mode = true;  // Skip authentication entirely

  Firebase.reconnectWiFi(true);
  Firebase.begin(&config, &auth);

  // Wait for Firebase to be ready
  Serial.print("[Firebase] Connecting");
  unsigned long fbStart = millis();
  while (!Firebase.ready() && (millis() - fbStart) < 10000) {
    delay(500);
    Serial.print(".");
  }

  if (Firebase.ready()) {
    Serial.println("\n[Firebase] Ready.");
    firebaseReady = true;
    // Reset manual trigger on boot so a stale value doesn't fire the pump
    Firebase.RTDB.setInt(&fbdo_write, "/control/manual_trigger", 0);
  } else {
    Serial.println("\n[Firebase] NOT connected — offline mode.");
  }

  Serial.println("[Setup] Complete. SmartPot is running.\n");
}

// =====================================================================
//  MAIN LOOP
// =====================================================================
void loop() {
  unsigned long now = millis();

  // Read sensors
  int    rawMoisture = analogRead(MOISTURE_PIN);
  int    pctMoisture = moisturePercent(rawMoisture);
  String resvStatus  = reservoirStatus();

  Serial.printf("[Sensor] Moisture=%d%% (raw:%d)  Reservoir=%s\n",
                pctMoisture, rawMoisture, resvStatus.c_str());

  // ---- Upload to Firebase every UPLOAD_INTERVAL_MS ----
  if (firebaseReady && (now - lastUploadMs >= UPLOAD_INTERVAL_MS)) {
    lastUploadMs = now;
    Firebase.RTDB.setInt   (&fbdo_write, "/status/moisture",    pctMoisture);
    Firebase.RTDB.setString(&fbdo_write, "/status/reservoir",   resvStatus);
    Firebase.RTDB.setInt   (&fbdo_write, "/status/moisture_raw", rawMoisture);
  }

  // ---- Check for manual trigger from Flutter app ----
  if (firebaseReady) {
    if (Firebase.RTDB.getInt(&fbdo_read, "/control/manual_trigger")) {
      if (fbdo_read.intData() == 1) {
        Serial.println("[Control] Manual trigger received from app.");

        if (resvStatus == "EMPTY") {
          // Reservoir is dry — do NOT run pump, notify app
          Firebase.RTDB.setString(&fbdo_write, "/status/alert",
                                   "Reservoir empty! Refill before watering.");
          Serial.println("[Pump] Skipped — reservoir empty.");
        } else {
          Firebase.RTDB.setString(&fbdo_write, "/status/alert", "");
          runPump("Manual");
        }

        // Always reset the trigger so the pump doesn't loop
        Firebase.RTDB.setInt(&fbdo_write, "/control/manual_trigger", 0);
        delay(PUMP_COOLDOWN_MS);
        return; // Skip auto-water check this cycle
      }
    }
  }

  // ---- Auto Watering Logic ----
  // Only water if: raw sensor value is above dry threshold AND reservoir is not empty
  if (rawMoisture > MOISTURE_DRY_THRESHOLD && resvStatus != "EMPTY") {

    Serial.printf("[Auto] Soil is dry (%d%%), auto-watering...\n", pctMoisture);

    if (firebaseReady) {
      Firebase.RTDB.setString(&fbdo_write, "/status/alert", "");
    }

    runPump("Auto");
    delay(PUMP_COOLDOWN_MS); // Let water soak in before checking again
  }

  // ---- Warn if reservoir is full (overflow risk) ----
  if (resvStatus == "FULL" && firebaseReady) {
    Firebase.RTDB.setString(&fbdo_write, "/status/alert",
                             "Reservoir is full — check for overflow!");
  }

  delay(1000); // Main loop cadence
}
