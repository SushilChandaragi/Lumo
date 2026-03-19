// lib/models/watering_event.dart

class WateringEvent {
  final String key;
  final String time;
  final String type; // "Auto" or "Manual"

  const WateringEvent({
    required this.key,
    required this.time,
    required this.type,
  });

  factory WateringEvent.fromMap(String key, Map<dynamic, dynamic> map) {
    return WateringEvent(
      key:  key,
      time: map['time']?.toString() ?? 'Unknown',
      type: map['type']?.toString() ?? 'Unknown',
    );
  }
}

// ─────────────────────────────────────────────────────────────
class PlantStatus {
  final int    moisture;     // 0-100 percentage
  final String reservoir;   // "OK", "EMPTY", "FULL"
  final String lastWatered; // formatted timestamp
  final String alert;       // empty string = no alert

  const PlantStatus({
    required this.moisture,
    required this.reservoir,
    required this.lastWatered,
    required this.alert,
  });

  factory PlantStatus.empty() => const PlantStatus(
    moisture:    0,
    reservoir:  'OK',
    lastWatered: '—',
    alert:       '',
  );

  factory PlantStatus.fromMap(Map<dynamic, dynamic> map) {
    return PlantStatus(
      moisture:    int.tryParse(map['moisture']?.toString() ?? '0') ?? 0,
      reservoir:   map['reservoir']?.toString() ?? 'OK',
      lastWatered: map['last_watered']?.toString() ?? '—',
      alert:       map['alert']?.toString() ?? '',
    );
  }

  String get moistureLabel {
    if (moisture >= 70) return 'Well Watered';
    if (moisture >= 40) return 'Adequate';
    if (moisture >= 20) return 'Getting Dry';
    return 'Needs Water';
  }

  bool get isDry => moisture < 35;
}
