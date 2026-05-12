import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'qr_display_screen.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  String _selectedVaccine = 'Sinovac';
  DateTime _vaccinationDate = DateTime.now();
  DateTime? _nextDoseDate;

  final List<String> _vaccines = [
    'Sinovac',
    'Pfizer-BioNTech',
    'AstraZeneca',
    'Moderna',
    'Janssen (J&J)',
    'Sputnik V',
    'Novavax',
    'Other',
  ];

  bool _isLoading = false;

  Future<void> _pickDate({required bool isNextDose}) async {
    final initialDate = isNextDose
        ? (_nextDoseDate ?? DateTime.now().add(const Duration(days: 28)))
        : _vaccinationDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF1D9E75),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isNextDose) {
          _nextDoseDate = picked;
        } else {
          _vaccinationDate = picked;
        }
      });
    }
  }

  Future<void> _generateQR() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final registeredAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final nextDose = _nextDoseDate != null
        ? DateFormat('yyyy-MM-dd').format(_nextDoseDate!)
        : null;

    final data = {
      'type': 'vaxtrack_ph',
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'address': _addressController.text.trim(),
      'contact': _contactController.text.trim(),
      'vaccine': _selectedVaccine,
      'vaccinationDate': DateFormat('yyyy-MM-dd').format(_vaccinationDate),
      'nextDoseDate': nextDose,
      'registeredBy': AuthService.currentEmail ?? '',
      'registeredAt': registeredAt,
    };

    // Save record to Firestore patient_records collection
    try {
      await FirebaseFirestore.instance.collection('patient_records').add(data);
    } catch (_) {
      // Continue even if save fails — QR is still generated
    }

    final qrData = jsonEncode(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrDisplayScreen(
          qrData: qrData,
          patientName: _nameController.text.trim(),
          vaccine: _selectedVaccine,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(title: const Text('Register Patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Patient Record',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Fill in patient details and generate a QR code',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information
              const Text('Personal Information',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF085041))),
              const SizedBox(height: 12),

              _buildField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 12),

              _buildField(
                controller: _ageController,
                label: 'Age',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter age';
                  if (int.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _buildField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 12),

              _buildField(
                controller: _contactController,
                label: 'Contact Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty
                    ? 'Please enter contact number'
                    : null,
              ),
              const SizedBox(height: 24),

              // Vaccine Information
              const Text('Vaccine Information',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF085041))),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedVaccine,
                decoration: InputDecoration(
                  labelText: 'Vaccine',
                  prefixIcon:
                      const Icon(Icons.vaccines, color: Color(0xFF1D9E75)),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF1D9E75), width: 2),
                  ),
                ),
                items: _vaccines
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedVaccine = v!),
              ),
              const SizedBox(height: 12),

              _buildDateField(
                label: 'Vaccination Date',
                date: _vaccinationDate,
                icon: Icons.calendar_today,
                onTap: () => _pickDate(isNextDose: false),
              ),
              const SizedBox(height: 12),

              _buildDateField(
                label: 'Next Dose Date (Optional)',
                date: _nextDoseDate,
                icon: Icons.event_repeat,
                onTap: () => _pickDate(isNextDose: true),
                isOptional: true,
              ),

              if (_nextDoseDate != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _nextDoseDate = null),
                    child: const Text('Clear next dose',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFFA32D2D))),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code, size: 22),
                  label: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Generate QR Code',
                          style: TextStyle(fontSize: 15)),
                  onPressed: _isLoading ? null : _generateQR,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1D9E75)),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    bool isOptional = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1D9E75)),
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
        ),
        child: Text(
          date != null
              ? DateFormat('MMMM d, yyyy').format(date)
              : 'Tap to select date',
          style: TextStyle(
            fontSize: 15,
            color: date != null
                ? const Color(0xFF2C2C2A)
                : const Color(0xFF888780),
          ),
        ),
      ),
    );
  }
}
