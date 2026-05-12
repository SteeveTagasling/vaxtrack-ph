import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'add_user_screen.dart';
import 'user_list_screen.dart';
import 'analytics_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        title: const Text('VaxTrack PH — Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => AuthService.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text('Administrator',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(email,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('You have full access to manage system accounts.',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('Account Management',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF085041))),
            const SizedBox(height: 12),

            // Add user card
            _menuCard(
              context,
              icon: Icons.person_add_alt_1,
              title: 'Add New Account',
              subtitle: 'Create a healthcare provider or pharmacy account',
              color: const Color(0xFF1D9E75),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddUserScreen()),
              ),
            ),
            const SizedBox(height: 12),

            // View users card
            _menuCard(
              context,
              icon: Icons.people,
              title: 'Manage Accounts',
              subtitle: 'View, activate, or deactivate user accounts',
              color: const Color(0xFF378ADD),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserListScreen()),
              ),
            ),
            const SizedBox(height: 28),

            const Text('Reports',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF085041))),
            const SizedBox(height: 12),

            _menuCard(
              context,
              icon: Icons.bar_chart,
              title: 'Analytics Report',
              subtitle: 'View scan logs and generate reports for DOH',
              color: const Color(0xFF534AB7),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD3D1C7)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2A))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888780))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF888780)),
          ],
        ),
      ),
    );
  }
}
