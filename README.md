# Lumo

Lumo is an IoT self-watering plant system with:
- ESP32 firmware in `esp32/smartpot.ino`
- Flutter mobile app in `flutter_app/`
- Firebase Realtime Database for live status and control

## Project Structure
- `esp32/` : firmware for moisture sensing, pump control, and Firebase sync
- `flutter_app/` : Flutter app for monitoring and manual watering

## Quick Start

### 1) ESP32 Firmware
1. Open `esp32/smartpot.ino` in Arduino IDE.
2. Install board package: `esp32 by Espressif Systems`.
3. Install library: `Firebase ESP Client` (by Mobizt).
4. Update Wi-Fi and Firebase values in the config section.
5. Upload to ESP32 and open Serial Monitor at `115200`.

### 2) Flutter App
1. Go to `flutter_app/`.
2. Copy `android/app/google-services.example.json` to `android/app/google-services.json` and fill it with your Firebase project values.
3. Run:
   ```bash
   flutter pub get
   flutter run
   ```

## Notes
- App display name is set to `Lumo`.
- App icon is configured as a leaf icon source in `flutter_app/assets/app_icon_leaf.png`.
- Build outputs and local generated files are intentionally excluded from source control.
- `android/app/google-services.json` is intentionally not committed.