import 'package:flutter/material.dart';
import '../models/vaccine_record.dart';

class VaccineDetailScreen extends StatelessWidget {
  final VaccineRecord record;
  const VaccineDetailScreen({super.key, required this.record});

  Color get _statusColor {
    switch (record.status) {
      case VaccineStatus.valid:
        return const Color(0xFF1D9E75);
      case VaccineStatus.nearExpiry:
        return const Color(0xFFBA7517);
      case VaccineStatus.expired:
        return const Color(0xFFA32D2D);
      case VaccineStatus.unverified:
        return const Color(0xFF888780);
    }
  }

  String get _statusLabel {
    switch (record.status) {
      case VaccineStatus.valid:
        return 'VALID';
      case VaccineStatus.nearExpiry:
        return 'NEAR EXPIRY';
      case VaccineStatus.expired:
        return 'EXPIRED';
      case VaccineStatus.unverified:
        return 'UNVERIFIED';
    }
  }

  IconData get _statusIcon {
    switch (record.status) {
      case VaccineStatus.valid:
        return Icons.verified;
      case VaccineStatus.nearExpiry:
        return Icons.schedule;
      case VaccineStatus.expired:
        return Icons.cancel;
      case VaccineStatus.unverified:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        title: const Text('Vaccine Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _statusColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon, color: _statusColor, size: 36),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _statusColor,
                        ),
                      ),
                      if (record.status == VaccineStatus.nearExpiry)
                        Text(
                          'Expires in ${record.daysUntilExpiry} day(s)',
                          style: TextStyle(fontSize: 13, color: _statusColor),
                        ),
                      if (record.status == VaccineStatus.expired)
                        const Text(
                          'This vaccine has expired',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFA32D2D),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vaccine info card
            _sectionCard(
              title: 'Vaccine Information',
              icon: Icons.vaccines,
              children: [
                _infoRow('Vaccine Name', record.vaccineName),
                _infoRow('Batch ID', record.batchId, mono: true),
                _infoRow('Manufacturer', record.manufacturer),
                _infoRow('Dosage', record.dosage),
              ],
            ),
            const SizedBox(height: 16),

            // Dates card
            _sectionCard(
              title: 'Dates & Expiry',
              icon: Icons.calendar_month,
              children: [
                _infoRow(
                  'Expiry Date',
                  '${record.expiryDate.day}/${record.expiryDate.month}/${record.expiryDate.year}',
                  valueColor: record.status == VaccineStatus.expired
                      ? const Color(0xFFA32D2D)
                      : record.status == VaccineStatus.nearExpiry
                      ? const Color(0xFFBA7517)
                      : null,
                ),
                _infoRow(
                  'Date Registered',
                  '${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}',
                ),
                _infoRow('Scan Date', () {
                  final now = DateTime.now();
                  return '${now.day}/${now.month}/${now.year}';
                }()),
              ],
            ),
            const SizedBox(height: 24),

            // DOH note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5DCAA5)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0F6E56), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This scan has been logged automatically. '
                      'Report any discrepancies to the Department of Health.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF085041)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Back to scan button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Another'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD3D1C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1D9E75), size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF085041),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFD3D1C7)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool mono = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF888780)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF2C2C2A),
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
