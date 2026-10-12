import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                  ),
                  _SettingsOptionCard(
                    icon: Icons.settings,
                    title: 'App Preferences',
                    subtitle: 'Theme, language and display',
                  ),
                  _SettingsOptionCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage notification settings',
                  ),
                  _SettingsOptionCard(
                    icon: Icons.security,
                    title: 'Privacy & Security',
                    subtitle: 'Data, permissions and more',
                  ),
                  _SettingsOptionCard(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'FAQs and Contact us',
                  ),
                  _SettingsOptionCard(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version and information',
                  ),
                  const SizedBox(height: 12),

                  // Bottom App Info Banner matching design mockups
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB680),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7A00),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medical_services_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PharmAssist',
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

class _SettingsOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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