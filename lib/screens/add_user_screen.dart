import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _fullNameController = TextEditingController();
  final _facilityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  String _selectedRole = 'healthcare_provider';
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureAdminPassword = true;
  String? _errorMessage;
  String? _successMessage;

  final Map<String, String> _roleLabels = {
    'healthcare_provider': 'Healthcare Provider',
    'pharmacy': 'Pharmacy',
  };

  Future<void> _createUser() async {
    if (_fullNameController.text.isEmpty ||
        _facilityController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _adminPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await AuthService.adminCreateUser(
        adminEmail: AuthService.currentUser!.email!,
        adminPassword: _adminPasswordController.text,
        newEmail: _emailController.text,
        newPassword: _passwordController.text,
        role: _selectedRole,
        fullName: _fullNameController.text,
        facility: _facilityController.text,
      );
      setState(() {
        _successMessage =
            '${_roleLabels[_selectedRole]} account created for ${_emailController.text}';
        _fullNameController.clear();
        _facilityController.clear();
        _emailController.clear();
        _passwordController.clear();
        _adminPasswordController.clear();
      });
    } on Exception catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('email-already-in-use'))
        msg = 'This email is already registered.';
      if (msg.contains('wrong-password') ||
          msg.contains('invalid-credential')) {
        msg = 'Incorrect admin password.';
      }
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _facilityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(title: const Text('Add New Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role selector
            const Text('Account Role',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF085041))),
            const SizedBox(height: 8),
            Row(
              children: _roleLabels.entries.map((entry) {
                final selected = _selectedRole == entry.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRole = entry.key),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: entry.key == 'healthcare_provider' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            selected ? const Color(0xFF1D9E75) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF1D9E75)
                              : const Color(0xFFD3D1C7),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            entry.key == 'healthcare_provider'
                                ? Icons.medical_services
                                : Icons.local_pharmacy,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF888780),
                            size: 22,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF2C2C2A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text('User Information',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF085041))),
            const SizedBox(height: 12),

            _buildField(_fullNameController, 'Full Name', Icons.person_outline),
            const SizedBox(height: 12),
            _buildField(_facilityController,
                'Facility / Hospital / Pharmacy Name', Icons.business),
            const SizedBox(height: 12),
            _buildField(_emailController, 'Email Address', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildField(_passwordController, 'Set Password (min 6 characters)',
                Icons.lock_outline,
                obscure: _obscureNewPassword,
                toggleObscure: () =>
                    setState(() => _obscureNewPassword = !_obscureNewPassword)),
            const SizedBox(height: 24),

            // Admin confirmation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF9F27)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security, color: Color(0xFF854F0B), size: 16),
                      SizedBox(width: 6),
                      Text('Admin Confirmation',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF633806))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Enter your admin password to authorize this action.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF854F0B))),
                  const SizedBox(height: 10),
                  _buildField(
                    _adminPasswordController,
                    'Your Admin Password',
                    Icons.admin_panel_settings,
                    obscure: _obscureAdminPassword,
                    toggleObscure: () => setState(
                        () => _obscureAdminPassword = !_obscureAdminPassword),
                    fillColor: Colors.white,
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              _alertBox(_errorMessage!, isError: true),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 14),
              _alertBox(_successMessage!, isError: false),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account',
                        style: TextStyle(fontSize: 15)),
                onPressed: _isLoading ? null : _createUser,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    Color fillColor = Colors.white,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1D9E75)),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD3D1C7))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD3D1C7))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2)),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF888780)),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );
  }

  Widget _alertBox(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFCEBEB) : const Color(0xFFE1F5EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? const Color(0xFFF09595) : const Color(0xFF5DCAA5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? const Color(0xFFA32D2D) : const Color(0xFF0F6E56),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color:
                    isError ? const Color(0xFFA32D2D) : const Color(0xFF085041),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
