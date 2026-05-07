import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// ─── LOGIN SCREEN ─────────────────────────────────────────────────────────────
/// Reached when:
///   • The user has never logged in (fresh install)
///   • The user explicitly logged out
///   • The user deleted their account
///   • The stored token was rejected by the backend on splash
///
/// NOT reached automatically once the user is authenticated.
///
/// After a successful login:
///   • profile_completed = false  → /profile-setup   (Google new users)
///   • role = admin               → /admin
///   • role = technician          → /technician-dashboard
/// ──────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _usernameCtrl   = TextEditingController();
  final _passwordCtrl   = TextEditingController();

  bool _isLoading       = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Routing helper ─────────────────────────────────────────────────────
  Future<void> _redirectAfterLogin() async {
    final prefs            = await SharedPreferences.getInstance();
    final role             = prefs.getString('role') ?? '';
    final profileCompleted = prefs.getBool('profile_completed') ?? false;

    if (!mounted) return;

    // New Google user or any user who skipped profile setup.
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

    // Unknown role – should not happen in production.
    await ApiService.clearAuthData();
    if (!mounted) return;
    _showSnack('Unknown account role. Please contact support.');
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ── Username / password sign-in ────────────────────────────────────────
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await ApiService.login(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      await _redirectAfterLogin();
    } catch (e) {
      if (!mounted) return;
      _showSnack(_loginError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google sign-in ─────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleLoading = true);

    try {
      final google     = GoogleSignIn.instance;
      await google.initialize();
      final googleUser = await google.authenticate();
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final firebaseUser =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await firebaseUser.user?.getIdToken();

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Missing Firebase ID token');
      }

      await ApiService.googleLogin(idToken: idToken);
      await _redirectAfterLogin();
    } catch (e) {
      if (!mounted) return;
      _showSnack(_googleError(e));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ── Error message helpers ──────────────────────────────────────────────
  String _loginError(Object e) {
    final t = e.toString().toLowerCase();
    if (t.contains('401') || t.contains('invalid credentials') || t.contains('unauthorized'))
      return 'Wrong username or password.';
    if (t.contains('timeout')) return 'Server is taking too long. Try again.';
    if (t.contains('socket') || t.contains('network') || t.contains('connection'))
      return 'No internet connection.';
    if (t.contains('500')) return 'Server error. Try again later.';
    return 'Login failed. Please try again.';
  }

  String _googleError(Object e) {
    final t = e.toString().toLowerCase();
    if (t.contains('canceled')) return 'Sign-in was cancelled.';
    if (t.contains('timeout'))  return 'Google sign-in timed out.';
    if (t.contains('network') || t.contains('connection'))
      return 'No internet connection.';
    return 'Google sign-in failed. Please try again.';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final busy = _isLoading || _isGoogleLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.water_drop_rounded, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text('Sign in to continue', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Username / email
                          TextFormField(
                            controller: _usernameCtrl,
                            enabled: !busy,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Email or Username'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Email or username is required' : null,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordCtrl,
                            enabled: !busy,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) { if (!busy) _signIn(); },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: busy ? null : () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 20),

                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: busy ? null : _signIn,
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Google button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: busy ? null : _signInWithGoogle,
                              child: _isGoogleLoading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Continue with Google'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: busy ? null : () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}