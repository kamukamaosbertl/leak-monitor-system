import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const String baseUrl = "https://leak-monitor-backend.onrender.com/api";

  static Future<void> init() async {
    // Request permission
    await _messaging.requestPermission();

    // Init local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _local.initialize(initSettings);

    // Get token and send to backend
    String? token = await _messaging.getToken();
    print("FCM TOKEN: $token");

    if (token != null) {
      await sendTokenToBackend(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      sendTokenToBackend(newToken);
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(message);
    });
  }

  static Future<void> sendTokenToBackend(String token) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/device-token/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": token,
          "device_id": "phone-1",
          "platform": "android",
        }),
      );
    } catch (e) {
      print("Token send failed: $e");
    }
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    await _local.show(
      0,
      message.notification?.title ?? "Leak Alert",
      message.notification?.body ?? "Leak detected",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'leak_channel',
          'Leak Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
