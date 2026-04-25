import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  bool _isExportingPdf = false;
  bool _isExportingCsv = false;

  String? _error;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.generateLatestReport();

      if (!mounted) return;

      setState(() {
        _report = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load latest report';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);

    try {
      await ApiService.downloadLatestReportPdf();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF report exported successfully')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export PDF report')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExportingCsv = true);

    try {
      await ApiService.downloadLatestReportCsv();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV report exported successfully')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export CSV report')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingCsv = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = _report?['incident'] as Map<String, dynamic>? ?? {};
    final alerts = _report?['alerts'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Reports'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReport,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ListView(
                  children: [
                    const SizedBox(height: 180),
                    Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
                : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),

                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Latest Leak Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Summary of the most recent leak incident recorded by the system.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _ExportButton(
                            label: 'Export PDF',
                            icon: Icons.picture_as_pdf_rounded,
                            isLoading: _isExportingPdf,
                            onTap: _exportPdf,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ExportButton(
                            label: 'Export CSV',
                            icon: Icons.table_chart_rounded,
                            isLoading: _isExportingCsv,
                            onTap: _exportCsv,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _ReportCard(
                      title: 'Incident Details',
                      children: [
                        _ReportRow(
                          label: 'Device',
                          value: '${incident['device_id'] ?? '-'}',
                        ),
                        _ReportRow(
                          label: 'Location',
                          value: '${incident['location'] ?? '-'}',
                        ),
                        _ReportRow(
                          label: 'Status',
                          value: '${incident['status'] ?? '-'}',
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
                          value: '${incident['duration_minutes'] ?? '-'} min',
                        ),
                        _ReportRow(
                          label: 'Water Lost',
                          value: '${incident['water_lost'] ?? '-'} L',
                        ),
                        _ReportRow(
                          label: 'Estimated Cost',
                          value: '${incident['money_lost'] ?? '-'}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _ReportCard(
                      title: 'Related Alerts',
                      children:
                          alerts.isEmpty
                              ? const [
                                Text(
                                  'No related alerts found.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ]
                              : alerts.map((alert) {
                                final item =
                                    alert as Map<String, dynamic>? ?? {};

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item['title'] ?? 'Alert'}',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${item['message'] ?? '-'}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _ReportRow(
                                          label: 'Severity',
                                          value: '${item['severity'] ?? '-'}',
                                        ),
                                        _ReportRow(
                                          label: 'Time',
                                          value: '${item['timestamp'] ?? '-'}',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon:
          isLoading
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ReportCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
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
            width: 115,
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
