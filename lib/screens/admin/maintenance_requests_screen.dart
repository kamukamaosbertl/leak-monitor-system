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
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  String _userRole = 'worker';

  bool get _isAdmin => _userRole == 'admin';
  bool get _isTechnician => _userRole == 'technician';
  bool get _canUpdateStatus => _isAdmin || _isTechnician;
  bool get _canClearCompleted => _isAdmin;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _loadRequests();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _userRole = prefs.getString('role') ?? 'worker';
    });
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
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load maintenance requests';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    if (!_canUpdateStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to update maintenance'),
        ),
      );
      return;
    }

    try {
      await ApiService.updateMaintenanceRequestStatus(
        requestId: id,
        statusValue: status,
      );

      await _loadRequests();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to $status')));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update status')));
    }
  }

  Future<void> _clearCompleted() async {
    if (!_canClearCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admin can clear completed requests'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirm'),
            content: const Text('Clear completed records only?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await ApiService.clearCompletedMaintenance();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completed requests cleared')),
        );

        _loadRequests();
      } catch (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear completed requests')),
        );
      }
    }
  }

  String _formatDate(dynamic value) {
    try {
      return DateFormat(
        'MMM d, yyyy HH:mm',
      ).format(DateTime.parse(value.toString()));
    } catch (_) {
      return value?.toString() ?? '-';
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

  String _roleTitle() {
    switch (_userRole) {
      case 'admin':
        return 'ADMIN';
      case 'technician':
        return 'TECHNICIAN';
      default:
        return _userRole.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maintenance Requests'),
            Text(
              _roleTitle(),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (_canClearCompleted)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              tooltip: 'Clear completed requests',
              onPressed: _clearCompleted,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ListView(
                  children: [
                    const SizedBox(height: 180),
                    Center(child: Text(_error!)),
                  ],
                )
                : _requests.isEmpty
                ? ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('No maintenance requests yet')),
                  ],
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final item = _requests[index];
                    final id = item['id'] as int;
                    final status = item['status']?.toString() ?? 'pending';
                    final color = _statusColor(status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.engineering_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item['location']?.toString() ??
                                      'Unknown location',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Device: ${item['device_id'] ?? '-'}'),
                          Text(
                            'Requested by: ${item['requested_by'] ?? 'Unknown'}',
                          ),
                          Text('Reason: ${item['reason'] ?? '-'}'),
                          Text('Severity: ${item['severity'] ?? '-'}'),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(item['created_at']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_canUpdateStatus) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatusButton(
                                  label: 'Assign',
                                  onTap: () => _updateStatus(id, 'assigned'),
                                ),
                                const SizedBox(width: 8),
                                _StatusButton(
                                  label: 'Progress',
                                  onTap: () => _updateStatus(id, 'in_progress'),
                                ),
                                const SizedBox(width: 8),
                                _StatusButton(
                                  label: 'Complete',
                                  onTap: () => _updateStatus(id, 'completed'),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Read-only access',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StatusButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(onPressed: onTap, child: Text(label)),
    );
  }
}
