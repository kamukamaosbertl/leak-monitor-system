import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

/// ─── PROFILE SETUP SCREEN ─────────────────────────────────────────────────────
/// Reached when:
///   • A brand-new account is created (email/password signup)
///   • A Google user logs in for the FIRST time (profile_completed = false)
///
/// NOT reached on subsequent logins once profile_completed = true.
///
/// After completing setup → /welcome
/// The welcome screen then sends the user to their role dashboard.
/// ──────────────────────────────────────────────────────────────────────────────
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _phoneCtrl        = TextEditingController();
  final _departmentCtrl   = TextEditingController();

  String _selectedRole    = 'technician';
  bool   _isLoading       = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Send to backend.
      await ApiService.setupProfile(
        role:        _selectedRole,
        phoneNumber: _phoneCtrl.text.trim(),
        department:  _departmentCtrl.text.trim(),
      );

      // 2. Make sure prefs are up-to-date (ApiService.setupProfile already
      //    does this, but we write again for safety so the splash / welcome
      //    screen always reads the correct values).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_completed', true);
      await prefs.setString('role',        _selectedRole);
      await prefs.setString('phone_number', _phoneCtrl.text.trim());
      await prefs.setString('department',   _departmentCtrl.text.trim());

      if (!mounted) return;

      // 3. Go to the welcome screen (it handles the final role redirect).
      Navigator.pushReplacementNamed(context, '/welcome');
    } catch (e) {
      debugPrint('PROFILE SETUP ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile setup failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // No back button – the user MUST complete setup.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.water_drop_rounded, size: 52, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Set up profile',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Complete your account details',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Role
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: const [
                            DropdownMenuItem(value: 'admin',      child: Text('Admin')),
                            DropdownMenuItem(value: 'technician', child: Text('Technician')),
                          ],
                          onChanged: _isLoading
                              ? null
                              : (v) { if (v != null) setState(() => _selectedRole = v); },
                        ),
                        const SizedBox(height: 14),

                        // Phone
                        TextFormField(
                          controller: _phoneCtrl,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone Number'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Phone number is required';
                            if (v.trim().length < 7)           return 'Enter a valid phone number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Department
                        TextFormField(
                          controller: _departmentCtrl,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(labelText: 'Department'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Department is required' : null,
                        ),
                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _continue,
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}