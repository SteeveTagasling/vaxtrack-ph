import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vaccine_record.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Query vaccine record by barcode/batch ID
  static Future<VaccineRecord?> queryVaccine(String batchId) async {
    try {
      final doc = await _db.collection('vaccines').doc(batchId).get();
      if (!doc.exists) return null;
      return VaccineRecord.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Log every scan activity (who, when, where, result)
  static Future<void> logScanActivity({
    required String batchId,
    required String result,
    String location = 'Unknown',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final log = ScanLog(
      batchId: batchId,
      scannedBy: user.uid,
      scannedByEmail: user.email ?? '',
      location: location,
      result: result,
      timestamp: DateTime.now(),
    );

    await _db.collection('scan_logs').add(log.toMap());
  }

  // Get all scan logs for analytics report
  static Future<List<Map<String, dynamic>>> getScanLogs() async {
    final snapshot = await _db
        .collection('scan_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Get analytics summary grouped by batch
  static Future<Map<String, int>> getScanSummary() async {
    final snapshot = await _db.collection('scan_logs').get();
    final Map<String, int> summary = {};

    for (final doc in snapshot.docs) {
      final batchId = doc.data()['batchId'] as String? ?? 'Unknown';
      summary[batchId] = (summary[batchId] ?? 0) + 1;
    }

    return summary;
  }

  // Sign out
  static Future<void> signOut() => _auth.signOut();

  // Current user
  static User? get currentUser => _auth.currentUser;
}
