import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/zone_map_screen.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/users_screen.dart';
import 'screens/admin/system_settings_screen.dart';
import 'screens/admin/alert_responses_screen.dart';
import 'screens/admin/maintenance_requests_screen.dart';
import 'screens/admin/reports_screen.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Background title: ${message.notification?.title}');
  debugPrint('Background body: ${message.notification?.body}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.init();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;

  final notificationSettings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  debugPrint(
    'Notification permission status: ${notificationSettings.authorizationStatus}',
  );

  final fcmToken = await messaging.getToken();
  debugPrint('FCM Token: $fcmToken');

  if (fcmToken != null) {
    await NotificationService.sendTokenToBackend(fcmToken);
  }

  messaging.onTokenRefresh.listen((newToken) async {
    debugPrint('Refreshed FCM Token: $newToken');
    await NotificationService.sendTokenToBackend(newToken);
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    debugPrint('Foreground title: ${message.notification?.title}');
    debugPrint('Foreground body: ${message.notification?.body}');
    NotificationService.showLocalNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification opened app: ${message.messageId}');
  });

  final initialMessage = await messaging.getInitialMessage();

  if (initialMessage != null) {
    debugPrint('App opened from terminated state via notification.');
    debugPrint('Initial message ID: ${initialMessage.messageId}');
  }

  final settings = await SettingsProvider.init();

  runApp(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: const MyApp(),
    ),
  );
}

class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;

  const RoleGuard({super.key, required this.child, required this.allowedRoles});

  Future<bool> _isAllowed() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');
    final role = prefs.getString('role') ?? 'worker';

    if (token == null || token.isEmpty) {
      return false;
    }

    return allowedRoles.contains(role);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAllowed(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return const UnauthorizedScreen();
      },
    );
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return const LoginScreen();
      },
    );
  }
}

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  Future<void> _goHome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'worker';

    if (!context.mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role == 'technician') {
      Navigator.pushReplacementNamed(context, '/admin/maintenance');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Access Denied'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 70,
                color: AppColors.statusAlert,
              ),
              const SizedBox(height: 16),
              const Text(
                'You do not have permission to view this page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Contact the system administrator if you need access.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _goHome(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _auth(Widget child) => AuthGuard(child: child);

  Widget _roles(List<String> roles, Widget child) {
    return RoleGuard(allowedRoles: roles, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leak Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        // Public routes
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),

        // General protected routes
        '/home': (_) => _auth(const HomeScreen()),
        '/dashboard':
            (_) => _roles([
              'admin',
              'worker',
              'viewer',
              'technician',
            ], const DashboardScreen()),
        '/profile': (_) => _auth(const ProfileScreen()),
        '/support': (_) => _auth(const HelpSupportScreen()),

        // Worker/admin/viewer routes
        '/history':
            (_) => _roles(['admin', 'worker', 'viewer'], const HistoryScreen()),

        // Alert routes
        '/alerts':
            (_) =>
                _roles(['admin', 'worker', 'technician'], const AlertsScreen()),

        // Admin-only routes
        '/admin': (_) => _roles(['admin'], const AdminHomeScreen()),
        '/admin/users': (_) => _roles(['admin'], const UsersScreen()),
        '/admin/system': (_) => _roles(['admin'], const SystemSettingsScreen()),
        '/admin/responses':
            (_) => _roles(['admin'], const AlertResponsesScreen()),
        '/admin/reports': (_) => _roles(['admin'], const ReportsScreen()),
        '/settings': (_) => _roles(['admin'], const SettingsScreen()),
        '/map': (_) => _roles(['admin'], const ZoneMapScreen()),

        // Admin + technician
        '/admin/maintenance':
            (_) => _roles([
              'admin',
              'technician',
            ], const MaintenanceRequestsScreen()),
      },
    );
  }
}
