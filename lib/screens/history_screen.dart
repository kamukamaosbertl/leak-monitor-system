import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/leak_event.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const int _maxHistoryRecords = 100;

  List<LeakEvent> _events = [];
  bool _isLoading = true;
  bool _isDeletingAll = false;
  String? _errorMessage;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Critical', 'Leak Detected'];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await ApiService.fetchLeakEvents();
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoading = false;
      });

      if (_events.length >= _maxHistoryRecords) {
        _showSnack('Please note: history records are full.');
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not load history records. Pull to retry.';
        _isLoading = false;
      });
    }
  }

  List<LeakEvent> get _filteredEvents {
    if (_selectedFilter == 'All') return _events;
    if (_selectedFilter == 'Critical') {
      return _events.where((e) => e.status == 'critical').toList();
    }
    return _events.where((e) => e.status == 'leak_detected').toList();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'critical':
        return AppColors.statusCritical;
      case 'leak_detected':
        return AppColors.statusAlert;
      default:
        return AppColors.statusNormal;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'critical':
        return 'CRITICAL';
      case 'leak_detected':
        return 'LEAK DETECTED';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _deleteRecord(LeakEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Record'),
          content: const Text(
            'Are you sure you want to delete this history record?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteLeakEvent(event.id);
      if (!mounted) return;

      setState(() {
        _events.removeWhere((e) => e.id == event.id);
      });

      _showSnack('Record deleted');
    } catch (_) {
      _showSnack('Could not delete record');
    }
  }

  Future<void> _deleteAllRecords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete All History'),
          content: const Text(
            'This will remove all history records. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeletingAll = true);

    try {
      await ApiService.deleteAllLeakEvents();
      if (!mounted) return;

      setState(() {
        _events.clear();
        _isDeletingAll = false;
      });

      _showSnack('All history deleted');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeletingAll = false);
      _showSnack('Could not delete all history');
    }
  }

  Future<void> _updateRecord(LeakEvent event) async {
    final locationController = TextEditingController(text: event.location);
    final waterLostController = TextEditingController(
      text: event.waterLost.toStringAsFixed(1),
    );
    final costController = TextEditingController(
      text: event.moneyLost.toStringAsFixed(2),
    );
    final durationController = TextEditingController(
      text: event.durationMinutes.toStringAsFixed(0),
    );

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        String status = event.status;

        return AlertDialog(
          title: const Text('Update Record'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'critical',
                      child: Text('Critical'),
                    ),
                    DropdownMenuItem(
                      value: 'leak_detected',
                      child: Text('Leak Detected'),
                    ),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  ],
                  onChanged: (value) {
                    status = value ?? status;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: waterLostController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Water Lost'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Estimated Cost',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Duration Minutes',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.updateLeakEvent(
                    id: event.id,
                    payload: {
                      'location': locationController.text.trim(),
                      'status': status,
                      'water_lost':
                          double.tryParse(waterLostController.text.trim()) ??
                          event.waterLost,
                      'money_lost':
                          double.tryParse(costController.text.trim()) ??
                          event.moneyLost,
                      'duration_minutes':
                          int.tryParse(durationController.text.trim()) ??
                          event.durationMinutes.toInt(),
                    },
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context, true);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not update record')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated == true) {
      await _loadEvents();
      _showSnack('Record updated');
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildScrollableState(
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading history...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildScrollableState(
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
              'Could Not Load History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return _buildScrollableState(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No History Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'No leak history has been recorded yet.'
                  : 'No "$_selectedFilter" records match this filter.',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];

        return _LeakEventCard(
          event: event,
          statusColor: _statusColor(event.status),
          statusLabel: _statusLabel(event.status),
          onEdit: () => _updateRecord(event),
          onDelete: () => _deleteRecord(event),
        );
      },
    );
  }

  Widget _buildScrollableState({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _filters.map((filter) {
                final selected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyCount = _events.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed:
              () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        title: const Text('History'),
        actions: [
          IconButton(
            icon:
                _isDeletingAll
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Delete all',
            onPressed:
                (_events.isEmpty || _isDeletingAll) ? null : _deleteAllRecords,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/water_bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.82)),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        color: Color(0x0F000000),
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TopInfo(
                          label: 'Records',
                          value: '$historyCount / $_maxHistoryRecords',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TopInfo(
                          label: 'Status',
                          value:
                              historyCount >= _maxHistoryRecords
                                  ? 'Full'
                                  : 'Available',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildFilterBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopInfo extends StatelessWidget {
  final String label;
  final String value;

  const _TopInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeakEventCard extends StatelessWidget {
  final LeakEvent event;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LeakEventCard({
    required this.event,
    required this.statusColor,
    required this.statusLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy  HH:mm').format(event.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4, right: 10),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.location,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateStr  •  ${event.deviceId}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricPill(
                    label: 'Water Lost',
                    value: '${event.waterLost.toStringAsFixed(1)} L',
                    accentColor: AppColors.statusAlert,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricPill(
                    label: 'Est. Cost',
                    value: '\$${event.moneyLost.toStringAsFixed(2)}',
                    accentColor: AppColors.accentOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricPill(
                    label: 'Duration',
                    value: '${event.durationMinutes.toInt()} min',
                    accentColor: AppColors.accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DetailStat(
                    label: 'Flow In',
                    value: '${event.flowIn.toStringAsFixed(1)} L/m',
                  ),
                ),
                Expanded(
                  child: _DetailStat(
                    label: 'Flow Out',
                    value: '${event.flowOut.toStringAsFixed(1)} L/m',
                  ),
                ),
                Expanded(
                  child: _DetailStat(
                    label: 'Delta',
                    value: event.delta.toStringAsFixed(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Update'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;

  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
