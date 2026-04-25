import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// MetricCard
// Compact reusable card for dashboard metrics.
// ─────────────────────────────────────────────

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final bool isHighlighted;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🔥 Highlight = urgency (critical metrics pop visually)
    final Color valueColor =
        isHighlighted ? AppColors.statusAlert : AppColors.textPrimary;

    final Color unitColor =
        isHighlighted ? AppColors.statusAlert : AppColors.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),

        // 🔥 Border becomes stronger when highlighted
        border: Border.all(
          color:
              isHighlighted
                  ? AppColors.statusAlert.withOpacity(0.6)
                  : AppColors.border,
          width: isHighlighted ? 1.4 : 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Top row → icon + label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // 🔥 VALUE = primary focus
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),

          const SizedBox(height: 6),

          // 🔹 Unit = secondary info (less visual weight)
          Text(
            unit,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: unitColor.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // 🔥 Accent line → helps fast scanning
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 4,
            width: isHighlighted ? 64 : 42, // grows when important
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WideMetricCard
// Full-width version for larger values or labels.
// ─────────────────────────────────────────────

class WideMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final bool isHighlighted;

  const WideMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color valueColor =
        isHighlighted ? AppColors.statusAlert : AppColors.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),

        // 🔥 Same highlight logic
        border: Border.all(
          color:
              isHighlighted
                  ? AppColors.statusAlert.withOpacity(0.6)
                  : AppColors.border,
          width: isHighlighted ? 1.4 : 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Icon block
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),

          // 🔹 Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // 🔥 Bigger emphasis for wide cards
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // 🔥 scanning anchor
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  width: isHighlighted ? 80 : 52,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
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
