// lib/services/firebase_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/watering_event.dart';

class FirebaseService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ── Streams ─────────────────────────────────────────────────────────────

  /// Emits [PlantStatus] whenever any /status/* field changes
  static Stream<PlantStatus> statusStream() {
    return _db
        .ref('/status')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null) return PlantStatus.empty();
          return PlantStatus.fromMap(data as Map<dynamic, dynamic>);
        });
  }

  /// Emits the full sorted history list whenever /history changes
  static Stream<List<WateringEvent>> historyStream() {
    return _db
        .ref('/history')
        .orderByKey()
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null) return <WateringEvent>[];

          final map = data as Map<dynamic, dynamic>;
          final list = map.entries
              .map((e) => WateringEvent.fromMap(
                    e.key.toString(),
                    e.value as Map<dynamic, dynamic>,
                  ))
              .toList();

          // Most recent first
          list.sort((a, b) => b.time.compareTo(a.time));
          return list;
        });
  }

  // ── Commands ─────────────────────────────────────────────────────────────

  /// Tells the ESP32 to water the plant manually
  static Future<void> triggerManualWatering() async {
    await _db.ref('/control/manual_trigger').set(1);
  }

  /// Dismiss an alert from the app side
  static Future<void> clearAlert() async {
    await _db.ref('/status/alert').set('');
  }

  /// Delete a single history entry (optional)
  static Future<void> deleteHistoryEvent(String key) async {
    await _db.ref('/history/$key').remove();
  }
}
