import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/leak_event.dart';

class ApiService {
  static const String baseUrl = 'https://leak-monitor-backend.onrender.com/api';

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      if (auth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> _decodeResponse(http.Response response) async {
    debugPrint('API STATUS: ${response.statusCode}');

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    debugPrint('API ERROR BODY: ${response.body}');
    throw Exception('Server returned ${response.statusCode}: ${response.body}');
  }

  static bool _parseBool(dynamic value) {
    return value == true ||
        value == 'true' ||
        value == 1 ||
        value == '1';
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Future<void> _saveUserToPrefs(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    final profileRaw = user['profile_completed'] ??
        user['profileCompleted'] ??
        user['profile_complete'] ??
        user['is_profile_complete'];

    final profileCompleted = _parseBool(profileRaw);

    debugPrint('SAVING USER TO PREFS: $user');
    debugPrint('PROFILE COMPLETED RAW: $profileRaw');
    debugPrint('PROFILE COMPLETED SAVED: $profileCompleted');

    await prefs.setInt('user_id', _parseInt(user['id']));
    await prefs.setString('username', user['username']?.toString() ?? '');
    await prefs.setString('email', user['email']?.toString() ?? '');
    await prefs.setString('role', user['role']?.toString() ?? '');
    await prefs.setString('phone_number', user['phone_number']?.toString() ?? '');
    await prefs.setString('department', user['department']?.toString() ?? '');
    await prefs.setBool('profile_completed', profileCompleted);
  }

  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final tokens = data['tokens'];
    final user = data['user'];

    if (tokens is! Map<String, dynamic> || user is! Map<String, dynamic>) {
      throw Exception('Invalid auth response. Missing tokens or user.');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('auth_token', tokens['access']?.toString() ?? '');
    await prefs.setString('refresh_token', tokens['refresh']?.toString() ?? '');

    await _saveUserToPrefs(user);
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('role');
    await prefs.remove('phone_number');
    await prefs.remove('department');
    await prefs.remove('profile_completed');
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register/'),
          headers: await _headers(auth: false),
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = await _decodeResponse(response) as Map<String, dynamic>;
    await _saveAuthData(decoded);
    return decoded;
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login/'),
          headers: await _headers(auth: false),
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final decoded = await _decodeResponse(response) as Map<String, dynamic>;
    await _saveAuthData(decoded);
    return decoded;
  }

  static Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/google/'),
          headers: await _headers(auth: false),
          body: jsonEncode({'id_token': idToken}),
        )
        .timeout(const Duration(seconds: 45));

    final decoded = await _decodeResponse(response) as Map<String, dynamic>;
    await _saveAuthData(decoded);
    return decoded;
  }

  static Future<Map<String, dynamic>> setupProfile({
    required String role,
    required String phoneNumber,
    required String department,
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/auth/profile/setup/'),
          headers: await _headers(),
          body: jsonEncode({
            'role': role,
            'phone_number': phoneNumber,
            'department': department,
          }),
        )
        .timeout(const Duration(seconds: 15));

    await _decodeResponse(response);

    

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
    await prefs.setString('phone_number', phoneNumber);
    await prefs.setString('department', department);
    await prefs.setBool('profile_completed', true);

   return {
  'role': role,
  'phone_number': phoneNumber,
  'department': department,
  'profile_completed': true,
};
  }

  static Future<Map<String, dynamic>> me() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/auth/me/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = await _decodeResponse(response) as Map<String, dynamic>;
    await _saveUserToPrefs(decoded);
    return decoded;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await http
            .post(
              Uri.parse('$baseUrl/auth/logout/'),
              headers: await _headers(),
              body: jsonEncode({'refresh': refreshToken}),
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint('LOGOUT API ERROR: $e');
    }

    await clearAuthData();
  }

  static Future<void> deleteAccount() async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/auth/delete-account/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    await _decodeResponse(response);
    await clearAuthData();
  }

  static Future<void> registerDeviceToken({
    required String token,
    String? deviceId,
    String platform = 'android',
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/device-token/'),
          headers: await _headers(),
          body: jsonEncode({
            'token': token,
            'device_id': deviceId,
            'platform': platform,
          }),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<List<LeakEvent>> fetchLeakEvents() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/leaks/history/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = await _decodeResponse(response);

    if (decoded is! List) {
      throw Exception('Invalid response format: expected a list');
    }

    return decoded
        .map((item) => LeakEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateLeakEvent({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/leaks/history/$id/'),
          headers: await _headers(),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<void> deleteLeakEvent(int id) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/leaks/history/$id/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<void> deleteAllLeakEvents() async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/leaks/history/clear/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<List<Map<String, dynamic>>> fetchAlerts() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/alerts/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = await _decodeResponse(response);

    if (decoded is! List) {
      throw Exception('Invalid response format: expected a list');
    }

    return decoded.map((item) => item as Map<String, dynamic>).toList();
  }

  static Future<void> markAlertRead(int alertId) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/alerts/$alertId/read/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<void> dismissAlert(int alertId) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/alerts/$alertId/dismiss/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<void> markAllAlertsRead() async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/alerts/mark-all-read/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> respondToAlert({
    required int alertId,
    required int userId,
    required String action,
    String notes = '',
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/alerts/$alertId/respond/'),
          headers: await _headers(),
          body: jsonEncode({
            'user_id': userId,
            'action': action,
            'notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 10));

    return await _decodeResponse(response) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> fetchAlertResponses() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/alerts/responses/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = await _decodeResponse(response);

    if (decoded is! List) {
      throw Exception('Invalid response format: expected a list');
    }

    return decoded.map((item) => item as Map<String, dynamic>).toList();
  }

  static Future<void> clearDismissedAlerts() async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/alerts/clear-dismissed/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<void> clearResolvedResponses() async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/alerts/responses/clear-resolved/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> callTechnician({
    required String deviceId,
    required String location,
    required int userId,
    String reason = 'Leak detected',
    String severity = 'critical',
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/maintenance/call/'),
          headers: await _headers(),
          body: jsonEncode({
            'device_id': deviceId,
            'location': location,
            'user_id': userId,
            'reason': reason,
            'severity': severity,
          }),
        )
        .timeout(const Duration(seconds: 10));

    return await _decodeResponse(response) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> fetchMaintenanceRequests() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/maintenance/requests/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = await _decodeResponse(response);

    if (decoded is! List) {
      throw Exception('Invalid response format: expected a list');
    }

    return decoded.map((item) => item as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>> updateMaintenanceRequestStatus({
    required int requestId,
    required String statusValue,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/maintenance/requests/$requestId/'),
          headers: await _headers(),
          body: jsonEncode({'status': statusValue}),
        )
        .timeout(const Duration(seconds: 10));

    return await _decodeResponse(response) as Map<String, dynamic>;
  }

  static Future<void> clearCompletedMaintenance() async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/maintenance/requests/clear-completed/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    await _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> generateLatestReport() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/reports/latest/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    return await _decodeResponse(response) as Map<String, dynamic>;
  }

  static Future<void> downloadLatestReportPdf() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/reports/latest/pdf/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/latest_leak_report.pdf');

    await file.writeAsBytes(response.bodyBytes);
    await OpenFilex.open(file.path);
  }

  static Future<void> downloadLatestReportCsv() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/reports/latest/csv/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/latest_leak_report.csv');

    await file.writeAsBytes(response.bodyBytes);
    await OpenFilex.open(file.path);
  }

  static Future<Map<String, dynamic>> fetchAdminSummary() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/admin/summary/'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 10));

    return await _decodeResponse(response) as Map<String, dynamic>;
  }
}