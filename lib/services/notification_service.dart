import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const String baseUrl = 'https://leak-monitor-backend.onrender.com/api';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _local.initialize(initSettings);

    FirebaseMessaging.onMessage.listen(showLocalNotification);
  }

  static Future<void> sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null || authToken.isEmpty) {
        debugPrint('Skipping FCM token upload: user not logged in.');
        return;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/device-token/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'token': token,
              'device_id': 'phone-1',
              'platform': 'android',
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('FCM token upload status: ${response.statusCode}');
      debugPrint('FCM token upload body: ${response.body}');
    } catch (error) {
      debugPrint('Token send failed: $error');
    }
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    await _local.show(
      message.hashCode,
      message.notification?.title ?? 'Leak Alert',
      message.notification?.body ?? 'Leak detected',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'leak_channel',
          'Leak Alerts',
          channelDescription: 'Notifications for leak alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}