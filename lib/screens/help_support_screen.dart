import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedIndex;

  final String _supportEmail = 'kamukamaosbert2023@gmail.com';
  final String _supportPhone = '+256793702186';
  final String _tutorialUrl =
      'https://youtu.be/3vvhC32zX4s?si=ov1ZcnQsPm25yVHZ';

  final List<Map<String, String>> _faqs = [
    {
      'q': 'What does the delta value mean?',
      'a':
          'Delta is the difference between Flow In and Flow Out. If Flow In is higher than Flow Out, it means water may be leaking somewhere in the pipeline.',
    },
    {
      'q': 'Why is not all sensor data stored?',
      'a':
          'Sensors can send data every second. Storing every reading would fill the database quickly. The system stores important leak events instead, so reports and history focus on meaningful incidents.',
    },
    {
      'q': 'What happens when a leak is detected?',
      'a':
          'The dashboard updates in real time, an alert is created, a push notification may be sent to registered devices, and the leak event is stored for history and reporting.',
    },
    {
      'q': 'What does critical status mean?',
      'a':
          'Critical means the leak is serious and needs urgent attention. It usually means high water loss, high delta, or prolonged leak duration.',
    },
    {
      'q': 'How is money lost calculated?',
      'a':
          'Money lost is estimated from the amount of water lost multiplied by the configured water cost rate.',
    },
    {
      'q': 'How do I export a report?',
      'a':
          'Admins can open the Reports screen and export the latest report as PDF or CSV.',
    },
    {
      'q': 'Why can I not see some screens?',
      'a':
          'The app uses roles. Admins, technicians, workers, and viewers see different screens depending on their responsibilities.',
    },
  ];

  Future<void> _openEmailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Leak Monitor Support Request',
        'body': 'Hello support team,\n\nI need help with:\n\n',
      },
    );

    if (!await launchUrl(uri)) {
      _showSnack('Could not open email app');
    }
  }

  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);

    if (!await launchUrl(uri)) {
      _showSnack('Could not open phone dialer');
    }
  }

  Future<void> _openTutorials() async {
    final uri = Uri.parse(_tutorialUrl);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('Could not open tutorials');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Help & Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed:
              () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
      ),
      body: ListView(
        children: [
          _buildHeroCard(),
          _buildQuickLinksRow(),
          _buildSectionHeader('Frequently Asked Questions'),
          ..._faqs.asMap().entries.map(
            (entry) => _buildFaqItem(entry.key, entry.value),
          ),
          _buildSectionHeader('Contact Support'),
          _buildContactCard(),
          _buildSectionHeader('System Status'),
          _buildSystemStatusCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
          SizedBox(height: 12),
          Text(
            'How can we help?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Find answers, contact support, or learn how to use the leak monitoring system.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinksRow() {
    final links = [
      _QuickLink(
        icon: Icons.video_library_outlined,
        label: 'Tutorials',
        onTap: _openTutorials,
      ),
      _QuickLink(
        icon: Icons.email_outlined,
        label: 'Email Us',
        onTap: _openEmailSupport,
      ),
      _QuickLink(
        icon: Icons.phone_outlined,
        label: 'Call Us',
        onTap: _callSupport,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children:
            links.map((link) {
              return Expanded(
                child: GestureDetector(
                  onTap: link.onTap,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 6,
                          color: Color(0x0D000000),
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(link.icon, color: AppColors.primary, size: 22),
                        const SizedBox(height: 6),
                        Text(
                          link.label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildFaqItem(int index, Map<String, String> faq) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x0A000000),
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          key: Key('faq_$index'),
          initiallyExpanded: _expandedIndex == index,
          onExpansionChanged: (expanded) {
            setState(() => _expandedIndex = expanded ? index : null);
          },
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          title: Text(
            faq['q']!,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq['a']!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
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
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.email_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Email Support'),
              subtitle: Text(_supportEmail),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openEmailSupport,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.phone_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Phone Support'),
              subtitle: Text(_supportPhone),
              trailing: const Icon(Icons.chevron_right),
              onTap: _callSupport,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.video_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Tutorials'),
              subtitle: const Text('Open user guide and training videos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openTutorials,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    final checks = [
      ('Live Dashboard', true),
      ('Database Storage', true),
      ('Alert Service', true),
      ('Push Notifications', true),
      ('Report Export', true),
    ];

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
        child: Column(
          children:
              checks.map((check) {
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        check.$2
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color:
                            check.$2
                                ? AppColors.statusNormal
                                : AppColors.statusAlert,
                      ),
                      title: Text(check.$1),
                      trailing: Text(
                        check.$2 ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          color:
                              check.$2
                                  ? AppColors.statusNormal
                                  : AppColors.statusAlert,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (checks.last.$1 != check.$1) const Divider(height: 1),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _QuickLink {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
