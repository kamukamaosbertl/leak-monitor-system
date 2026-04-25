import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool emailAlerts = true;
  bool smsAlerts = false;
  bool autoReports = true;
  bool maintenanceMode = false;
  bool debugLogging = false;
  bool backupEnabled = true;

  final _emailController = TextEditingController(text: 'admin@waterworks.co');
  final _smsController = TextEditingController(text: '+256700000000');
  final _backupTimeController = TextEditingController(text: '02:00 AM');
  String _reportFrequency = 'Daily';
  String _alertChannel = 'Email + App';

  @override
  void dispose() {
    _emailController.dispose();
    _smsController.dispose();
    _backupTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          TextButton(
            onPressed:
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('System settings saved')),
                ),
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildHeader('Alert Configuration'),
          _buildCard([
            SwitchListTile(
              value: emailAlerts,
              title: const Text('Email Alerts'),
              subtitle: const Text('Send leak alerts by email'),
              secondary: const Icon(Icons.email_outlined),
              onChanged: (val) => setState(() => emailAlerts = val),
            ),
            if (emailAlerts)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Email Address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            const Divider(height: 1),
            SwitchListTile(
              value: smsAlerts,
              title: const Text('SMS Alerts'),
              subtitle: const Text('Send critical alerts by SMS'),
              secondary: const Icon(Icons.sms_outlined),
              onChanged: (val) => setState(() => smsAlerts = val),
            ),
            if (smsAlerts)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _smsController,
                  decoration: const InputDecoration(labelText: 'SMS Number'),
                  keyboardType: TextInputType.phone,
                ),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Alert Channel'),
              trailing: DropdownButton<String>(
                value: _alertChannel,
                underline: const SizedBox.shrink(),
                items:
                    ['Email Only', 'App Only', 'Email + App', 'SMS + App']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (val) => setState(() => _alertChannel = val!),
              ),
            ),
          ]),
          _buildHeader('Reports'),
          _buildCard([
            SwitchListTile(
              value: autoReports,
              title: const Text('Automatic Reports'),
              subtitle: const Text('Generate and send scheduled reports'),
              secondary: const Icon(Icons.assessment_outlined),
              onChanged: (val) => setState(() => autoReports = val),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Report Frequency'),
              trailing: DropdownButton<String>(
                value: _reportFrequency,
                underline: const SizedBox.shrink(),
                items:
                    ['Daily', 'Weekly', 'Monthly']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (val) => setState(() => _reportFrequency = val!),
              ),
            ),
          ]),
          _buildHeader('Backup & Data'),
          _buildCard([
            SwitchListTile(
              value: backupEnabled,
              title: const Text('Auto Backup'),
              subtitle: const Text('Daily database backup'),
              secondary: const Icon(Icons.backup_outlined),
              onChanged: (val) => setState(() => backupEnabled = val),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _backupTimeController,
                decoration: const InputDecoration(labelText: 'Backup Time'),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.delete_sweep_outlined,
                color: AppColors.statusAlert,
              ),
              title: const Text(
                'Purge Old Records',
                style: TextStyle(color: AppColors.statusAlert),
              ),
              subtitle: const Text('Delete incidents older than 1 year'),
              trailing: const Icon(Icons.chevron_right),
              onTap:
                  () => showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('Purge Records'),
                          content: const Text(
                            'This will permanently delete all incident records older than 12 months. This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusAlert,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Records purged'),
                                  ),
                                );
                              },
                              child: const Text('Purge'),
                            ),
                          ],
                        ),
                  ),
            ),
          ]),
          _buildHeader('System'),
          _buildCard([
            SwitchListTile(
              value: maintenanceMode,
              title: const Text('Maintenance Mode'),
              subtitle: const Text('Suspend alerts during maintenance'),
              secondary: const Icon(
                Icons.build_outlined,
                color: AppColors.statusWarning,
              ),
              onChanged: (val) => setState(() => maintenanceMode = val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              value: debugLogging,
              title: const Text('Debug Logging'),
              subtitle: const Text('Log all WebSocket messages'),
              secondary: const Icon(Icons.bug_report_outlined),
              onChanged: (val) => setState(() => debugLogging = val),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              color: Color(0x0D000000),
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }
}
