import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class MaintenanceRequestsScreen extends StatefulWidget {
  const MaintenanceRequestsScreen({super.key});

  @override
  State<MaintenanceRequestsScreen> createState() =>
      _MaintenanceRequestsScreenState();
}

class _MaintenanceRequestsScreenState extends State<MaintenanceRequestsScreen> {
  bool _isLoading = true;
  bool _isUpdating = false;

  String? _error;
  String _userRole = 'technician';

  // Bottom nav index — 0 = Maintenance, 1 = Alerts, 2 = Support, 3 = Profile
  int _currentNavIndex = 0;

  List<Map<String, dynamic>> _requests = [];

  bool get _isAdmin => _userRole == 'admin';
  bool get _isTechnician => _userRole == 'technician';
  bool get _canUpdate => _isAdmin || _isTechnician;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _userRole = prefs.getString('role') ?? 'technician';
    });

    await _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.fetchMaintenanceRequests();

      if (!mounted) return;

      setState(() {
        _requests = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load maintenance requests.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int requestId, String status) async {
    if (!_canUpdate || _isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      await ApiService.updateMaintenanceRequestStatus(
        requestId: requestId,
        statusValue: status,
      );

      await _loadRequests();

      if (!mounted) return;
      _showMessage('Request updated.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not update request.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _clearCompleted() async {
    if (!_isAdmin) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear completed?'),
        content: const Text('This will remove completed requests only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.clearCompletedMaintenance();
      await _loadRequests();

      if (!mounted) return;
      _showMessage('Completed requests cleared.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not clear completed requests.');
    }
  }

  // ── Bottom nav handler: technician only ───────────────────────────────
  void _handleBottomNav(int index) {
    if (index == _currentNavIndex) return;

    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0:
        // Already on maintenance.
        break;
      case 1:
        Navigator.pushNamed(context, '/alerts');
        break;
      case 2:
        Navigator.pushNamed(context, '/support');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(dynamic value) {
    try {
      return DateFormat('MMM d, yyyy • HH:mm')
          .format(DateTime.parse(value.toString()).toLocal());
    } catch (_) {
      return '-';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.accentGreen;
      case 'in_progress':
        return AppColors.accentOrange;
      case 'assigned':
        return AppColors.accentBlue;
      default:
        return AppColors.statusAlert;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'assigned':
        return 'ASSIGNED';
      default:
        return 'PENDING';
    }
  }

  String get _screenSubtitle =>
      _isAdmin ? 'All technician work' : 'Your maintenance work';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maintenance'),
            Text(
              _screenSubtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),

        // Admins may visit this page from Admin Panel.
        // Technicians are home here, so they do not need a back button.
        leading: _isAdmin
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/admin');
                },
              )
            : null,
        automaticallyImplyLeading: false,

        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.cleaning_services_rounded),
              onPressed: _clearCompleted,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
          ),
        ],
      ),

      // Technician bottom nav only.
      // History was removed because it is admin-only in main.dart.
      bottomNavigationBar: _isTechnician
          ? NavigationBar(
              selectedIndex: _currentNavIndex,
              onDestinationSelected: _handleBottomNav,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.build_outlined),
                  selectedIcon: Icon(Icons.build_rounded),
                  label: 'Maintenance',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications_rounded),
                  label: 'Alerts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.help_outline_rounded),
                  selectedIcon: Icon(Icons.help_rounded),
                  label: 'Support',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            )
          : null,

      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.statusAlert,
          ),
          const SizedBox(height: 12),
          Center(child: Text(_error!)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRequests,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (_requests.isEmpty) {
      return const Center(child: Text('No maintenance requests yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final item = _requests[index];
        final id = item['id'] as int;
        final status = item['status']?.toString() ?? 'pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _statusColor(status),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              item['location']?.toString() ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(item['created_at'])),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: _canUpdate
                ? PopupMenuButton<String>(
                    onSelected: (value) => _updateStatus(id, value),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'assigned',
                        child: Text('Mark Assigned'),
                      ),
                      PopupMenuItem(
                        value: 'in_progress',
                        child: Text('Mark In Progress'),
                      ),
                      PopupMenuItem(
                        value: 'completed',
                        child: Text('Mark Done'),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }
}