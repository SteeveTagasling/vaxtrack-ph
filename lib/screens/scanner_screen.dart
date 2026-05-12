import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/firebase_service.dart';
import '../models/vaccine_record.dart';
import 'vaccine_detail_screen.dart';
import 'analytics_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();

    final batchId = barcode!.rawValue!;

    // Step: Query national database (Firebase Firestore lookup)
    final record = await FirebaseService.queryVaccine(batchId);

    if (!mounted) return;

    if (record == null) {
      // No record found → Flag as unverified
      await FirebaseService.logScanActivity(
        batchId: batchId,
        result: 'UNVERIFIED - Record not found',
      );
      _showUnverifiedDialog(batchId);
    } else if (record.isExpiredOrNearExpiry) {
      // Record found but expired/near-expiry → Send expiry alert
      await FirebaseService.logScanActivity(
        batchId: batchId,
        result: record.status == VaccineStatus.expired
            ? 'ALERT - Expired'
            : 'WARNING - Near expiry',
      );
      _showExpiryAlert(record);
    } else {
      // Valid record → Display vaccine details
      await FirebaseService.logScanActivity(
        batchId: batchId,
        result: 'VALID',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VaccineDetailScreen(record: record),
        ),
      ).then((_) => _resumeScanner());
    }
  }

  void _showUnverifiedDialog(String batchId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFBA7517), size: 28),
            SizedBox(width: 8),
            Text('Unverified Vaccine', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This vaccine batch was NOT found in the national database.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Batch ID: $batchId',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFF633806),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Do NOT administer this vaccine. Report to DOH immediately.',
              style: TextStyle(fontSize: 13, color: Color(0xFFA32D2D)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanner();
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  void _showExpiryAlert(VaccineRecord record) {
    final isExpired = record.status == VaccineStatus.expired;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isExpired ? Icons.cancel : Icons.schedule,
              color:
                  isExpired ? const Color(0xFFA32D2D) : const Color(0xFFBA7517),
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isExpired ? 'Expired Vaccine' : 'Near Expiry',
              style: const TextStyle(fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isExpired
                  ? 'This vaccine has already expired.'
                  : 'This vaccine expires in ${record.daysUntilExpiry} day(s).',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _detailRow('Batch', record.batchId),
            _detailRow('Manufacturer', record.manufacturer),
            _detailRow(
              'Expiry',
              '${record.expiryDate.day}/${record.expiryDate.month}/${record.expiryDate.year}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VaccineDetailScreen(record: record),
                ),
              ).then((_) => _resumeScanner());
            },
            child: const Text('View Details'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resumeScanner();
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _resumeScanner() {
    setState(() => _isProcessing = false);
    _scannerController.start();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('VaxTrack PH — Scan'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analytics',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => FirebaseService.signOut(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
          ),
          // Scan overlay frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1D9E75), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Bottom instruction bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              color: Colors.black87,
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner,
                      color: Color(0xFF5DCAA5), size: 28),
                  const SizedBox(height: 8),
                  const Text(
                    'Point camera at vaccine QR code or barcode',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF5DCAA5),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Querying national database...',
                          style:
                              TextStyle(color: Color(0xFF5DCAA5), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Signed in as: ${FirebaseService.currentUser?.email ?? ""}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
