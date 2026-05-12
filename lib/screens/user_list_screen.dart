import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await AuthService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final isActive = user['isActive'] as bool? ?? true;
    final action = isActive ? 'deactivate' : 'activate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title:
            Text('${action[0].toUpperCase()}${action.substring(1)} Account?'),
        content: Text(
          'Are you sure you want to $action the account of ${user['fullName']}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action[0].toUpperCase() + action.substring(1),
                style: TextStyle(
                    color: isActive
                        ? const Color(0xFFA32D2D)
                        : const Color(0xFF1D9E75))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (isActive) {
      await AuthService.deactivateUser(user['id']);
    } else {
      await AuthService.reactivateUser(user['id']);
    }
    _loadUsers();
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'healthcare_provider':
        return 'Healthcare Provider';
      case 'pharmacy':
        return 'Pharmacy';
      default:
        return role ?? 'Unknown';
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'healthcare_provider':
        return const Color(0xFF1D9E75);
      case 'pharmacy':
        return const Color(0xFF378ADD);
      default:
        return const Color(0xFF888780);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline,
                          size: 64, color: Color(0xFFB4B2A9)),
                      const SizedBox(height: 12),
                      const Text('No accounts yet.',
                          style: TextStyle(
                              color: Color(0xFF888780), fontSize: 15)),
                      const SizedBox(height: 8),
                      const Text(
                          'Add a healthcare provider or pharmacy account.',
                          style: TextStyle(
                              color: Color(0xFFB4B2A9), fontSize: 13)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Account'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isActive = user['isActive'] as bool? ?? true;
                      final role = user['role'] as String?;
                      final name = user['fullName'] as String? ?? 'Unknown';
                      final email = user['email'] as String? ?? '';
                      final facility = user['facility'] as String? ?? '';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              isActive ? Colors.white : const Color(0xFFF1EFE8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD3D1C7)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _roleColor(role).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                role == 'pharmacy'
                                    ? Icons.local_pharmacy
                                    : Icons.medical_services,
                                color: _roleColor(role),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isActive
                                                  ? const Color(0xFF2C2C2A)
                                                  : const Color(0xFF888780),
                                            )),
                                      ),
                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? const Color(0xFFE1F5EE)
                                              : const Color(0xFFF1EFE8),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isActive
                                                ? const Color(0xFF0F6E56)
                                                : const Color(0xFF5F5E5A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(email,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888780))),
                                  if (facility.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(facility,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFB4B2A9))),
                                  ],
                                  const SizedBox(height: 6),
                                  // Role badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _roleColor(role).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _roleLabel(role),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: _roleColor(role)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Toggle button
                            IconButton(
                              icon: Icon(
                                isActive ? Icons.person_off : Icons.person,
                                color: isActive
                                    ? const Color(0xFFA32D2D)
                                    : const Color(0xFF1D9E75),
                                size: 22,
                              ),
                              tooltip: isActive ? 'Deactivate' : 'Activate',
                              onPressed: () => _toggleActive(user),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
