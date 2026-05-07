import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/leak_data.dart';
import '../../providers/settings_provider.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/metric_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WebSocketService _ws = WebSocketService();
  StreamSubscription<LeakData>? _subscription;

  LeakData _data = mockLeakData;
  bool _isConnected = false;
  bool _alertsSilenced = false;
  bool _isGeneratingReport = false;
  int _currentNavIndex = 0;

  // Backend roles are only admin and technician.
  String _userRole = 'technician';

  String? _lastAlertKey;
  DateTime? _lastAlertTime;

  SettingsProvider? _settingsProvider;

  bool get _isAdmin => _userRole == 'admin';
  bool get _isTechnician => _userRole == 'technician';

  bool get _canViewHistory => _isAdmin || _isTechnician;
  bool get _canViewAlerts => _isAdmin || _isTechnician;
  bool get _canGenerateReport => _isAdmin;
  bool get _canAccessSettings => _isAdmin;

  // Backend still sends duration_minutes.
  // UI displays it as seconds.
  int get _durationSeconds => (_data.durationMinutes * 60).round();

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _connectStream();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _settingsProvider = context.read<SettingsProvider>();
      _settingsProvider?.addListener(_onSettingsChanged);
    });
  }

  @override
  void dispose() {
    _settingsProvider?.removeListener(_onSettingsChanged);
    _subscription?.cancel();
    _ws.dispose();
    super.dispose();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _userRole = prefs.getString('role') ?? 'technician';
    });
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _connectStream() {
    _ws.connect();

    _subscription = _ws.stream.listen(
      (LeakData incoming) {
        if (!mounted) return;

        setState(() {
          _data = incoming;
          _isConnected = true;
        });

        _checkAlerts(incoming);
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isConnected = false);
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _isConnected = false);
      },
    );
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    _showSnack('Dashboard refreshed');
  }

  void _checkAlerts(LeakData data) {
    if (!mounted || _alertsSilenced || _settingsProvider == null) return;

    final settings = _settingsProvider!;

    String? alertMessage;

    if (data.status == LeakStatus.critical &&
        settings.shouldAlert('critical')) {
      alertMessage = 'Critical leak detected at ${data.location}';
    } else if (data.status == LeakStatus.warning ||
        data.status == LeakStatus.leakDetected) {
      if (settings.shouldAlert('leak_detected')) {
        alertMessage = 'Leak detected at ${data.location}';
      }
    }

    if (alertMessage == null) return;

    final alertKey =
        '${data.status.name}-${data.deviceId}-${data.lastUpdated.toIso8601String()}';
    final now = DateTime.now();

    if (_lastAlertKey == alertKey &&
        _lastAlertTime != null &&
        now.difference(_lastAlertTime!) < const Duration(seconds: 4)) {
      return;
    }

    _lastAlertKey = alertKey;
    _lastAlertTime = now;

    _showSnack(alertMessage);
  }

  void _showSnack(String text) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _generateReport() async {
    if (!_canGenerateReport) {
      _showSnack('Only admins can generate reports');
      return;
    }

    if (_isGeneratingReport) return;

    setState(() => _isGeneratingReport = true);

    try {
      final report = await ApiService.generateLatestReport();

      if (!mounted) return;

      setState(() => _isGeneratingReport = false);
      _showReportDialog(report);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isGeneratingReport = false);
      _showSnack('Failed to generate report');
    }
  }

  void _showReportDialog(Map<String, dynamic> report) {
    final incident = report['incident'] as Map<String, dynamic>? ?? {};
    final generatedAt = report['generated_at']?.toString() ?? 'Unknown';

    final durationMinutes =
        (incident['duration_minutes'] as num?)?.toDouble() ?? 0;
    final durationSeconds = (durationMinutes * 60).round();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Latest Leak Report'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReportRow(label: 'Generated At', value: generatedAt),
                _ReportRow(
                  label: 'Device',
                  value: incident['device_id']?.toString() ?? 'Unknown',
                ),
                _ReportRow(
                  label: 'Location',
                  value: incident['location']?.toString() ?? 'Unknown',
                ),
                _ReportRow(
                  label: 'Status',
                  value: incident['status']?.toString() ?? 'Unknown',
                ),
                _ReportRow(
                  label: 'Flow In',
                  value: '${incident['flow_in'] ?? '-'} L/min',
                ),
                _ReportRow(
                  label: 'Flow Out',
                  value: '${incident['flow_out'] ?? '-'} L/min',
                ),
                _ReportRow(
                  label: 'Delta',
                  value: '${incident['delta'] ?? '-'} L/min',
                ),
                _ReportRow(
                  label: 'Duration',
                  value: '$durationSeconds sec',
                ),
                _ReportRow(
                  label: 'Water Lost',
                  value: '${incident['water_lost'] ?? '-'} L',
                ),
                _ReportRow(
                  label: 'Estimated Cost',
                  value: 'UGX ${incident['money_lost'] ?? '-'}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _toggleAlertSilence() {
    setState(() => _alertsSilenced = !_alertsSilenced);
    _showSnack(_alertsSilenced ? 'Alerts silenced' : 'Alerts enabled');
  }

  void _navigateToRoute(String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _navigateFromDrawer(String route) {
    Navigator.pop(context);
    if (!mounted) return;
    _navigateToRoute(route);
  }

  void _handleBottomNav(int index) {
    final items = _bottomDestinations();

    if (index < 0 || index >= items.length) return;
    if (index == _currentNavIndex) return;

    setState(() => _currentNavIndex = index);

    final route = items[index].route;

    if (route == '/dashboard') return;

    _navigateToRoute(route);
  }

  List<_NavItem> _bottomDestinations() {
    final items = <_NavItem>[
      const _NavItem(
        route: '/dashboard',
        destination: NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
      ),
    ];

    if (_canViewHistory) {
      items.add(
        const _NavItem(
          route: '/history',
          destination: NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'History',
          ),
        ),
      );
    }

    if (_isAdmin) {
      items.add(
        const _NavItem(
          route: '/admin',
          destination: NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'Admin',
          ),
        ),
      );
    }

    if (_canViewAlerts) {
      items.add(
        const _NavItem(
          route: '/alerts',
          destination: NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
        ),
      );
    }

    items.add(
      const _NavItem(
        route: '/profile',
        destination: NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ),
    );

    return items;
  }

  String get _formattedTime =>
      DateFormat('MMM d, yyyy  HH:mm:ss').format(_data.lastUpdated);

  String _flowUnit(SettingsProvider settings) {
    switch (settings.selectedUnit) {
      case 'Gallons':
        return 'gal/min';
      case 'Cubic meters':
        return 'm³/min';
      default:
        return 'L/min';
    }
  }

  String _formatFlowValue(double litersPerMinute, SettingsProvider settings) {
    switch (settings.selectedUnit) {
      case 'Gallons':
        return (litersPerMinute * 0.264172).toStringAsFixed(1);
      case 'Cubic meters':
        return (litersPerMinute / 1000).toStringAsFixed(4);
      default:
        return litersPerMinute.toStringAsFixed(1);
    }
  }

  ({String number, String unit}) _splitFormattedVolume(String formatted) {
    final parts = formatted.split(' ');
    if (parts.length >= 2) {
      return (number: parts.first, unit: parts.sublist(1).join(' '));
    }
    return (number: formatted, unit: '');
  }

  bool get _isLeakOrCritical {
    return _data.status == LeakStatus.critical ||
        _data.status == LeakStatus.warning ||
        _data.status == LeakStatus.leakDetected;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final waterLostFormatted = settings.formatVolume(_data.waterLost);
    final waterLostParts = _splitFormattedVolume(waterLostFormatted);
    final navItems = _bottomDestinations();
    final safeNavIndex =
        _currentNavIndex >= navItems.length ? 0 : _currentNavIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(
              child: _SectionLabel(text: 'Live Metrics'),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  MetricCard(
                    label: 'LOSS DELTA',
                    value: _data.delta.toStringAsFixed(2),
                    unit: 'Normal 0-5 · Leak 5-10 · Critical >10',
                    icon: Icons.compare_arrows_rounded,
                    accentColor:
                        _isLeakOrCritical
                            ? AppColors.statusAlert
                            : AppColors.accentPurple,
                    isHighlighted: _isLeakOrCritical,
                  ),
                  MetricCard(
                    label: 'DURATION',
                    value: '$_durationSeconds',
                    unit: 'seconds',
                    icon: Icons.timer_outlined,
                    accentColor: AppColors.accentOrange,
                    isHighlighted: _isLeakOrCritical,
                  ),
                  MetricCard(
                    label: 'FLOW IN',
                    value: _formatFlowValue(_data.flowIn, settings),
                    unit: _flowUnit(settings),
                    icon: Icons.south_rounded,
                    accentColor: AppColors.accentBlue,
                  ),
                  MetricCard(
                    label: 'FLOW OUT',
                    value: _formatFlowValue(_data.flowOut, settings),
                    unit: _flowUnit(settings),
                    icon: Icons.north_rounded,
                    accentColor: AppColors.accentTeal,
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: _SectionLabel(text: 'Impact Summary'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    WideMetricCard(
                      label: 'WATER LOST',
                      value: waterLostParts.number,
                      unit: '${waterLostParts.unit} total',
                      icon: Icons.water_drop_rounded,
                      accentColor: AppColors.statusAlert,
                      isHighlighted: _isLeakOrCritical,
                    ),
                    const SizedBox(height: 12),
                    WideMetricCard(
                      label: 'ESTIMATED COST',
                      value: settings.formatCurrency(_data.moneyLost),
                      unit: 'Financial impact · ${settings.selectedCurrency}',
                      icon: Icons.attach_money_rounded,
                      accentColor: AppColors.accentOrange,
                      isHighlighted: _data.moneyLost > 0,
                    ),
                    const SizedBox(height: 12),
                    WideMetricCard(
                      label: 'ACTIVE SENSOR',
                      value: _data.location,
                      unit:
                          'Device ${_data.deviceId} · Updated $_formattedTime',
                      icon: Icons.location_on_rounded,
                      accentColor: AppColors.accentGreen,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeNavIndex,
        onDestinationSelected: _handleBottomNav,
        destinations: navItems.map((item) => item.destination).toList(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leak Monitor'),
          Text(
            '${_data.location} · ${_userRole.toUpperCase()}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    _isConnected
                        ? Colors.white.withOpacity(0.15)
                        : Colors.red.withOpacity(0.25),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color:
                          _isConnected
                              ? const Color(0xFF4ADE80)
                              : Colors.red.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    _isConnected ? 'Live' : 'Offline',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Leak Monitor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: ${_userRole.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (_canGenerateReport)
            ListTile(
              leading:
                  _isGeneratingReport
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
              title: const Text('Generate Report'),
              onTap:
                  _isGeneratingReport
                      ? null
                      : () {
                          Navigator.pop(context);
                          _generateReport();
                        },
            ),

          if (_canViewAlerts)
            ListTile(
              leading: Icon(
                _alertsSilenced
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_outlined,
              ),
              title: Text(_alertsSilenced ? 'Enable Alerts' : 'Silence Alerts'),
              onTap: () {
                Navigator.pop(context);
                _toggleAlertSilence();
              },
            ),

          if (_canViewHistory)
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text('View History'),
              onTap: () => _navigateFromDrawer('/history'),
            ),

          if (_isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded),
              title: const Text('Admin Panel'),
              onTap: () => _navigateFromDrawer('/admin'),
            ),



          if (_isAdmin)
            ListTile(
              leading: const Icon(Icons.question_answer_rounded),
              title: const Text('Alert Responses'),
              onTap: () => _navigateFromDrawer('/admin/responses'),
            ),

          const Divider(),

          if (_canAccessSettings)
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => _navigateFromDrawer('/settings'),
            ),

          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () => _navigateFromDrawer('/support'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String route;
  final NavigationDestination destination;

  const _NavItem({required this.route, required this.destination});
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReportRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}