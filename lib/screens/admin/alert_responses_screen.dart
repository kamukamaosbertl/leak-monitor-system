import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AlertResponsesScreen extends StatefulWidget {
  const AlertResponsesScreen({super.key});

  @override
  State<AlertResponsesScreen> createState() => _AlertResponsesScreenState();
}

class _AlertResponsesScreenState extends State<AlertResponsesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _responses = [];

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.fetchAlertResponses();
      if (!mounted) return;
      setState(() {
        _responses = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load alert responses';
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    try {
      return DateFormat(
        'MMM d, yyyy HH:mm',
      ).format(DateTime.parse(value.toString()));
    } catch (_) {
      return value?.toString() ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Alert Responses'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadResponses,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ListView(
                  children: [
                    const SizedBox(height: 180),
                    Center(child: Text(_error!)),
                  ],
                )
                : _responses.isEmpty
                ? ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('No alert responses yet')),
                  ],
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _responses.length,
                  itemBuilder: (context, index) {
                    final item = _responses[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.assignment_turned_in_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${item['user'] ?? 'Unknown user'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${item['action'] ?? '-'}'.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Alert ID: ${item['alert'] ?? '-'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if ((item['notes'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Notes: ${item['notes']}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(item['created_at']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
