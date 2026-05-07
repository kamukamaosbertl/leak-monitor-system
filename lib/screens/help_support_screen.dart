import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _supportEmail = 'kamukamaosbert2023@gmail.com';
  static const String _supportPhone = '+256793702186';

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Leak Monitor Support',
      },
    );

    if (!await launchUrl(uri)) {
      _showMessage(context, 'Could not open email app');
    }
  }

  Future<void> _callSupport(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);

    if (!await launchUrl(uri)) {
      _showMessage(context, 'Could not open phone dialer');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  Icon(
                    Icons.support_agent_rounded,
                    size: 52,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Need help?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Contact support for account, alerts, or maintenance help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.email_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Email Support'),
                  subtitle: const Text(_supportEmail),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openEmail(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Call Support'),
                  subtitle: const Text(_supportPhone),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _callSupport(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.secondary,
                  ),
                  title: Text('Quick Tip'),
                  subtitle: Text(
                    'If login or alerts fail, check your internet connection first.',
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