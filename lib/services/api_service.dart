import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leak_event.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ApiService {
  static const String baseUrl = 'https://leak-monitor-backend.onrender.com/api';

  static Future<List<LeakEvent>> fetchLeakEvents() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/leaks/history/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final decoded = json.decode(response.body);

      if (decoded is! List) {
        throw Exception('Invalid response format: expected a list');
      }

      return decoded
          .map((item) => LeakEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch leak events: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchAlertSettings() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/settings/alerts/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected an object');
      }

      return decoded;
    } catch (e) {
      throw Exception('Failed to fetch alert settings: $e');
    }
  }

  static Future<Map<String, dynamic>> updateAlertSettings({
    double? deltaThreshold,
    double? waterLostThreshold,
    int? durationThreshold,
  }) async {
    try {
      final Map<String, dynamic> payload = {};

      if (deltaThreshold != null) {
        payload['delta_threshold'] = deltaThreshold;
      }
      if (waterLostThreshold != null) {
        payload['water_lost_threshold'] = waterLostThreshold;
      }
      if (durationThreshold != null) {
        payload['duration_threshold'] = durationThreshold;
      }

      final response = await http
          .patch(
            Uri.parse('$baseUrl/settings/alerts/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected an object');
      }

      return decoded;
    } catch (e) {
      throw Exception('Failed to update alert settings: $e');
    }
  }

  static Future<void> updateLeakEvent({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/leaks/history/$id/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update leak event: $e');
    }
  }

  static Future<void> deleteLeakEvent(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/leaks/history/$id/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete leak event: $e');
    }
  }

  static Future<void> deleteAllLeakEvents() async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/leaks/history/clear/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete all leak events: $e');
    }
  }

  // ─────────────────────────────────────────────
  // NEW: Alert response tracking
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> respondToAlert({
    required int alertId,
    required int userId,
    required String action,
    String notes = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/alerts/$alertId/respond/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'action': action,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected an object');
      }

      return decoded;
    } catch (e) {
      throw Exception('Failed to respond to alert: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAlertResponses() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/alerts/responses/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = json.decode(response.body);

      if (decoded is! List) {
        throw Exception('Invalid response format: expected a list');
      }

      return decoded.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to fetch alert responses: $e');
    }
  }

  // ─────────────────────────────────────────────
  // NEW: Maintenance / call technician
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> callTechnician({
    required String deviceId,
    required String location,
    required int userId,
    String reason = 'Leak detected',
    String severity = 'critical',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/maintenance/call/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device_id': deviceId,
              'location': location,
              'user_id': userId,
              'reason': reason,
              'severity': severity,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 201) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected an object');
      }

      return decoded;
    } catch (e) {
      throw Exception('Failed to call technician: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMaintenanceRequests() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/maintenance/requests/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = json.decode(response.body);

      if (decoded is! List) {
        throw Exception('Invalid response format: expected a list');
      }

      return decoded.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to fetch maintenance requests: $e');
    }
  }

  static Future<Map<String, dynamic>> updateMaintenanceRequestStatus({
    required int requestId,
    required String statusValue,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/maintenance/requests/$requestId/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': statusValue}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected an object');
      }

      return decoded;
    } catch (e) {
      throw Exception('Failed to update maintenance request: $e');
    }
  }

  // ─────────────────────────────────────────────
  // NEW: Reports
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> generateLatestReport() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/reports/latest/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected an object');
      }

      return decoded;
    } catch (e) {
      throw Exception('Failed to generate latest report: $e');
    }
  }

  static Future<void> downloadLatestReportPdf() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/reports/latest/pdf/'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/latest_leak_report.pdf');

      await file.writeAsBytes(response.bodyBytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      throw Exception('Failed to download PDF report: $e');
    }
  }

  static Future<void> downloadLatestReportCsv() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/reports/latest/csv/'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/latest_leak_report.csv');

      await file.writeAsBytes(response.bodyBytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      throw Exception('Failed to download CSV report: $e');
    }
  }
  // ─────────────────────────────────────────────
  // NEW: Admin summary
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> fetchAdminSummary() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/admin/summary/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected an object');
      }

      return decoded;
    } catch (e) {
      throw Exception('Failed to fetch admin summary: $e');
    }
  }

  // 🔥 CLEAR DISMISSED ALERTS
  static Future<void> clearDismissedAlerts() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/alerts/clear-dismissed/'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear dismissed alerts');
    }
  }

  // 🔥 CLEAR RESOLVED ALERT RESPONSES
  static Future<void> clearResolvedResponses() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/alerts/responses/clear-resolved/'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear resolved responses');
    }
  }

  // 🔥 CLEAR COMPLETED MAINTENANCE REQUESTS
  static Future<void> clearCompletedMaintenance() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/maintenance/requests/clear-completed/'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear completed maintenance');
    }
  }
}
