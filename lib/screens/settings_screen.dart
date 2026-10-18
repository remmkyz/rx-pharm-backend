import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_data_service.dart';
import '../main.dart'; // Imports appSettingsProvider for live theme/text adjustments

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Stack(
            children: [
              ClipPath(
                clipper: _HeaderWaveClipper(),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: const Color(0xFFE8231F),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFFE8231F)),
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
                    'Settings',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Customize your app experience',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  _SettingsOptionCard(
                    icon: Icons.person,
                    title: 'Account Settings',
                    subtitle: 'Update your profile and security',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                    ),
                  ),
                  _SettingsOptionCard(
                    icon: Icons.settings,
                    title: 'App Preferences',
                    subtitle: 'Theme, language and display',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppPreferencesScreen()),
                    ),
                  ),
                  _SettingsOptionCard(
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Data, permissions and more',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                    ),
                  ),
                  _SettingsOptionCard(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'FAQs and Contact us',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                    ),
                  ),
                  _SettingsOptionCard(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version and information',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8231F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medical_services_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rx Pharm Assist',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
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

// ==========================================
// 1. ACCOUNT SETTINGS SCREEN
// ==========================================
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _twoFactorAuth = true;
  bool _isLoading = true;
  Map<String, dynamic> _allSettings = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _allSettings = await UserDataService.loadSettingsPreferences();
    setState(() {
      _twoFactorAuth = _allSettings['twoFactorAuth'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, dynamic val) async {
    _allSettings[key] = val;
    await UserDataService.saveSettingsPreferences(_allSettings);
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8231F)),
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                await user?.updatePassword(passwordController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSubHeader(context, 'Account Settings', 'Manage security and account credentials'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8231F)))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildCardTile(
                        context,
                        icon: Icons.key,
                        title: 'Change Password',
                        subtitle: 'Last changed 30 days ago',
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      SwitchListTile(
                        title: const Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Secure sign-in with SMS verification', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        value: _twoFactorAuth,
                        activeColor: const Color(0xFFE8231F),
                        onChanged: (val) {
                          setState(() => _twoFactorAuth = val);
                          _updateSetting('twoFactorAuth', val);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.red),
                        title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        onTap: () {},
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. APP PREFERENCES SCREEN
// ==========================================
class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  late String _selectedTheme;
  late String _selectedLanguage;
  late double _textSizeVal;

  @override
  void initState() {
    super.initState();
    if (appSettingsProvider.themeMode == ThemeMode.dark) {
      _selectedTheme = 'Dark Theme';
    } else if (appSettingsProvider.themeMode == ThemeMode.system) {
      _selectedTheme = 'System Default';
    } else {
      _selectedTheme = 'Light Theme (Default)';
    }

    _selectedLanguage = appSettingsProvider.language;

    if (appSettingsProvider.textScaleFactor < 1.0) {
      _textSizeVal = 1.0;
    } else if (appSettingsProvider.textScaleFactor > 1.0) {
      _textSizeVal = 3.0;
    } else {
      _textSizeVal = 2.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSubHeader(context, 'App Preferences', 'Customize display theme and layout'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('App Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTheme,
                  items: ['Light Theme (Default)', 'Dark Theme', 'System Default']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTheme = val);
                      appSettingsProvider.setTheme(val);
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  items: ['English (US)', 'Filipino', 'Spanish']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedLanguage = val);
                      appSettingsProvider.setLanguage(val);
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Text Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Slider(
                  value: _textSizeVal,
                  min: 1.0,
                  max: 3.0,
                  divisions: 2,
                  activeColor: const Color(0xFFE8231F),
                  label: _textSizeVal == 1.0 ? 'Small' : (_textSizeVal == 2.0 ? 'Medium' : 'Large'),
                  onChanged: (val) {
                    setState(() => _textSizeVal = val);
                    appSettingsProvider.setTextSize(val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. PRIVACY & SECURITY SCREEN
// ==========================================
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _locationService = true;
  bool _cameraAccess = false;
  bool _anonymousDiagnostics = true;
  bool _isLoading = true;
  Map<String, dynamic> _allSettings = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _allSettings = await UserDataService.loadSettingsPreferences();
    setState(() {
      _locationService = _allSettings['locationService'] ?? true;
      _cameraAccess = _allSettings['cameraAccess'] ?? false;
      _anonymousDiagnostics = _allSettings['anonymousDiagnostics'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, dynamic val) async {
    _allSettings[key] = val;
    await UserDataService.saveSettingsPreferences(_allSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSubHeader(context, 'Privacy & Security', 'Control data permissions and sharing'),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8231F)))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      SwitchListTile(
                        title: const Text('Location Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Find nearby pharmacies', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        value: _locationService,
                        activeColor: const Color(0xFFE8231F),
                        onChanged: (val) {
                          setState(() => _locationService = val);
                          _updateSetting('locationService', val);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Camera Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Scan medicine barcodes and prescriptions', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        value: _cameraAccess,
                        activeColor: const Color(0xFFE8231F),
                        onChanged: (val) {
                          setState(() => _cameraAccess = val);
                          _updateSetting('cameraAccess', val);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Anonymous Diagnostics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Share crash logs to improve app', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        value: _anonymousDiagnostics,
                        activeColor: const Color(0xFFE8231F),
                        onChanged: (val) {
                          setState(() => _anonymousDiagnostics = val);
                          _updateSetting('anonymousDiagnostics', val);
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFEBEE),
                          foregroundColor: const Color(0xFFE8231F),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Medical Data PDF exported successfully!')),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Export Medical Data (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. HELP & SUPPORT SCREEN
// ==========================================
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSubHeader(context, 'Help & Support', 'Frequently Asked Questions and assistance'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildFaqItem(
                  'How do I schedule a medicine reminder?',
                  'Go to "My Medicines" from the User tab and click the "+ Add" button to configure dosages and alarm times.',
                ),
                _buildFaqItem(
                  'How do I change my primary email?',
                  'Navigate to "Contact Information" in your User Profile page to update email and phone details.',
                ),
                _buildFaqItem(
                  'Is my medical data encrypted?',
                  'Yes, Rx Pharm Assist uses 256-bit AES encryption for all offline and synchronized patient records.',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.headset_mic, color: Color(0xFFE8231F), size: 36),
                      const SizedBox(height: 8),
                      const Text('Need further help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8231F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Connecting to Live Support...')),
                          );
                        },
                        child: const Text('Start Live Chat', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(answer, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ],
    );
  }
}

// ==========================================
// 5. ABOUT SCREEN
// ==========================================
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildSubHeader(context, 'About Rx Pharm Assist', 'App information and software details'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8231F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medical_services, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 12),
                      const Text('Rx Pharm Assist Mobile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text('Version 1.0.0 (Build 2026.09)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 20),
                      const Text(
                        'Rx Pharm Assist is your personal digital healthcare companion, enabling real-time prescription tracking, refill alerts, and emergency profile management.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 40),
                ListTile(
                  title: const Text('Terms of Service', style: TextStyle(color: Color(0xFFE8231F), fontWeight: FontWeight.bold)),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Privacy Policy', style: TextStyle(color: Color(0xFFE8231F), fontWeight: FontWeight.bold)),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Open Source Licenses', style: TextStyle(color: Color(0xFFE8231F), fontWeight: FontWeight.bold)),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// REUSABLE WIDGET HELPERS
// ==========================================
Widget _buildSubHeader(BuildContext context, String title, String subtitle) {
  return Column(
    children: [
      Stack(
        children: [
          ClipPath(
            clipper: _HeaderWaveClipper(),
            child: Container(
              height: 120,
              width: double.infinity,
              color: const Color(0xFFE8231F),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFFE8231F)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildCardTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: Color(0xFFE8231F), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFE8231F)),
    ),
  );
}

class _SettingsOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsOptionCard({
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
        color: Theme.of(context).cardColor,
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
            color: Color(0xFFE8231F),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFE8231F)),
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