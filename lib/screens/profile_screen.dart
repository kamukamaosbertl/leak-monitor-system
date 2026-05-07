import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// ─── PROFILE SCREEN ───────────────────────────────────────────────────────────
/// Accessible from both role dashboards via a profile icon / drawer.
/// Allows the user to edit phone and department.
/// Logout and Delete account both return the user to /login with the stack
/// fully cleared so they cannot press Back into the app.
/// ──────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = 'User';
  String email = '';
  String role = '';
  String phone = '';
  String department = '';

  bool notificationsEnabled = true;
  bool isLoading = true;
  bool isSaving = false;

  final phoneCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    phoneCtrl.dispose();
    departmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ApiService.me();
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        username =
            user['username']?.toString() ?? prefs.getString('username') ?? 'User';
        email = user['email']?.toString() ?? prefs.getString('email') ?? '';
        role = user['role']?.toString() ?? prefs.getString('role') ?? '';
        phone = user['phone_number']?.toString() ??
            prefs.getString('phone_number') ??
            '';
        department = user['department']?.toString() ??
            prefs.getString('department') ??
            '';

        phoneCtrl.text = phone;
        departmentCtrl.text = department;
        isLoading = false;
      });
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        username = prefs.getString('username') ?? 'User';
        email = prefs.getString('email') ?? '';
        role = prefs.getString('role') ?? '';
        phone = prefs.getString('phone_number') ?? '';
        department = prefs.getString('department') ?? '';

        phoneCtrl.text = phone;
        departmentCtrl.text = department;
        isLoading = false;
      });
    }
  }

  Future<void> _goBackHome() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = role.isNotEmpty ? role : prefs.getString('role') ?? '';

    if (!mounted) return;

    if (savedRole == 'admin') {
      Navigator.pushReplacementNamed(context, '/dashboard');
      return;
    }

    if (savedRole == 'technician') {
      Navigator.pushReplacementNamed(context, '/technician-dashboard');
      return;
    }

    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _saveProfile() async {
    setState(() => isSaving = true);

    try {
      await ApiService.setupProfile(
        role: role,
        phoneNumber: phoneCtrl.text.trim(),
        department: departmentCtrl.text.trim(),
      );

      await _loadProfile();

      if (!mounted) return;

      Navigator.pop(context);
      _showSnack('Profile updated');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not update profile');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: departmentCtrl,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveProfile,
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action cannot be undone. Your account will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteAccount();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not delete account');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String get _roleLabel {
    if (role == 'admin') return 'Admin';
    if (role == 'technician') return 'Technician';
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackHome();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackHome,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: isLoading ? null : _openEditSheet,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 46,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _roleLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          value: email.isEmpty ? 'Not provided' : email,
                        ),
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          title: 'Phone',
                          value: phone.isEmpty ? 'Not provided' : phone,
                        ),
                        _InfoTile(
                          icon: Icons.work_outline_rounded,
                          title: 'Department',
                          value: department.isEmpty
                              ? 'Not provided'
                              : department,
                        ),
                        _InfoTile(
                          icon: Icons.badge_outlined,
                          title: 'Role',
                          value: _roleLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications_outlined),
                          title: const Text('Notifications'),
                          subtitle: Text(
                            notificationsEnabled ? 'Enabled' : 'Disabled',
                          ),
                          value: notificationsEnabled,
                          onChanged: (v) {
                            setState(() => notificationsEnabled = v);
                            _showSnack(
                              v
                                  ? 'Notifications enabled'
                                  : 'Notifications disabled',
                            );
                          },
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          leading: Icon(Icons.privacy_tip_outlined),
                          title: Text('Privacy Policy'),
                          trailing: Icon(Icons.chevron_right),
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          leading: Icon(Icons.description_outlined),
                          title: Text('Terms & Conditions'),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout_rounded),
                          title: const Text('Logout'),
                          onTap: _logout,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.statusAlert,
                          ),
                          title: const Text(
                            'Delete my account',
                            style: TextStyle(color: AppColors.statusAlert),
                          ),
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}