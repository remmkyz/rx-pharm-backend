import 'package:flutter/material.dart';
import '../services/user_data_service.dart';

class ContactInfoScreen extends StatefulWidget {
  const ContactInfoScreen({super.key});

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  late TextEditingController _emailController;
  late TextEditingController _primaryPhoneController;
  late TextEditingController _alternatePhoneController;
  late TextEditingController _addressController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _primaryPhoneController = TextEditingController();
    _alternatePhoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    final info = await UserDataService.loadContactInfo();
    _emailController.text = info['email'] ?? '';
    _primaryPhoneController.text = info['primaryPhone'] ?? '';
    _alternatePhoneController.text = info['altPhone'] ?? '';
    _addressController.text = info['mailingAddress'] ?? '';
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _primaryPhoneController.dispose();
    _alternatePhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveContactDetails() async {
    await UserDataService.saveContactInfo(
      email: _emailController.text.trim(),
      primaryPhone: _primaryPhoneController.text.trim(),
      altPhone: _alternatePhoneController.text.trim(),
      mailingAddress: _addressController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact Details saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Stack(
            children: [
              ClipPath(
                clipper: _HeaderWaveClipper(),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: const Color(0xFFFF7A00),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFFFF7A00)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Information',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Update your phone numbers and mailing address',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Email Address'),
                          _buildTextField(_emailController, hint: 'user@email.com', keyboardType: TextInputType.emailAddress),

                          _buildLabel('Primary Phone'),
                          _buildTextField(_primaryPhoneController, hint: '+1 (555) 019-2834', keyboardType: TextInputType.phone),

                          _buildLabel('Alternate Phone'),
                          _buildTextField(_alternatePhoneController, hint: '+1 (555) 018-9921', keyboardType: TextInputType.phone),

                          _buildLabel('Mailing Address'),
                          _buildTextField(_addressController, hint: 'Enter mailing address', maxLines: 3),

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7A00),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _saveContactDetails,
                              child: const Text(
                                'Save Contact Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {required String hint, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width * 0.5, size.height + 20, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}