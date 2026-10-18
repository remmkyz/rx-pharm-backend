import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_session.dart';
import '../services/user_data_service.dart';
import '../services/auth_helper.dart';
import 'contact_info_screen.dart'; // <-- Added import
import 'notification_settings_screen.dart'; // <-- Added import

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await UserDataService.loadUserProfile();
    if (mounted) setState(() {});
  }

  String _getUserDisplayName() {
    if (UserSession.name.isNotEmpty) {
      return UserSession.name;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return 'Guest';
  }

  String _getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email!;
    }
    return UserSession.email;
  }

  void _navigateToEditDetails(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditUserDetailScreen(),
      ),
    );
    setState(() {}); // Refresh screen state with updated values
  }

  @override
  Widget build(BuildContext context) {
    final userName = _getUserDisplayName();
    final userEmail = _getUserEmail();
    final userAge = UserSession.age;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Manage your Account',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => _navigateToEditDetails(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB680),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 48, color: Color(0xFFFF7A00)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  'Patient',
                                  style: TextStyle(color: Colors.black45, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 14, color: Colors.black87),
                                    const SizedBox(width: 4),
                                    Text(
                                      userAge.isNotEmpty ? 'Age: $userAge' : 'Age: --',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 14, color: Colors.black87),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        userEmail.isNotEmpty ? userEmail : 'No Email',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF7A00),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _UserMenuCard(
                    icon: Icons.phone,
                    title: 'Contact Information',
                    subtitle: 'Phone and Email',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContactInfoScreen()),
                      );
                    },
                  ),
                  _UserMenuCard(
                    icon: Icons.medication,
                    title: 'My Medicines',
                    subtitle: 'Manage your Alerts',
                    onTap: () {}, // Kept open for Scanner integration later
                  ),
                  _UserMenuCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB680),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => AuthHelper.performLogout(context),
                        icon: const Icon(Icons.logout, color: Color(0xFFFF7A00)),
                        label: const Text(
                          'Log out',
                          style: TextStyle(
                            color: Color(0xFFFF7A00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _UserMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFF7A00),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFFF7A00)),
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

// EditUserDetailScreen remains the same as previously defined for Personal Information
class EditUserDetailScreen extends StatefulWidget {
  const EditUserDetailScreen({super.key});

  @override
  State<EditUserDetailScreen> createState() => _EditUserDetailScreenState();
}

class _EditUserDetailScreenState extends State<EditUserDetailScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _dobController;
  late TextEditingController _emergencyContactController;

  String? _selectedBloodType;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController(text: UserSession.firstName);
    _lastNameController = TextEditingController(text: UserSession.lastName);
    _ageController = TextEditingController(text: UserSession.age);
    _dobController = TextEditingController(text: UserSession.dob);
    _emergencyContactController = TextEditingController(text: UserSession.emergencyContact);

    _selectedBloodType = UserSession.bloodType.isNotEmpty ? UserSession.bloodType : null;
    _selectedGender = UserSession.gender.isNotEmpty ? UserSession.gender : null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    UserSession.firstName = firstName;
    UserSession.lastName = lastName;
    UserSession.age = _ageController.text.trim();
    UserSession.dob = _dobController.text.trim();
    UserSession.emergencyContact = _emergencyContactController.text.trim();
    UserSession.bloodType = _selectedBloodType ?? '';
    UserSession.gender = _selectedGender ?? '';

    final fullName = '$firstName $lastName'.trim();
    UserSession.name = fullName.isNotEmpty ? fullName : 'Guest';

    await UserDataService.saveUserProfile();

    if (mounted) Navigator.pop(context);
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
            child: SingleChildScrollView(
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
                      'Personal Information',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'View and edit your personal medical details',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    _buildFieldLabel('First Name'),
                    _buildTextField(_firstNameController, hint: 'Enter First Name'),

                    _buildFieldLabel('Last Name'),
                    _buildTextField(_lastNameController, hint: 'Enter Last Name'),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Age'),
                              _buildTextField(_ageController, hint: 'Age', keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Blood Type'),
                              _buildDropdownField(
                                value: _selectedBloodType,
                                hint: 'Select',
                                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                                onChanged: (val) {
                                  setState(() => _selectedBloodType = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _buildFieldLabel('Date of Birth'),
                    _buildTextField(_dobController, hint: 'MM/DD/YYYY', suffixIcon: Icons.calendar_today),

                    _buildFieldLabel('Gender'),
                    _buildDropdownField(
                      value: _selectedGender,
                      hint: 'Select Gender',
                      items: ['Male', 'Female', 'Other'],
                      onChanged: (val) {
                        setState(() => _selectedGender = val);
                      },
                    ),

                    _buildFieldLabel('Emergency Contact'),
                    _buildTextField(_emergencyContactController, hint: 'Contact Details'),

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
                        onPressed: _saveDetails,
                        child: const Text(
                          'Save Personal Information',
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {required String hint, TextInputType keyboardType = TextInputType.text, IconData? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey, size: 18) : null,
        ),
      ),
    );
  }

  Widget _buildDropdownField({required String? value, required String hint, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}