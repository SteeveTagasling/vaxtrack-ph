import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.person, color: Color(0xFF0F6E56), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                record['name'] ?? 'Patient',
                style: const TextStyle(fontSize: 16, color: Color(0xFF0F6E56)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vaccine badge
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                        record['vaccine'] ?? 'Unknown',
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
              _infoRow(
                  Icons.location_on, 'Address', record['address'] ?? 'N/A'),
              _infoRow(Icons.phone, 'Contact', record['contact'] ?? 'N/A'),
              const Divider(height: 20),
              _infoRow(Icons.calendar_today, 'Vaccinated',
                  record['vaccinationDate'] ?? 'N/A'),
              if (record['nextDoseDate'] != null &&
                  record['nextDoseDate'].toString().isNotEmpty)
                _infoRow(
                    Icons.event_repeat, 'Next Dose', record['nextDoseDate']),
              const Divider(height: 20),
              _infoRow(Icons.medical_services, 'Registered By',
                  record['registeredBy'] ?? 'N/A'),
              _infoRow(Icons.access_time, 'Registered At',
                  record['registeredAt'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
                                    const Icon(Icons.chevron_right,
                                        color: Color(0xFF888780), size: 20),
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
