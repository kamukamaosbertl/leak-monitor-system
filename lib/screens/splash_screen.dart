import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// ─── SPLASH SCREEN ────────────────────────────────────────────────────────────
/// This is the GATEKEEPER of the entire app.
/// It runs every time the user opens the app and decides where to send them.
///
/// Decision tree:
///   1. No token stored          → /login
///   2. Token exists but backend
///      rejects it (expired /
///      deleted account)         → clear data → /login
///   3. Token valid but profile
///      not completed            → /profile-setup
///   4. Token valid, profile OK,
///      role = admin             → /admin
///   5. Token valid, profile OK,
///      role = technician        → /technician-dashboard
///   6. Token valid but unknown
///      role                     → clear data → /login
/// ──────────────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Give the splash logo a single frame to paint before we do async work.
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (!mounted) return;

    // ── 1. No token at all → go to login ──────────────────────────────────
    if (token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // ── 2. Token exists → verify with backend ─────────────────────────────
    try {
      // ApiService.me() hits /auth/me/ and saves the fresh user data to prefs.
      // If the token is expired or the account was deleted, it will throw.
      await ApiService.me();
    } catch (_) {
      // Token is invalid / account gone → wipe everything and send to login.
      await ApiService.clearAuthData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // ── 3. Token is valid → read the freshly-saved prefs ─────────────────
    final role             = prefs.getString('role') ?? '';
    final profileCompleted = prefs.getBool('profile_completed') ?? false;

    if (!mounted) return;

    if (!profileCompleted) {
      Navigator.pushReplacementNamed(context, '/profile-setup');
      return;
    }

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
      return;
    }

    if (role == 'technician') {
      Navigator.pushReplacementNamed(context, '/technician-dashboard');
      return;
    }

    // ── 6. Unknown role → treat as invalid ───────────────────────────────
    await ApiService.clearAuthData();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Leak Monitor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}