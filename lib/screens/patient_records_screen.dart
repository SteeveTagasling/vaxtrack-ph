import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen> {
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patient_records')
          .orderBy('registeredAt', descending: true)
          .get();

      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _records = records;
        _filtered = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _records.where((r) {
        final name = (r['name'] as String? ?? '').toLowerCase();
        final vaccine = (r['vaccine'] as String? ?? '').toLowerCase();
        final registeredBy = (r['registeredBy'] as String? ?? '').toLowerCase();
        return name.contains(q) ||
            vaccine.contains(q) ||
            registeredBy.contains(q);
      }).toList();
    });
  }

  void _showRecordDetail(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (_) => _RecordDetailDialog(record: record),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1D9E75)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF888780))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2A))),
          ),
        ],
      ),
    );
  }

  String _vaccineInitial(String? vaccine) {
    if (vaccine == null || vaccine.isEmpty) return 'V';
    return vaccine[0].toUpperCase();
  }

  Color _vaccineColor(String? vaccine) {
    final colors = [
      const Color(0xFF1D9E75),
      const Color(0xFF378ADD),
      const Color(0xFF534AB7),
      const Color(0xFFBA7517),
      const Color(0xFFA32D2D),
    ];
    if (vaccine == null) return colors[0];
    return colors[vaccine.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        title: const Text('Patient Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.folder_shared, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Total Records',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  Text(
                    '${_records.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search by name, vaccine, or provider…',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFFB4B2A9)),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF888780), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD3D1C7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD3D1C7)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open,
                                size: 64, color: Color(0xFFB4B2A9)),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No records match your search.'
                                  : 'No patient records found.',
                              style: const TextStyle(
                                  color: Color(0xFF888780), fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Records are created when a patient is registered\nby a Healthcare Provider or Pharmacy.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFFB4B2A9), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final record = _filtered[index];
                            final vaccine = record['vaccine'] as String?;
                            final name = record['name'] as String? ?? 'Unknown';
                            final age = record['age'];
                            final registeredBy =
                                record['registeredBy'] as String? ?? '';
                            final registeredAt =
                                record['registeredAt'] as String? ?? '';

                            return InkWell(
                              onTap: () => _showRecordDetail(record),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFD3D1C7)),
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _vaccineColor(vaccine)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _vaccineInitial(vaccine),
                                          style: TextStyle(
                                            color: _vaccineColor(vaccine),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF2C2C2A)),
                                                ),
                                              ),
                                              if (age != null)
                                                Text(
                                                  'Age $age',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF888780)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          // Vaccine badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _vaccineColor(vaccine)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              vaccine ?? 'Unknown Vaccine',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: _vaccineColor(vaccine),
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (registeredBy.isNotEmpty)
                                            Text(
                                              'By: $registeredBy',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFB4B2A9)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          if (registeredAt.isNotEmpty)
                                            Text(
                                              registeredAt,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFB4B2A9)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // QR icon hint
                                    Column(
                                      children: [
                                        const Icon(Icons.qr_code,
                                            color: Color(0xFF1D9E75), size: 18),
                                        const SizedBox(height: 2),
                                        const Icon(Icons.chevron_right,
                                            color: Color(0xFF888780), size: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Separate StatefulWidget for the detail dialog so it can manage QR
// save/share state independently without closing the dialog.
// ─────────────────────────────────────────────────────────────────────────────
class _RecordDetailDialog extends StatefulWidget {
  final Map<String, dynamic> record;

  const _RecordDetailDialog({required this.record});

  @override
  State<_RecordDetailDialog> createState() => _RecordDetailDialogState();
}

class _RecordDetailDialogState extends State<_RecordDetailDialog>
    with SingleTickerProviderStateMixin {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _patientName => widget.record['name'] as String? ?? 'Patient';
  String get _vaccine => widget.record['vaccine'] as String? ?? 'Unknown';
  String get _qrData {
    // If the record already has a stored qrData string, use it
    final stored = widget.record['qrData'] as String?;
    if (stored != null && stored.isNotEmpty) return stored;

    // Otherwise re-encode the full JSON payload — same format the
    // registration screen produces — so the scanner can verify it.
    final payload = {
      'type': 'vaxtrack_ph',
      'name': widget.record['name'] ?? '',
      'age': widget.record['age'] ?? 0,
      'address': widget.record['address'] ?? '',
      'contact': widget.record['contact'] ?? '',
      'vaccine': widget.record['vaccine'] ?? '',
      'vaccinationDate': widget.record['vaccinationDate'] ?? '',
      'nextDoseDate': widget.record['nextDoseDate'] ?? '',
      'registeredBy': widget.record['registeredBy'] ?? '',
      'registeredAt': widget.record['registeredAt'] ?? '',
    };
    return jsonEncode(payload);
  }

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

      final dir = await getTemporaryDirectory();
      final safeName = _patientName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filePath = '${dir.path}/VaxTrack_${safeName}_QR.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

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
      final safeName = _patientName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filePath = '${dir.path}/VaxTrack_${safeName}_QR.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'VaxTrack PH — Vaccination QR Code\nPatient: $_patientName\nVaccine: $_vaccine',
        subject: 'VaxTrack PH — $_patientName Vaccination Record',
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1D9E75)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF888780))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person,
                      color: Color(0xFF0F6E56), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _patientName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F6E56)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: const Color(0xFF888780),
                ),
              ],
            ),
          ),

          // ── Tab bar ─────────────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0F6E56),
            unselectedLabelColor: const Color(0xFF888780),
            indicatorColor: const Color(0xFF1D9E75),
            tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Details'),
              Tab(icon: Icon(Icons.qr_code, size: 18), text: 'QR Code'),
            ],
          ),

          // ── Tab content ─────────────────────────────────────────────────
          SizedBox(
            height: 360,
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 1: Details ───────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vaccine badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5EE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF5DCAA5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.vaccines,
                                color: Color(0xFF0F6E56), size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _vaccine,
                                style: const TextStyle(
                                  color: Color(0xFF0F6E56),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _infoRow(Icons.person, 'Name', record['name'] ?? 'N/A'),
                      _infoRow(Icons.cake, 'Age', '${record['age'] ?? 'N/A'}'),
                      _infoRow(Icons.location_on, 'Address',
                          record['address'] ?? 'N/A'),
                      _infoRow(
                          Icons.phone, 'Contact', record['contact'] ?? 'N/A'),
                      const Divider(height: 20),
                      _infoRow(Icons.calendar_today, 'Vaccinated',
                          record['vaccinationDate'] ?? 'N/A'),
                      if (record['nextDoseDate'] != null &&
                          record['nextDoseDate'].toString().isNotEmpty)
                        _infoRow(Icons.event_repeat, 'Next Dose',
                            record['nextDoseDate']),
                      const Divider(height: 20),
                      _infoRow(Icons.medical_services, 'Registered By',
                          record['registeredBy'] ?? 'N/A'),
                      _infoRow(Icons.access_time, 'Registered At',
                          record['registeredAt'] ?? 'N/A'),
                    ],
                  ),
                ),

                // ── Tab 2: QR Code ───────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      // QR Card with RepaintBoundary for capture
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD3D1C7)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D9E75),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.vaccines,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 5),
                                    Text('VaxTrack PH',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              QrImageView(
                                data: _qrData,
                                version: QrVersions.auto,
                                size: 200,
                                backgroundColor: Colors.white,
                                gapless: true,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _patientName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C2C2A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1F5EE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _vaccine,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0F6E56),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Scan to verify vaccination record',
                                style: TextStyle(
                                    fontSize: 11, color: Color(0xFF888780)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Share & Download buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF1D9E75)))
                                  : const Icon(Icons.download, size: 18),
                              label: const Text('Save'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1D9E75),
                                side:
                                    const BorderSide(color: Color(0xFF1D9E75)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: (_isSaving || _isSharing)
                                  ? null
                                  : _downloadQr,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: _isSharing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF534AB7)))
                                  : const Icon(Icons.share, size: 18),
                              label: const Text('Share'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF534AB7),
                                side:
                                    const BorderSide(color: Color(0xFF534AB7)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed:
                                  (_isSaving || _isSharing) ? null : _shareQr,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Footer close button ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
