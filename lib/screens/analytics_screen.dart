import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, dynamic>> _logs = [];
  Map<String, int> _summary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final logs = await FirebaseService.getScanLogs();
    final summary = await FirebaseService.getScanSummary();
    setState(() {
      _logs = logs;
      _summary = summary;
      _isLoading = false;
    });
  }

  Color _resultColor(String result) {
    if (result.contains('VALID')) return const Color(0xFF1D9E75);
    if (result.contains('ALERT') || result.contains('Expired'))
      return const Color(0xFFA32D2D);
    if (result.contains('WARNING') || result.contains('Near'))
      return const Color(0xFFBA7517);
    return const Color(0xFF888780);
  }

  @override
  Widget build(BuildContext context) {
    final totalScans = _logs.length;
    final validScans =
        _logs.where((l) => (l['result'] as String).contains('VALID')).length;
    final alertScans =
        _logs.where((l) => (l['result'] as String).contains('ALERT')).length;
    final unverified = _logs
        .where((l) => (l['result'] as String).contains('UNVERIFIED'))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        title: const Text('Analytics Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DOH header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D9E75),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VaxTrack PH — Scan Analytics',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'For DOH & Health Authorities',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary stats
                    Row(
                      children: [
                        _statCard(
                          'Total Scans',
                          totalScans.toString(),
                          const Color(0xFF378ADD),
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          'Valid',
                          validScans.toString(),
                          const Color(0xFF1D9E75),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statCard(
                          'Expired Alerts',
                          alertScans.toString(),
                          const Color(0xFFA32D2D),
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          'Unverified',
                          unverified.toString(),
                          const Color(0xFFBA7517),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Scan by batch summary
                    if (_summary.isNotEmpty) ...[
                      const Text(
                        'Scans per Batch',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF085041),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD3D1C7)),
                        ),
                        child: Column(
                          children: _summary.entries.map((e) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          e.key,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'monospace',
                                            color: Color(0xFF2C2C2A),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE1F5EE),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '${e.value} scans',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0F6E56),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (e.key != _summary.keys.last)
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFD3D1C7),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Recent scan logs
                    const Text(
                      'Recent Scan Activity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF085041),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_logs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No scan logs yet.\nStart scanning vaccines to see activity.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF888780),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final result = log['result'] as String? ?? '';
                          final ts = log['timestamp'];
                          String timeStr = '';
                          if (ts != null) {
                            try {
                              final dt = ts.toDate();
                              timeStr =
                                  '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                            } catch (_) {}
                          }
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD3D1C7),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _resultColor(result),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log['batchId'] as String? ??
                                            'Unknown batch',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C2C2A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        result,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _resultColor(result),
                                        ),
                                      ),
                                      Text(
                                        '${log['scannedByEmail'] ?? ''} · $timeStr',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF888780),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888780)),
            ),
          ],
        ),
      ),
    );
  }
}
