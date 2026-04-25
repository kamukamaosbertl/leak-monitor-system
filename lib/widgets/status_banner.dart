import 'package:flutter/material.dart';
import '../models/leak_data.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// StatusBanner
// Top dashboard banner showing current system state.
// ─────────────────────────────────────────────

class StatusBanner extends StatelessWidget {
  final LeakData data;

  const StatusBanner({super.key, required this.data});

  _StatusStyle _getStyle() {
    switch (data.status) {
      case LeakStatus.normal:
        return const _StatusStyle(
          label: 'System Normal',
          icon: Icons.check_circle_rounded,
          backgroundColor: AppColors.statusNormalBg,
          foregroundColor: AppColors.statusNormal,
          description: 'All sensors are reading within normal range.',
        );
      case LeakStatus.warning:
        return const _StatusStyle(
          label: 'Warning',
          icon: Icons.warning_amber_rounded,
          backgroundColor: AppColors.statusWarningBg,
          foregroundColor: AppColors.statusWarning,
          description: 'A minor anomaly has been detected. Monitoring closely.',
        );
      case LeakStatus.leakDetected:
        return const _StatusStyle(
          label: 'Leak Detected',
          icon: Icons.water_damage_rounded,
          backgroundColor: AppColors.statusAlertBg,
          foregroundColor: AppColors.statusAlert,
          description:
              'An active leak has been confirmed. Attention is required.',
        );
      case LeakStatus.critical:
        return const _StatusStyle(
          label: 'Critical Alert',
          icon: Icons.crisis_alert_rounded,
          backgroundColor: AppColors.statusCriticalBg,
          foregroundColor: AppColors.statusCritical,
          description: 'Severe leak detected. Shut off the valve immediately.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _getStyle();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.foregroundColor.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: style.foregroundColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(style.icon, color: style.foregroundColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        style.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: style.foregroundColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _PulseDot(color: style.foregroundColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  style.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: style.foregroundColor.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated live indicator
// ─────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;

  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Internal style model
// ─────────────────────────────────────────────

class _StatusStyle {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final String description;

  const _StatusStyle({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.description,
  });
}
