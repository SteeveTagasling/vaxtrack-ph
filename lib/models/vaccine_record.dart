import 'package:cloud_firestore/cloud_firestore.dart';

enum VaccineStatus { valid, nearExpiry, expired, unverified }

class VaccineRecord {
  final String batchId;
  final String manufacturer;
  final DateTime expiryDate;
  final VaccineStatus status;
  final String vaccineName;
  final String dosage;
  final DateTime createdAt;

  VaccineRecord({
    required this.batchId,
    required this.manufacturer,
    required this.expiryDate,
    required this.status,
    required this.vaccineName,
    required this.dosage,
    required this.createdAt,
  });

  factory VaccineRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final expiry = (data['expiryDate'] as Timestamp).toDate();
    final now = DateTime.now();
    final daysLeft = expiry.difference(now).inDays;

    VaccineStatus status;
    if (expiry.isBefore(now)) {
      status = VaccineStatus.expired;
    } else if (daysLeft <= 30) {
      status = VaccineStatus.nearExpiry;
    } else {
      status = VaccineStatus.valid;
    }

    return VaccineRecord(
      batchId: data['batchId'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      expiryDate: expiry,
      status: status,
      vaccineName: data['vaccineName'] ?? '',
      dosage: data['dosage'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  bool get isExpiredOrNearExpiry =>
      status == VaccineStatus.expired || status == VaccineStatus.nearExpiry;

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
}

class ScanLog {
  final String batchId;
  final String scannedBy;
  final String scannedByEmail;
  final String location;
  final String result;
  final DateTime timestamp;

  ScanLog({
    required this.batchId,
    required this.scannedBy,
    required this.scannedByEmail,
    required this.location,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'batchId': batchId,
    'scannedBy': scannedBy,
    'scannedByEmail': scannedByEmail,
    'location': location,
    'result': result,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
