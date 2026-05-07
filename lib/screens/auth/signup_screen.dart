import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// ─── SIGNUP SCREEN ────────────────────────────────────────────────────────────
/// Reached ONLY from the Login screen via "Create account".
///
/// After a successful registration the backend returns a token.
/// We ALWAYS go to /profile-setup next because a brand-new account
/// can never have a completed profile yet.
/// ──────────────────────────────────────────────────────────────────────────────
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  bool _isLoading      = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await ApiService.register(
        username: _usernameCtrl.text.trim(),
        email:    _emailCtrl.text.trim().toLowerCase(),
        password: _passwordCtrl.text.trim(),
      );

      // New accounts always need profile setup.
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/profile-setup');
    } catch (e) {
      if (!mounted) return;
      _showSnack(_signupError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _signupError(Object e) {
    final t = e.toString().toLowerCase();
    if (t.contains('username') && (t.contains('already') || t.contains('exists')))
      return 'Username already taken. Try another.';
    if (t.contains('email') && (t.contains('already') || t.contains('exists') || t.contains('registered')))
      return 'Email already registered. Sign in instead.';
    if (t.contains('timeout'))   return 'Server took too long. Try again.';
    if (t.contains('socket') || t.contains('network') || t.contains('connection'))
      return 'No internet connection.';
    if (t.contains('500'))       return 'Server error. Try again later.';
    return 'Could not create account. Please try again.';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 40),
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
                  'Create account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text('Sign up to get started', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Username
                          TextFormField(
                            controller: _usernameCtrl,
                            enabled: !_isLoading,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Username'),
                            validator: (v) {
                              final u = v?.trim() ?? '';
                              if (u.isEmpty)  return 'Username is required';
                              if (u.length < 3) return 'At least 3 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: (v) {
                              final e = v?.trim() ?? '';
                              if (e.isEmpty) return 'Email is required';
                              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(e))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordCtrl,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) { if (!_isLoading) _createAccount(); },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'At least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _createAccount,
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Create Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Back to Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}