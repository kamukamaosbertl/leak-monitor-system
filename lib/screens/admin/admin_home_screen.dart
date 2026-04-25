import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _isCheckingRole = true;
  String _userRole = 'worker';

  bool get _isAdmin => _userRole == 'admin';

  final List<_AdminItem> _items = const [
    _AdminItem(
      title: 'Alert Responses',
      subtitle: 'See who acknowledged, responded, or resolved alerts',
      icon: Icons.assignment_turned_in_rounded,
      route: '/admin/responses',
    ),
    _AdminItem(
      title: 'Maintenance Requests',
      subtitle: 'Track technician requests and repair progress',
      icon: Icons.engineering_rounded,
      route: '/admin/maintenance',
    ),
    _AdminItem(
      title: 'Manage Users',
      subtitle: 'Manage admins, workers, technicians, and viewers',
      icon: Icons.people_alt_rounded,
      route: '/admin/users',
    ),
    _AdminItem(
      title: 'Reports',
      subtitle: 'View leak reports and incident summaries',
      icon: Icons.description_rounded,
      route: '/admin/reports',
    ),
    _AdminItem(
      title: 'System Settings',
      subtitle: 'Configure thresholds and system behavior',
      icon: Icons.settings_rounded,
      route: '/admin/system',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'worker';

    if (!mounted) return;

    if (role != 'admin') {
      Navigator.pushReplacementNamed(context, '/dashboard');
      return;
    }

    setState(() {
      _userRole = role;
      _isCheckingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(height: 12),
                Text(
                  'Leak Monitoring Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage alerts, responses, technicians, users, reports, and system settings.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Admin Functions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ..._items.map((item) => _AdminTile(item: item)),
        ],
      ),
    );
  }
}

class _AdminItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _AdminItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}

class _AdminTile extends StatelessWidget {
  final _AdminItem item;

  const _AdminTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x0F000000),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: AppColors.primary),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
        onTap: () {
          Navigator.pushNamed(context, item.route);
        },
      ),
    );
  }
}
