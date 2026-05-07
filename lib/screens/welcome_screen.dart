import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// ─── WELCOME SCREEN ───────────────────────────────────────────────────────────
/// Shown ONCE after a user completes profile setup for the first time.
/// Pressing "Continue" clears the entire navigation stack and sends the user
/// to their role-appropriate dashboard, so they can never press Back to land
/// on the setup flow again.
/// ──────────────────────────────────────────────────────────────────────────────
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _goToDashboard(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final role  = prefs.getString('role') ?? '';

    if (!context.mounted) return;

    if (role == 'admin') {
      Navigator.pushNamedAndRemoveUntil(context, '/admin', (_) => false);
      return;
    }

    if (role == 'technician') {
      Navigator.pushNamedAndRemoveUntil(context, '/technician-dashboard', (_) => false);
      return;
    }

    // Fallback – unknown role.
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // No AppBar – this is a one-time celebration screen.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 70, color: AppColors.secondary),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your profile is ready. Let\'s get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _goToDashboard(context),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}