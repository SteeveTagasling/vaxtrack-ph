import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Admin credentials (only admin uses Firebase Auth) ───────────
  static const String adminEmail = 'admin@vaxtrack.ph';

  // ── Current session ─────────────────────────────────────────────
  static Map<String, dynamic>? _currentSession;

  static bool get isLoggedIn => _currentSession != null;
  static bool get isAdmin => _currentSession?['role'] == 'admin';
  static String? get currentEmail => _currentSession?['email'];
  static String? get currentRole => _currentSession?['role'];
  static String? get currentName => _currentSession?['fullName'];

  // ── Login ───────────────────────────────────────────────────────

  static Future<String?> login(String email, String password) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    // Admin login via Firebase Auth
    if (trimmedEmail == adminEmail) {
      await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      _currentSession = {
        'email': adminEmail,
        'role': 'admin',
        'fullName': 'Administrator',
      };
      await _saveSession();
      return 'admin';
    }

    // Non-admin: check Firestore users collection
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: trimmedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('user-not-found');
    }

    final userData = snapshot.docs.first.data();

    if (userData['password'] != trimmedPassword) {
      throw Exception('wrong-password');
    }

    if (userData['isActive'] == false) {
      throw Exception('user-disabled');
    }

    _currentSession = {
      'email': userData['email'],
      'role': userData['role'],
      'fullName': userData['fullName'],
      'facility': userData['facility'],
    };
    await _saveSession();
    return userData['role'] as String;
  }

  static Future<void> logout() async {
    _currentSession = null;
    try {
      await _auth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vaxtrack_session');
  }

  static Future<String?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString('vaxtrack_session');
    if (sessionJson == null) return null;

    try {
      _currentSession = jsonDecode(sessionJson) as Map<String, dynamic>;
      return _currentSession?['role'];
    } catch (_) {
      _currentSession = null;
      return null;
    }
  }

  static Future<void> _saveSession() async {
    if (_currentSession == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vaxtrack_session', jsonEncode(_currentSession));
  }

  // ── User management (Firestore) ──────────────────────────────────

  /// Get all user accounts from Firestore.
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Admin creates a new user account — saved to Firestore.
  static Future<void> createUser({
    required String email,
    required String password,
    required String role,
    required String fullName,
    required String facility,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();

    // Check if email already exists in Firestore
    final existing = await _db
        .collection('users')
        .where('email', isEqualTo: trimmedEmail)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('This email is already registered.');
    }

    // Save to Firestore — document ID is auto-generated
    await _db.collection('users').add({
      'email': trimmedEmail,
      'password': password.trim(),
      'fullName': fullName.trim(),
      'facility': facility.trim(),
      'role': role,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deactivate a user account in Firestore.
  static Future<void> deactivateUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isActive': false});
  }

  /// Reactivate a user account in Firestore.
  static Future<void> reactivateUser(String userId) async {
    await _db.collection('users').doc(userId).update({'isActive': true});
  }
}
