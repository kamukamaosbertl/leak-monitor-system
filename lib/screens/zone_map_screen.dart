import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/leak_data.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_theme.dart';

class ZoneMapScreen extends StatefulWidget {
  const ZoneMapScreen({super.key});

  @override
  State<ZoneMapScreen> createState() => _ZoneMapScreenState();
}

class _ZoneMapScreenState extends State<ZoneMapScreen> {
  final WebSocketService _ws = WebSocketService();
  StreamSubscription<LeakData>? _subscription;

  String _selectedZone = 'All';

  // Static zone structure only.
  // Keep this because zones are part of your layout/system setup,
  // not live readings themselves.
  final List<_Zone> _zones = const [
    _Zone(
      id: 'A',
      name: 'Zone A – Main Pipeline',
      description: 'Central distribution trunk from treatment plant',
      sensorId: 'ESP32-001',
    ),
    _Zone(
      id: 'B',
      name: 'Zone B – Residential',
      description: 'Household supply lines for Blocks 1–6',
      sensorId: 'ESP32-002',
    ),
    _Zone(
      id: 'C',
      name: 'Zone C – Industrial',
      description: 'Factory and commercial district supply',
      sensorId: 'ESP32-003',
    ),
    _Zone(
      id: 'D',
      name: 'Zone D – Agriculture',
      description: 'Irrigation lines for farm areas',
      sensorId: 'ESP32-004',
    ),
  ];

  // Live sensor snapshots keyed by deviceId
  final Map<String, LeakData> _liveDataBySensor = {};

  @override
  void initState() {
    super.initState();
    _connectStream();
  }

  void _connectStream() {
    _ws.connect();

    _subscription = _ws.stream.listen(
      (LeakData incoming) {
        if (!mounted) return;

        setState(() {
          _liveDataBySensor[incoming.deviceId] = incoming;
        });
      },
      onError: (_) {
        if (!mounted) return;
      },
      onDone: () {
        if (!mounted) return;
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ws.dispose();
    super.dispose();
  }

  List<_Zone> get _filteredZones {
    if (_selectedZone == 'All') return _zones;

    return _zones.where((zone) {
      final data = _liveDataBySensor[zone.sensorId];
      final status = _statusString(data);
      return status == _selectedZone.toLowerCase();
    }).toList();
  }

  String _statusString(LeakData? data) {
    if (data == null) return 'normal';

    switch (data.status) {
      case LeakStatus.critical:
        return 'critical';
      case LeakStatus.warning:
        return 'warning';
      case LeakStatus.leakDetected:
        return 'leak_detected';
      case LeakStatus.normal:
        return 'normal';
    }
  }

  Color _statusColor(LeakData? data) {
    if (data == null) return AppColors.textSecondary;

    switch (data.status) {
      case LeakStatus.critical:
        return AppColors.statusCritical;
      case LeakStatus.warning:
        return AppColors.statusWarning;
      case LeakStatus.leakDetected:
        return AppColors.statusAlert;
      case LeakStatus.normal:
        return AppColors.statusNormal;
    }
  }

  IconData _statusIcon(LeakData? data) {
    if (data == null) return Icons.sensors_outlined;

    switch (data.status) {
      case LeakStatus.critical:
        return Icons.error_rounded;
      case LeakStatus.warning:
        return Icons.warning_amber_rounded;
      case LeakStatus.leakDetected:
        return Icons.water_damage_rounded;
      case LeakStatus.normal:
        return Icons.check_circle_rounded;
    }
  }

  String _statusLabel(LeakData? data) {
    if (data == null) return 'NO DATA';

    switch (data.status) {
      case LeakStatus.critical:
        return 'CRITICAL';
      case LeakStatus.warning:
        return 'WARNING';
      case LeakStatus.leakDetected:
        return 'LEAK DETECTED';
      case LeakStatus.normal:
        return 'NORMAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Zone Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live zone data is updating')),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMapPlaceholder(),
          _buildLegendAndFilter(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredZones.length,
              itemBuilder: (context, index) {
                final zone = _filteredZones[index];
                final data = _liveDataBySensor[zone.sensorId];

                return _ZoneCard(
                  zone: zone,
                  data: data,
                  statusColor: _statusColor(data),
                  statusIcon: _statusIcon(data),
                  statusLabel: _statusLabel(data),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 180),
            painter: _PipelinePainter(
              zones: _zones,
              statusResolver:
                  (sensorId) => _statusColor(_liveDataBySensor[sensorId]),
            ),
          ),
          const Positioned(
            top: 12,
            left: 16,
            child: Text(
              'Pipeline Overview',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Live status by zone',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendAndFilter() {
    final filters = ['All', 'Critical', 'Warning', 'Normal'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              filters.map((f) {
                final isSelected = _selectedZone == f;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedZone = f),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _Zone {
  final String id;
  final String name;
  final String description;
  final String sensorId;

  const _Zone({
    required this.id,
    required this.name,
    required this.description,
    required this.sensorId,
  });
}

class _ZoneCard extends StatelessWidget {
  final _Zone zone;
  final LeakData? data;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;

  const _ZoneCard({
    required this.zone,
    required this.data,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x0D000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: data == null ? _buildNoDataCard() : _buildLiveDataCard(),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        const Text(
          'Waiting for live sensor data...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.sensors, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              zone.sensorId,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveDataCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            _ZoneStat(
              label: 'Flow In',
              value: '${data!.flowIn.toStringAsFixed(1)} L/m',
            ),
            _ZoneStat(
              label: 'Flow Out',
              value: '${data!.flowOut.toStringAsFixed(1)} L/m',
            ),
            _ZoneStat(label: 'Delta', value: data!.delta.toStringAsFixed(2)),
            _ZoneStat(label: 'Duration', value: '${data!.durationMinutes} min'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ZoneStat(
              label: 'Water Lost',
              value: '${data!.waterLost.toStringAsFixed(1)} L',
            ),
            _ZoneStat(
              label: 'Money Lost',
              value: '\$${data!.moneyLost.toStringAsFixed(2)}',
            ),
            _ZoneStat(label: 'Updated', value: _timeOnly(data!.lastUpdated)),
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.sensors,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      zone.sensorId,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              zone.id,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zone.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                zone.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 16),
            const SizedBox(width: 4),
            Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _timeOnly(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ZoneStat extends StatelessWidget {
  final String label;
  final String value;

  const _ZoneStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PipelinePainter extends CustomPainter {
  final List<_Zone> zones;
  final Color Function(String sensorId) statusResolver;

  _PipelinePainter({required this.zones, required this.statusResolver});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(40, size.height / 2);
    path.lineTo(size.width * 0.35, size.height / 2);
    path.lineTo(size.width * 0.35, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    canvas.drawPath(path, linePaint);

    final path2 = Path();
    path2.moveTo(size.width * 0.35, size.height / 2);
    path2.lineTo(size.width * 0.35, size.height * 0.7);
    path2.lineTo(size.width * 0.7, size.height * 0.7);
    canvas.drawPath(path2, linePaint);

    final positions = [
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.3),
      Offset(size.width * 0.9, size.height * 0.7),
    ];

    for (int i = 0; i < zones.length && i < positions.length; i++) {
      final dotPaint =
          Paint()
            ..color = statusResolver(zones[i].sensorId).withOpacity(0.9)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(positions[i], 10, dotPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: zones[i].id,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          positions[i].dx - textPainter.width / 2,
          positions[i].dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PipelinePainter oldDelegate) {
    return oldDelegate.zones != zones;
  }
}
