import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _goBack(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goBack(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ─────────────────────────────
          // DISPLAY
          // ─────────────────────────────
          _section('Display'),

          _card([
            _dropdown(
              label: 'Volume Unit',
              value: s.selectedUnit,
              options: const ['Liters', 'Gallons', 'Cubic meters'],
              onChanged: (v) => s.setSelectedUnit(v!),
            ),

            _divider(),

            _dropdown(
              label: 'Currency',
              value: s.selectedCurrency,
              options: const ['UGX', 'USD', 'EUR', 'KES'],
              onChanged: (v) => s.setSelectedCurrency(v!),
            ),

            _divider(),

            _dropdown(
              label: 'Refresh Rate',
              value: s.selectedRefreshRate,
              options: const ['2 seconds', '5 seconds', '10 seconds'],
              onChanged: (v) => s.setSelectedRefreshRate(v!),
            ),
          ]),

          const SizedBox(height: 20),

          // ─────────────────────────────
          // NOTIFICATIONS
          // ─────────────────────────────
          _section('Notifications'),

          _card([
            SwitchListTile(
              value: s.criticalAlerts,
              title: const Text('Critical Alerts'),
              subtitle: const Text('Get alerts for serious leaks'),
              onChanged: (v) => s.setCriticalAlerts(v),
            ),

            _divider(),

            SwitchListTile(
              value: s.leakAlerts,
              title: const Text('Leak Alerts'),
              subtitle: const Text('Get alerts for normal leaks'),
              onChanged: (v) => s.setLeakAlerts(v),
            ),

            _divider(),

            SwitchListTile(
              value: s.soundAlerts,
              title: const Text('Sound Alerts'),
              subtitle: const Text('Play sound when alert comes'),
              onChanged: (v) => s.setSoundAlerts(v),
            ),
          ]),

          const SizedBox(height: 20),

          // ─────────────────────────────
          // ABOUT
          // ─────────────────────────────
          _section('About'),

          _card([
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('App Version'),
              trailing: Text('1.0.0'),
            ),
          ]),
        ],
      ),
    );
  }

  // ─────────────────────────────
  // UI HELPERS
  // ─────────────────────────────

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1);

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      title: Text(label),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}