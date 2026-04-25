import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _goBackToDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.darkMode;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goBackToDashboard(context);
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _goBackToDashboard(context),
          ),
          title: const Text('Settings'),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/water_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color:
                    isDark
                        ? Colors.black.withOpacity(0.70)
                        : Colors.white.withOpacity(0.78),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
              children: [
                _buildSectionHeader('Alert Rules', isDark),
                _buildThresholdCard(context, settings, isDark),

                _buildSectionHeader('Display Preferences', isDark),
                _buildDisplayCard(context, settings, isDark),

                _buildSectionHeader('System & Info', isDark),
                _buildAboutCard(context, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? const Color(0xFF111827).withOpacity(0.88)
                  : Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Color(0x0F000000),
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildThresholdCard(
    BuildContext context,
    SettingsProvider s,
    bool isDark,
  ) {
    return _buildCard([
      _CardIntro(
        icon: Icons.warning_amber_rounded,
        title: 'Alert Thresholds',
        subtitle:
            'Set when the system should treat changes as serious enough to trigger attention.',
        accentColor: AppColors.statusAlert,
        isDark: isDark,
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      _SliderTile(
        label: 'Flow Delta Threshold',
        subtitle:
            'Alert when delta exceeds ${s.deltaThreshold.toStringAsFixed(1)} L/min',
        helper: 'Lower values catch issues earlier, but may increase noise.',
        value: s.deltaThreshold,
        min: 0.5,
        max: 10.0,
        divisions: 19,
        accentColor: AppColors.statusAlert,
        isDark: isDark,
        onChanged: (val) => s.setDeltaThreshold(val),
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      _SliderTile(
        label: 'Water Lost Threshold',
        subtitle:
            'Alert when loss exceeds ${s.waterLostThreshold.toStringAsFixed(0)} L',
        helper: 'Use this to define what counts as a costly or wasteful leak.',
        value: s.waterLostThreshold,
        min: 10,
        max: 500,
        divisions: 49,
        accentColor: AppColors.accentBlue,
        isDark: isDark,
        onChanged: (val) => s.setWaterLostThreshold(val),
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      _SliderTile(
        label: 'Duration Threshold',
        subtitle: 'Alert after ${s.durationThreshold} minutes of loss',
        helper:
            'Shorter times are more aggressive. Longer times reduce false alarms.',
        value: s.durationThreshold.toDouble(),
        min: 5,
        max: 120,
        divisions: 23,
        accentColor: AppColors.accentOrange,
        isDark: isDark,
        onChanged: (val) => s.setDurationThreshold(val.toInt()),
      ),
    ], isDark);
  }

  Widget _buildDisplayCard(
    BuildContext context,
    SettingsProvider s,
    bool isDark,
  ) {
    const units = ['Liters', 'Gallons', 'Cubic meters'];
    const currencies = ['USD', 'UGX', 'EUR', 'KES', 'GBP'];
    const refreshRates = ['2 seconds', '5 seconds', '10 seconds', '30 seconds'];

    return _buildCard([
      _CardIntro(
        icon: Icons.tune_rounded,
        title: 'Display & Units',
        subtitle:
            'These settings control how numbers are shown across the app.',
        accentColor: AppColors.accentBlue,
        isDark: isDark,
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      _DropdownTile(
        label: 'Volume Unit',
        description: 'Used for flow and water loss values across the app.',
        icon: Icons.straighten_outlined,
        value: s.selectedUnit,
        options: units,
        isDark: isDark,
        onChanged: (val) => s.setSelectedUnit(val!),
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      _DropdownTile(
        label: 'Currency',
        description: 'Used when estimating leak cost and financial impact.',
        icon: Icons.attach_money_outlined,
        value: s.selectedCurrency,
        options: currencies,
        isDark: isDark,
        onChanged: (val) => s.setSelectedCurrency(val!),
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      _DropdownTile(
        label: 'Live Refresh Rate',
        description: 'Controls how often the app updates live presentation.',
        icon: Icons.refresh_outlined,
        value: s.selectedRefreshRate,
        options: refreshRates,
        isDark: isDark,
        onChanged: (val) => s.setSelectedRefreshRate(val!),
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      SwitchListTile(
        value: s.darkMode,
        title: Text(
          'Dark Mode',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Switch the settings screen between light and dark appearance',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        secondary: Icon(
          Icons.dark_mode_outlined,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
        onChanged: (value) {
          s.setDarkMode(value);
        },
      ),
    ], isDark);
  }

  Widget _buildAboutCard(BuildContext context, bool isDark) {
    return _buildCard([
      _CardIntro(
        icon: Icons.info_outline,
        title: 'About This System',
        subtitle:
            'Useful reference information and support shortcuts for the monitoring platform.',
        accentColor: AppColors.accentGreen,
        isDark: isDark,
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      _InfoTile(
        icon: Icons.apps_rounded,
        title: 'App Version',
        value: '1.0.0',
        isDark: isDark,
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      _InfoTile(
        icon: Icons.code_outlined,
        title: 'Backend Version',
        value: 'Django 4.2',
        isDark: isDark,
      ),
      Divider(height: 1, color: isDark ? Colors.white10 : null),
      ListTile(
        leading: Icon(
          Icons.policy_outlined,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Read how system and user data are handled',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Privacy policy coming soon')),
          );
        },
      ),
    ], isDark);
  }
}

class _CardIntro extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isDark;

  const _CardIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 12.5,
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

class _SliderTile extends StatefulWidget {
  final String label;
  final String subtitle;
  final String helper;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.subtitle,
    required this.helper,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.accentColor,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<_SliderTile> {
  late double _tempValue;

  @override
  void initState() {
    super.initState();
    _tempValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _SliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _tempValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final valueText = _tempValue.toStringAsFixed(
      _tempValue == _tempValue.truncate() ? 0 : 1,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color:
                            widget.isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color:
                            widget.isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  valueText,
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.helper,
            style: TextStyle(
              color: widget.isDark ? Colors.white60 : AppColors.textSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.accentColor,
              thumbColor: widget.accentColor,
              overlayColor: widget.accentColor.withOpacity(0.12),
              inactiveTrackColor: widget.accentColor.withOpacity(0.18),
              trackHeight: 4,
            ),
            child: Slider(
              value: _tempValue,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              label: valueText,
              onChanged: (val) {
                setState(() => _tempValue = val);
              },
              onChangeEnd: (val) {
                widget.onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final String value;
  final List<String> options;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.options,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: isDark ? const Color(0xFF111827) : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              items:
                  options
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: isDark ? Colors.white70 : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
