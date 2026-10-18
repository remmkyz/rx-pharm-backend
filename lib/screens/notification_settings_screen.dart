import 'package:flutter/material.dart';
import '../services/user_data_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _medicineReminders = true;
  bool _refillAlerts = true;
  bool _healthTips = false;
  bool _emailNotifications = true;
  bool _soundVibration = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await UserDataService.loadNotificationPreferences();
    setState(() {
      _medicineReminders = prefs['medicineReminders'] ?? true;
      _refillAlerts = prefs['refillAlerts'] ?? true;
      _healthTips = prefs['healthTips'] ?? false;
      _emailNotifications = prefs['emailNotifications'] ?? true;
      _soundVibration = prefs['soundVibration'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(String key, bool value) async {
    setState(() {
      if (key == 'medicineReminders') _medicineReminders = value;
      if (key == 'refillAlerts') _refillAlerts = value;
      if (key == 'healthTips') _healthTips = value;
      if (key == 'emailNotifications') _emailNotifications = value;
      if (key == 'soundVibration') _soundVibration = value;
    });

    final prefsMap = {
      'medicineReminders': _medicineReminders,
      'refillAlerts': _refillAlerts,
      'healthTips': _healthTips,
      'emailNotifications': _emailNotifications,
      'soundVibration': _soundVibration,
    };

    await UserDataService.saveNotificationPreferences(prefsMap);
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
                            'Notifications',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Configure alerts and reminder preferences',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 20),

                          _buildCheckboxTile(
                            title: 'Medicine Reminders',
                            subtitle: "Receive alerts when it's time for dosage",
                            value: _medicineReminders,
                            onChanged: (val) => _updatePreference('medicineReminders', val ?? false),
                          ),
                          _buildCheckboxTile(
                            title: 'Refill Alerts',
                            subtitle: 'Get notified when stock is running low',
                            value: _refillAlerts,
                            onChanged: (val) => _updatePreference('refillAlerts', val ?? false),
                          ),
                          _buildCheckboxTile(
                            title: 'Health & Wellness Tips',
                            subtitle: 'Daily health recommendations',
                            value: _healthTips,
                            onChanged: (val) => _updatePreference('healthTips', val ?? false),
                          ),
                          _buildCheckboxTile(
                            title: 'Email Notifications',
                            subtitle: 'Receive summary reports via email',
                            value: _emailNotifications,
                            onChanged: (val) => _updatePreference('emailNotifications', val ?? false),
                          ),
                          _buildCheckboxTile(
                            title: 'Sound & Vibration',
                            subtitle: 'Play tone for critical alarms',
                            value: _soundVibration,
                            onChanged: (val) => _updatePreference('soundVibration', val ?? false),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Checkbox(
            value: value,
            activeColor: const Color(0xFFFF7A00),
            onChanged: onChanged,
          ),
        ],
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