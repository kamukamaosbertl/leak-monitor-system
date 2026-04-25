import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

enum AlertSeverity { info, warning, critical }

class AlertItem {
  final String id;
  final String title;
  final String message;
  final String location;
  final DateTime timestamp;
  final AlertSeverity severity;
  bool isRead;
  bool isDismissed;

  AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.location,
    required this.timestamp,
    required this.severity,
    this.isRead = false,
    this.isDismissed = false,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      location: json['location'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      severity: _severityFromString(json['severity'] ?? 'info'),
      isRead: json['is_read'] ?? false,
      isDismissed: json['is_dismissed'] ?? false,
    );
  }

  static AlertSeverity _severityFromString(String value) {
    switch (value.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const String _baseUrl =
      'https://leak-monitor-backend.onrender.com/api';

  List<AlertItem> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;

  int? _userId;
  String _userRole = 'worker';

  bool get _isAdmin => _userRole == 'admin';
  bool get _isTechnician => _userRole == 'technician';
  bool get _isWorker => _userRole == 'worker';

  bool get _canRespond => _isAdmin || _isTechnician || _isWorker;
  bool get _canDismiss => _isAdmin || _isTechnician || _isWorker;
  bool get _canClearDismissed => _isAdmin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserSession();
    _loadAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _userId = prefs.getInt('user_id');
      _userRole = prefs.getString('role') ?? 'worker';
    });
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/alerts/'));

      if (response.statusCode != 200) {
        throw Exception('Failed to load alerts (${response.statusCode})');
      }

      final List<dynamic> decoded = jsonDecode(response.body);
      final alerts =
          decoded
              .map((item) => AlertItem.fromJson(item as Map<String, dynamic>))
              .toList();

      if (!mounted) return;

      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not load alerts. Pull to retry.';
        _isLoading = false;
      });
    }
  }

  List<AlertItem> get _all => _alerts.where((a) => !a.isDismissed).toList();

  List<AlertItem> get _unread =>
      _alerts.where((a) => !a.isRead && !a.isDismissed).toList();

  List<AlertItem> get _critical =>
      _alerts
          .where((a) => a.severity == AlertSeverity.critical && !a.isDismissed)
          .toList();

  Future<void> _markAllRead() async {
    final previous =
        _alerts
            .map(
              (a) => AlertItem(
                id: a.id,
                title: a.title,
                message: a.message,
                location: a.location,
                timestamp: a.timestamp,
                severity: a.severity,
                isRead: a.isRead,
                isDismissed: a.isDismissed,
              ),
            )
            .toList();

    setState(() {
      for (final alert in _alerts) {
        alert.isRead = true;
      }
    });

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/alerts/mark-all-read/'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all alerts as read');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All alerts marked as read')),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _alerts = previous);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark all alerts as read')),
      );
    }
  }

  Future<void> _respondToAlert(AlertItem alert, String action) async {
    if (!_canRespond) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to respond')),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session not found. Login again.')),
      );
      return;
    }

    try {
      await ApiService.respondToAlert(
        alertId: int.parse(alert.id),
        userId: _userId!,
        action: action,
        notes: '',
      );

      if (!mounted) return;

      setState(() {
        if (action == 'acknowledged' || action == 'responding') {
          alert.isRead = true;
        }

        if (action == 'resolved' || action == 'dismissed') {
          _alerts.removeWhere((item) => item.id == alert.id);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'acknowledged'
                ? 'Alert acknowledged'
                : action == 'responding'
                ? 'Marked as responding'
                : action == 'resolved'
                ? 'Alert resolved'
                : 'Alert dismissed',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update alert')));
    }
  }

  Future<void> _dismiss(AlertItem alert) async {
    if (!_canDismiss) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to dismiss')),
      );
      return;
    }

    final previous = List<AlertItem>.from(_alerts);

    setState(() {
      _alerts.removeWhere((item) => item.id == alert.id);
    });

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/alerts/${alert.id}/dismiss/'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to dismiss alert');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alert dismissed')));
    } catch (_) {
      if (!mounted) return;

      setState(() => _alerts = previous);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not dismiss alert')));
    }
  }

  Future<void> _markRead(AlertItem alert) async {
    if (alert.isRead) return;

    final previousValue = alert.isRead;
    setState(() => alert.isRead = true);

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/alerts/${alert.id}/read/'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark alert as read');
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => alert.isRead = previousValue);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark alert as read')),
      );
    }
  }

  Future<void> _clearDismissedAlerts() async {
    if (!_canClearDismissed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin can clear dismissed alerts')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirm'),
            content: const Text('Clear dismissed alerts only?'),
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
        await ApiService.clearDismissedAlerts();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dismissed alerts cleared')),
        );

        _loadAlerts();
      } catch (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear dismissed alerts')),
        );
      }
    }
  }

  Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.statusCritical;
      case AlertSeverity.warning:
        return AppColors.statusAlert;
      case AlertSeverity.info:
        return AppColors.accentBlue;
    }
  }

  IconData _severityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error_rounded;
      case AlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case AlertSeverity.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unread.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alerts'),
            Text(
              _userRole.toUpperCase(),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (_canClearDismissed)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear dismissed alerts',
              onPressed: _clearDismissedAlerts,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAlerts,
            tooltip: 'Refresh',
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'All (${_all.length})'),
            Tab(text: 'Unread (${_unread.length})'),
            Tab(text: 'Critical (${_critical.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: TabBarView(
          controller: _tabController,
          children: [
            _AlertList(
              alerts: _all,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              canRespond: _canRespond,
              canDismiss: _canDismiss,
              onRetry: _loadAlerts,
              onDismiss: _dismiss,
              onRead: _markRead,
              onRespond: _respondToAlert,
              severityColor: _severityColor,
              severityIcon: _severityIcon,
              emptyTitle: 'No alerts yet',
              emptyMessage:
                  'When the backend starts sending alerts, they will appear here.',
            ),
            _AlertList(
              alerts: _unread,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              canRespond: _canRespond,
              canDismiss: _canDismiss,
              onRetry: _loadAlerts,
              onDismiss: _dismiss,
              onRead: _markRead,
              onRespond: _respondToAlert,
              severityColor: _severityColor,
              severityIcon: _severityIcon,
              emptyTitle: 'No unread alerts',
              emptyMessage: 'Everything has already been reviewed.',
            ),
            _AlertList(
              alerts: _critical,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              canRespond: _canRespond,
              canDismiss: _canDismiss,
              onRetry: _loadAlerts,
              onDismiss: _dismiss,
              onRead: _markRead,
              onRespond: _respondToAlert,
              severityColor: _severityColor,
              severityIcon: _severityIcon,
              emptyTitle: 'No critical alerts',
              emptyMessage:
                  'Critical leak detections will be highlighted here.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertList extends StatelessWidget {
  final List<AlertItem> alerts;
  final bool isLoading;
  final String? errorMessage;
  final bool canRespond;
  final bool canDismiss;
  final VoidCallback onRetry;
  final Future<void> Function(AlertItem) onDismiss;
  final Future<void> Function(AlertItem) onRead;
  final Future<void> Function(AlertItem, String) onRespond;
  final Color Function(AlertSeverity) severityColor;
  final IconData Function(AlertSeverity) severityIcon;
  final String emptyTitle;
  final String emptyMessage;

  const _AlertList({
    required this.alerts,
    required this.isLoading,
    required this.errorMessage,
    required this.canRespond,
    required this.canDismiss,
    required this.onRetry,
    required this.onDismiss,
    required this.onRead,
    required this.onRespond,
    required this.severityColor,
    required this.severityIcon,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading alerts...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could Not Load Alerts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (alerts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 60,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        final color = severityColor(alert.severity);
        final icon = severityIcon(alert.severity);

        return Dismissible(
          key: Key(alert.id),
          direction:
              canDismiss ? DismissDirection.endToStart : DismissDirection.none,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.statusAlert.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.statusAlert,
            ),
          ),
          confirmDismiss: (_) async {
            await onDismiss(alert);
            return true;
          },
          child: GestureDetector(
            onTap: () => onRead(alert),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: alert.isRead ? Colors.white : color.withOpacity(0.04),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alert.title,
                                  style: TextStyle(
                                    fontWeight:
                                        alert.isRead
                                            ? FontWeight.w600
                                            : FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (!alert.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.message,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          if (canRespond) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _actionButton(
                                  label: 'Ack',
                                  color: AppColors.accentBlue,
                                  onTap: () => onRespond(alert, 'acknowledged'),
                                ),
                                const SizedBox(width: 8),
                                _actionButton(
                                  label: 'Respond',
                                  color: AppColors.accentOrange,
                                  onTap: () => onRespond(alert, 'responding'),
                                ),
                                const SizedBox(width: 8),
                                _actionButton(
                                  label: 'Resolve',
                                  color: AppColors.accentGreen,
                                  onTap: () => onRespond(alert, 'resolved'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  alert.severity.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  alert.location,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'MMM d, HH:mm',
                                ).format(alert.timestamp),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
