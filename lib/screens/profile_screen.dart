import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _criticalOnly = false;

  int? _userId;
  String _role = 'worker';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _userId = prefs.getInt('user_id');
      _nameController.text = prefs.getString('username') ?? 'User';
      _emailController.text = prefs.getString('email') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '+256 700 000 000';
      _role = prefs.getString('role') ?? 'worker';

      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _emailNotifications = prefs.getBool('emailNotifications') ?? true;
      _criticalOnly = prefs.getBool('criticalOnlyNotifications') ?? false;

      _isLoading = false;
    });
  }

  Future<void> _toggleEdit() async {
    if (_isEditing) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('username', _nameController.text.trim());
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('phone', _phoneController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    }

    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _setPushNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotifications', value);

    setState(() => _pushNotifications = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Push notifications enabled' : 'Push notifications disabled',
        ),
      ),
    );
  }

  Future<void> _setEmailNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emailNotifications', value);

    setState(() => _emailNotifications = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Email notifications enabled'
              : 'Email notifications disabled',
        ),
      ),
    );
  }

  Future<void> _setCriticalOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('criticalOnlyNotifications', value);

    setState(() => _criticalOnly = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Only critical notifications enabled'
              : 'All alert notifications enabled',
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('role');
    await prefs.remove('isLoggedIn');

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  String get _roleTitle {
    switch (_role.toLowerCase()) {
      case 'admin':
        return 'System Administrator';
      case 'technician':
        return 'Technician';
      case 'viewer':
        return 'Viewer';
      default:
        return 'Worker';
    }
  }

  String get _roleDescription {
    switch (_role.toLowerCase()) {
      case 'admin':
        return 'Full access to dashboard, alerts, responses, maintenance, reports, users, and settings.';
      case 'technician':
        return 'Can view assigned maintenance work, respond to alerts, and update repair progress.';
      case 'viewer':
        return 'Read-only access to dashboard and history.';
      default:
        return 'Can view dashboard, receive alerts, respond to incidents, and request technicians.';
    }
  }

  IconData get _roleIcon {
    switch (_role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'technician':
        return Icons.engineering_rounded;
      case 'viewer':
        return Icons.visibility_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  List<String> get _permissions {
    switch (_role.toLowerCase()) {
      case 'admin':
        return [
          'View dashboard',
          'Manage alerts',
          'View alert responses',
          'Track maintenance requests',
          'View reports',
          'Manage users and settings',
        ];
      case 'technician':
        return [
          'View alerts',
          'Respond to incidents',
          'Update maintenance status',
          'Mark repairs complete',
        ];
      case 'viewer':
        return ['View dashboard', 'View leak history', 'Read-only access'];
      default:
        return [
          'View dashboard',
          'Receive notifications',
          'Acknowledge alerts',
          'Respond to incidents',
          'Request technician support',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        title: const Text('My Profile'),
        actions: [
          TextButton(
            onPressed: _toggleEdit,
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAvatarSection(),
            const SizedBox(height: 16),
            _buildInfoSection(),
            const SizedBox(height: 16),
            _buildNotificationsSection(),
            const SizedBox(height: 16),
            _buildRoleSection(),
            const SizedBox(height: 16),
            _buildAccountSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      color: AppColors.primary,
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white30,
                child: Icon(Icons.person, size: 52, color: Colors.white),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _nameController.text.isEmpty ? 'User' : _nameController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _roleTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_userId != null) ...[
            const SizedBox(height: 6),
            Text(
              'User ID: $_userId',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return _SectionCard(
      title: 'Account Information',
      children: [
        _ProfileField(
          label: 'Full Name',
          controller: _nameController,
          icon: Icons.person_outline,
          enabled: _isEditing,
        ),
        const Divider(height: 1),
        _ProfileField(
          label: 'Email Address',
          controller: _emailController,
          icon: Icons.email_outlined,
          enabled: _isEditing,
          keyboardType: TextInputType.emailAddress,
        ),
        const Divider(height: 1),
        _ProfileField(
          label: 'Phone Number',
          controller: _phoneController,
          icon: Icons.phone_outlined,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _SectionCard(
      title: 'Notification Preferences',
      children: [
        SwitchListTile(
          value: _pushNotifications,
          title: const Text('Push Notifications'),
          subtitle: const Text('Receive leak alerts on this device'),
          secondary: const Icon(Icons.notifications_outlined),
          onChanged: _setPushNotifications,
        ),
        const Divider(height: 1),
        SwitchListTile(
          value: _criticalOnly,
          title: const Text('Critical Alerts Only'),
          subtitle: const Text('Only notify me when leaks are critical'),
          secondary: const Icon(Icons.priority_high_rounded),
          onChanged: _pushNotifications ? _setCriticalOnly : null,
        ),
        const Divider(height: 1),
        SwitchListTile(
          value: _emailNotifications,
          title: const Text('Email Notifications'),
          subtitle: const Text('Receive reports and summaries by email'),
          secondary: const Icon(Icons.email_outlined),
          onChanged: _setEmailNotifications,
        ),
      ],
    );
  }

  Widget _buildRoleSection() {
    return _SectionCard(
      title: 'Role & Permissions',
      children: [
        ListTile(
          leading: Icon(_roleIcon, color: AppColors.primary),
          title: Text(_roleTitle),
          subtitle: Text(_roleDescription),
          trailing: const Icon(
            Icons.lock_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children:
                _permissions
                    .map(
                      (permission) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: AppColors.accentGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                permission,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _SectionCard(
      title: 'Account',
      children: [
        ListTile(
          leading: const Icon(
            Icons.lock_reset_outlined,
            color: AppColors.statusAlert,
          ),
          title: const Text(
            'Change Password',
            style: TextStyle(color: AppColors.statusAlert),
          ),
          subtitle: const Text('Update your account password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showChangePasswordDialog,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(
            Icons.logout_rounded,
            color: AppColors.statusAlert,
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: AppColors.statusAlert),
          ),
          subtitle: const Text('Logout from this device'),
          onTap: _showSignOutDialog,
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final current = currentController.text.trim();
                final password = newController.text.trim();
                final confirm = confirmController.text.trim();

                if (current.isEmpty || password.isEmpty || confirm.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fill in all password fields'),
                    ),
                  );
                  return;
                }

                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }

                if (password != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password validation passed. Connect backend endpoint next.',
                    ),
                  ),
                );
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusAlert,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 6,
                  color: Color(0x0D000000),
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool enabled;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.enabled,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}
