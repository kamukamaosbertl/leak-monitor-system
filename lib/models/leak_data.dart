// ─────────────────────────────────────────────
// Model: LeakData
// Holds all sensor readings for one snapshot
// ─────────────────────────────────────────────

enum LeakStatus { normal, warning, leakDetected, critical }

class LeakData {
  final String deviceId;
  final LeakStatus status;
  final double flowIn;
  final double flowOut;
  final double delta;
  final double durationMinutes;
  final double waterLost;
  final double moneyLost;
  final String location;
  final DateTime lastUpdated;

  const LeakData({
    required this.deviceId,
    required this.status,
    required this.flowIn,
    required this.flowOut,
    required this.delta,
    required this.durationMinutes,
    required this.waterLost,
    required this.moneyLost,
    required this.location,
    required this.lastUpdated,
  });

  // ── Build from Django WebSocket JSON ─────────
  factory LeakData.fromJson(Map<String, dynamic> json) {
    final double flowIn = (json['flow_in'] as num?)?.toDouble() ?? 0.0;
    final double flowOut = (json['flow_out'] as num?)?.toDouble() ?? 0.0;
    final double delta =
        (json['delta'] as num?)?.toDouble() ?? (flowIn - flowOut);

    // Map Django status string to enum
    final LeakStatus status = _parseStatus(json['status'] as String? ?? '');

    return LeakData(
      deviceId: json['device_id'] as String? ?? 'unknown',
      status: status,
      flowIn: flowIn,
      flowOut: flowOut,
      delta: delta,
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble() ?? 0.0,
      waterLost: (json['water_lost'] as num?)?.toDouble() ?? 0.0,
      moneyLost: (json['money_lost'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] as String? ?? 'Unknown',
      lastUpdated:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  bool get leakDetected =>
      status == LeakStatus.leakDetected || status == LeakStatus.critical;

  static LeakStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'leak_detected':
      case 'leak detected':
        return LeakStatus.leakDetected;
      case 'warning':
        return LeakStatus.warning;
      case 'critical':
        return LeakStatus.critical;
      default:
        return LeakStatus.normal;
    }
  }
}

// ─────────────────────────────────────────────
// Mock data — used as initial/fallback state
// ─────────────────────────────────────────────
final LeakData mockLeakData = LeakData(
  deviceId: 'unknown',
  status: LeakStatus.normal,
  flowIn: 0.0,
  flowOut: 0.0,
  delta: 0.0,
  durationMinutes: 0.0,
  waterLost: 0.0,
  moneyLost: 0.0,
  location: 'Waiting for sensor...',
  lastUpdated: DateTime.now(),
);
