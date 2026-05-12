import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';

class QrDisplayScreen extends StatefulWidget {
  final String qrData;
  final String patientName;
  final String vaccine;

  const QrDisplayScreen({
    super.key,
    required this.qrData,
    required this.patientName,
    required this.vaccine,
  });

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

  Future<Uint8List?> _captureQrImage() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _downloadQr() async {
    setState(() => _isSaving = true);
    try {
      // Request gallery permission
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Gallery permission is required to save the QR code.'),
              backgroundColor: Color(0xFFBA7517),
            ),
          );
          return;
        }
      }

      final bytes = await _captureQrImage();
      if (bytes == null) throw Exception('Could not capture QR image.');

      // Write to a temp file first, then save to gallery
      final dir = await getTemporaryDirectory();
      final safeName =
          widget.patientName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filePath = '${dir.path}/VaxTrack_${safeName}_QR.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Save to gallery using gal
      await Gal.putImage(filePath, album: 'VaxTrack PH');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child:
                    Text('QR code saved to your gallery (VaxTrack PH album).'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
    } on GalException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save to gallery: ${e.type.message}'),
          backgroundColor: const Color(0xFFA32D2D),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: const Color(0xFFA32D2D),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareQr() async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _captureQrImage();
      if (bytes == null) throw Exception('Could not capture QR image.');

      final dir = await getTemporaryDirectory();
      final safeName =
          widget.patientName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filePath = '${dir.path}/VaxTrack_${safeName}_QR.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'VaxTrack PH — Vaccination QR Code\nPatient: ${widget.patientName}\nVaccine: ${widget.vaccine}',
        subject: 'VaxTrack PH — ${widget.patientName} Vaccination Record',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: const Color(0xFFA32D2D),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(title: const Text('Patient QR Code')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Success header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF5DCAA5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF0F6E56), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Record Created Successfully',
                            style: TextStyle(
                                color: Color(0xFF0F6E56),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        SizedBox(height: 2),
                        Text('QR code generated. Download or share this code.',
                            style: TextStyle(
                                color: Color(0xFF0F6E56), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // QR Code card — wrapped in RepaintBoundary for image capture
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD3D1C7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D9E75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.vaccines, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('VaxTrack PH',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    QrImageView(
                      data: widget.qrData,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                      gapless: true,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.patientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5EE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.vaccine,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F6E56),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan this QR code to verify\nvaccination record',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF888780), height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Download & Share
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF1D9E75)))
                        : const Icon(Icons.download, size: 20),
                    label: const Text('Save to Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D9E75),
                      side: const BorderSide(color: Color(0xFF1D9E75)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (_isSaving || _isSharing) ? null : _downloadQr,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF534AB7)))
                        : const Icon(Icons.share, size: 20),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF534AB7),
                      side: const BorderSide(color: Color(0xFF534AB7)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (_isSaving || _isSharing) ? null : _shareQr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Register Another & Done
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text('Register Another'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF378ADD),
                      side: const BorderSide(color: Color(0xFF378ADD)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home, size: 20),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
