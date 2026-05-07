import 'dart:async';

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

// Auth & onboarding
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/profile_screen.dart';

// Shared
import 'screens/alerts_screen.dart';
import 'screens/help_support_screen.dart';

// Admin
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/zone_map_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/users_screen.dart';
import 'screens/admin/system_settings_screen.dart';
import 'screens/admin/alert_responses_screen.dart';
import 'screens/admin/maintenance_requests_screen.dart';
import 'screens/admin/reports_screen.dart';

// ─── Background message handler ───────────────────────────────────────────────
// Must be a top-level function — Firebase requirement.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('BG message: ${message.messageId}');
}

// ─── Entry point ──────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar with dark icons.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Load persisted settings before the first frame.
  final settings = await SettingsProvider.init();

  runApp(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: const MyApp(),
    ),
  );

  // Set up Firebase + push notifications after the first frame so the app
  // paints immediately and the user is not blocked by permission dialogs.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_setupNotifications());
  });
}

// ─── Notification setup ───────────────────────────────────────────────────────
Future<void> _setupNotifications() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await NotificationService.init();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging  = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${permission.authorizationStatus}');

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await NotificationService.sendTokenToBackend(token);
    }

    // Keep the backend token fresh if FCM rotates it.
    messaging.onTokenRefresh.listen(NotificationService.sendTokenToBackend);

    // Show a local notification while the app is in the foreground.
    FirebaseMessaging.onMessage.listen(NotificationService.showLocalNotification);

    // Handle tap when the app was in the background.
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('Notification opened app: ${msg.messageId}');
    });
  } catch (e) {
    debugPrint('Notification setup failed: $e');
  }
}

// ─── AuthGuard ────────────────────────────────────────────────────────────────
// Wraps any route that requires a stored token.
// If no token is found the user is shown the LoginScreen instead.
//
// NOTE: This only checks the LOCAL token (fast, no network).
// The SplashScreen does the full backend verification once on app start.
class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late final Future<bool> _check = _hasToken();

  Future<bool> _hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data! ? widget.child : const LoginScreen();
      },
    );
  }
}

// ─── RoleGuard ────────────────────────────────────────────────────────────────
// Wraps any route that requires a specific role.
// If the stored role is not in [allowedRoles] the user sees UnauthorizedScreen.
// This is what stops a technician ever reaching an admin route.
class RoleGuard extends StatefulWidget {
  final Widget child;
  final List<String> allowedRoles;

  const RoleGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  late final Future<bool> _check = _isAllowed();

  Future<bool> _isAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final role  = prefs.getString('role') ?? '';

    if (token.isEmpty || role.isEmpty) return false;
    return widget.allowedRoles.contains(role);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data!) return widget.child;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final prefs = await SharedPreferences.getInstance();
          final role = prefs.getString('role') ?? '';

          if (!context.mounted) return;

          if (role == 'admin') {
            Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
          } else if (role == 'technician') {
            Navigator.pushNamedAndRemoveUntil(context, '/technician-dashboard', (_) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          }
        });

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// ─── UnauthorizedScreen ───────────────────────────────────────────────────────
// Shown when a user tries to access a route their role does not allow.
// "Go Home" sends them back to their own dashboard.
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  Future<void> _goHome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final role  = prefs.getString('role') ?? '';

    if (!context.mounted) return;

    if (role == 'admin') {
      Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
    } else if (role == 'technician') {
      Navigator.pushNamedAndRemoveUntil(context, '/technician-dashboard', (_) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Access Denied')),
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
                'You do not have permission\nto view this page.',
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
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MyApp ────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Shorthand helpers that keep the route table readable.
  Widget _auth(Widget child)               => AuthGuard(child: child);
  Widget _admin(Widget child)              => RoleGuard(allowedRoles: const ['admin'], child: child);
  Widget _technician(Widget child)         => RoleGuard(allowedRoles: const ['technician'], child: child);
  Widget _adminOrTech(Widget child)        => RoleGuard(allowedRoles: const ['admin', 'technician'], child: child);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leak Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',

      // ── Route table ──────────────────────────────────────────────────────
      //
      //  PUBLIC        → no guard        (anyone can land here)
      //  ONBOARDING    → _auth()         (token exists, role not confirmed yet)
      //  ADMIN ONLY    → _admin()        (role must be 'admin')
      //  TECH ONLY     → _technician()   (role must be 'technician')
      //  BOTH ROLES    → _adminOrTech()  (either role is fine)
      //
      // ─────────────────────────────────────────────────────────────────────
      routes: {
        // Public
        '/splash':        (_) => const SplashScreen(),
        '/login':         (_) => const LoginScreen(),
        '/signup':        (_) => const SignupScreen(),

        // Onboarding (token present but role may not be assigned yet)
        '/profile-setup': (_) => _auth(const ProfileSetupScreen()),
        '/welcome':       (_) => _auth(const WelcomeScreen()),

        // Both roles
        '/profile':       (_) => _adminOrTech(const ProfileScreen()),
        '/support':       (_) => _adminOrTech(const HelpSupportScreen()),
        '/alerts':        (_) => _adminOrTech(const AlertsScreen()),

        // Admin only
        '/admin':             (_) => _admin(const AdminHomeScreen()),
        '/admin/users':       (_) => _admin(const UsersScreen()),
        '/admin/system':      (_) => _admin(const SettingsScreen()),
        '/admin/responses':   (_) => _admin(const AlertResponsesScreen()),
        '/admin/maintenance': (_) => _admin(const MaintenanceRequestsScreen()),
        '/admin/reports':     (_) => _admin(const ReportsScreen()),
        '/dashboard':         (_) => _admin(const DashboardScreen()),
        '/history':           (_) => _admin(const HistoryScreen()),
        '/map':               (_) => _admin(const ZoneMapScreen()),

        // Technician only
        '/technician-dashboard': (_) => _technician(const MaintenanceRequestsScreen()),
      },
    );
  }
}