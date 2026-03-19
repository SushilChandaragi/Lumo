# Lumo

Lumo is an IoT self-watering plant system with:
- ESP32 firmware in `esp32/smartpot.ino`
- Flutter app in `flutter_app/`
- Firebase Realtime Database for status and control

## Project Structure
- `esp32/` firmware for moisture sensing, pump control, and Firebase sync
- `flutter_app/` mobile app for monitoring and manual watering

## Quick Start

### ESP32
1. Open `esp32/smartpot.ino` in Arduino IDE.
2. Install board package `esp32 by Espressif Systems`.
3. Install library `Firebase ESP Client` by Mobizt.
4. Fill your Wi-Fi and Firebase values in the config section.
5. Upload and monitor logs at baud `115200`.

### Flutter
1. Go to `flutter_app/`.
2. Create `flutter_app/android/app/google-services.json` using `google-services.json.example`.
3. Update `flutter_app/lib/firebase_options.dart` with your own Firebase values.
4. Run:
   ```bash
   flutter pub get
   flutter run
   ```


Co-authored-by: Ankit Raj <ankitrajj23@gmail.com>
