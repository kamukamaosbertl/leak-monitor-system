import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LeakEvent {
  final int id;
  final String status;
  final String deviceId;
  final double flowIn;
  final double flowOut;
  final double delta;
  final double durationMinutes;
  final double waterLost;
  final double moneyLost;
  final String location;
  final DateTime timestamp;

  const LeakEvent({
    required this.id,
    required this.status,
    required this.deviceId,
    required this.flowIn,
    required this.flowOut,
    required this.delta,
    required this.durationMinutes,
    required this.waterLost,
    required this.moneyLost,
    required this.location,
    required this.timestamp,
  });

  factory LeakEvent.fromJson(Map<String, dynamic> json) {
    return LeakEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?)?.toLowerCase() ?? 'normal',
      deviceId: (json['device_id'] as String?) ?? 'unknown',
      flowIn: (json['flow_in'] as num?)?.toDouble() ?? 0.0,
      flowOut: (json['flow_out'] as num?)?.toDouble() ?? 0.0,
      delta: (json['delta'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble() ?? 0.0,
      waterLost: (json['water_lost'] as num?)?.toDouble() ?? 0.0,
      moneyLost: (json['money_lost'] as num?)?.toDouble() ?? 0.0,
      location: (json['location'] as String?) ?? 'Unknown',
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'device_id': deviceId,
      'flow_in': flowIn,
      'flow_out': flowOut,
      'delta': delta,
      'duration_minutes': durationMinutes,
      'water_lost': waterLost,
      'money_lost': moneyLost,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  LeakEvent copyWith({
    int? id,
    String? status,
    String? deviceId,
    double? flowIn,
    double? flowOut,
    double? delta,
    double? durationMinutes,
    double? waterLost,
    double? moneyLost,
    String? location,
    DateTime? timestamp,
  }) {
    return LeakEvent(
      id: id ?? this.id,
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      flowIn: flowIn ?? this.flowIn,
      flowOut: flowOut ?? this.flowOut,
      delta: delta ?? this.delta,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      waterLost: waterLost ?? this.waterLost,
      moneyLost: moneyLost ?? this.moneyLost,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'critical':
        return 'CRITICAL';
      case 'leak_detected':
        return 'LEAK DETECTED';
      case 'warning':
        return 'WARNING';
      default:
        return 'NORMAL';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'critical':
        return AppColors.statusCritical;
      case 'leak_detected':
        return AppColors.statusAlert;
      case 'warning':
        return AppColors.statusWarning;
      default:
        return AppColors.statusNormal;
    }
  }

  bool get isLeak => status == 'critical' || status == 'leak_detected';
}
