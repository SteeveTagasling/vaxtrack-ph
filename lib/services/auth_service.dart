import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Admin credentials (only admin uses Firebase Auth) ───────────
  static const String adminEmail = 'admin@vaxtrack.ph';

  // ── Current session ─────────────────────────────────────────────
  static Map<String, dynamic>? _currentSession;

  /// Check if someone is logged in (admin or local user).
  static bool get isLoggedIn => _currentSession != null;
  static bool get isAdmin => _currentSession?['role'] == 'admin';
  static String? get currentEmail => _currentSession?['email'];
  static String? get currentRole => _currentSession?['role'];
  static String? get currentName => _currentSession?['fullName'];

  // ── Login ───────────────────────────────────────────────────────

  /// Login — admin uses Firebase Auth, others use local storage.
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

    // Non-admin: check local storage
    final users = await getAllUsers();
    Map<String, dynamic>? matchedUser;
    try {
      matchedUser = users.firstWhere(
        (u) => (u['email'] as String).toLowerCase() == trimmedEmail,
      );
    } catch (_) {
      throw Exception('user-not-found');
    }

    // Check password
    if (matchedUser['password'] != trimmedPassword) {
      throw Exception('wrong-password');
    }

    // Check if active
    if (matchedUser['isActive'] == false) {
      throw Exception('user-disabled');
    }

    // Set session with the STORED role (not user-selectable)
    _currentSession = {
      'email': matchedUser['email'],
      'role': matchedUser['role'],
      'fullName': matchedUser['fullName'],
      'facility': matchedUser['facility'],
    };
    await _saveSession();
    return matchedUser['role'] as String;
  }

  /// Logout — clear session and sign out of Firebase Auth.
  static Future<void> logout() async {
    _currentSession = null;
    try {
      await _auth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vaxtrack_session');
  }

  /// Restore session on app startup (returns role or null).
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

  /// Save current session to SharedPreferences.
  static Future<void> _saveSession() async {
    if (_currentSession == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vaxtrack_session', jsonEncode(_currentSession));
  }

  // ── User management (local storage) ─────────────────────────────

  static const String _usersKey = 'vaxtrack_users';

  /// Get all stored user accounts.
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return [];

    final List<dynamic> list = jsonDecode(usersJson);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Save the users list.
  static Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  /// Admin creates a new user account (LOCAL ONLY — no Firebase Auth).
  static Future<void> createUser({
    required String email,
    required String password,
    required String role,
    required String fullName,
    required String facility,
  }) async {
    final users = await getAllUsers();

    // Check if email already exists
    final exists = users.any(
      (u) => (u['email'] as String).toLowerCase() == email.trim().toLowerCase(),
    );
    if (exists) {
      throw Exception('This email is already registered.');
    }

    // Generate a simple unique ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    users.add({
      'id': id,
      'email': email.trim().toLowerCase(),
      'password': password.trim(),
      'fullName': fullName.trim(),
      'facility': facility.trim(),
      'role': role,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await _saveUsers(users);
  }

  /// Deactivate a user account.
  static Future<void> deactivateUser(String userId) async {
    final users = await getAllUsers();
    final index = users.indexWhere((u) => u['id'] == userId);
    if (index != -1) {
      users[index]['isActive'] = false;
      await _saveUsers(users);
    }
  }

  /// Reactivate a user account.
  static Future<void> reactivateUser(String userId) async {
    final users = await getAllUsers();
    final index = users.indexWhere((u) => u['id'] == userId);
    if (index != -1) {
      users[index]['isActive'] = true;
      await _saveUsers(users);
    }
  }
}
