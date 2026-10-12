import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_session.dart';
import '../services/auth_helper.dart';
import 'alarm_list_screen.dart';
import 'ask_ai_screen.dart';
import 'map_screen.dart';
import 'user_info_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _getUserDisplayName({bool fullName = false}) {
    String name = '';

    // 1. Prioritize UserSession name if available
    if (UserSession.name.isNotEmpty && UserSession.name != 'User') {
      name = UserSession.name;
    } else {
      // 2. Fall back to Firebase user display name
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser?.displayName != null && firebaseUser!.displayName!.isNotEmpty) {
        name = firebaseUser.displayName!;
      } else {
        name = 'User';
      }
    }

    if (!fullName) {
      return name.split(' ').first;
    }
    return name;
  }

  void _refreshState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _getUserDisplayName(fullName: false);
    final fullName = _getUserDisplayName(fullName: true);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _DashboardDrawer(
        fullName: fullName,
        onLogout: () => AuthHelper.performLogout(context),
        onUserUpdated: _refreshState,
      ),
      body: Column(
        children: [
          _DashboardHeader(
            userName: displayName,
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What can we help you with today?',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  _FeatureCard(
                    icon: Icons.alarm,
                    label: 'Schedule and Alarm',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AlarmListScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    icon: Icons.smart_toy_outlined,
                    label: 'Ask AI',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AskAiScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    icon: Icons.location_on_outlined,
                    label: 'Map',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE8231F),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );
        },
        child: const Icon(Icons.crop_free, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  final String fullName;
  final VoidCallback onLogout;
  final VoidCallback onUserUpdated;

  const _DashboardDrawer({
    required this.fullName,
    required this.onLogout,
    required this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFA96B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 45),
              ),
              const SizedBox(height: 12),
              Text(
                fullName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 30),
              _DrawerMenuItem(
                icon: Icons.person_outline,
                label: 'User',
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserInfoScreen()),
                  );
                  onUserUpdated();
                },
              ),
              const SizedBox(height: 12),
              _DrawerMenuItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _DrawerMenuItem(
                icon: Icons.access_time,
                label: 'History',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              const Spacer(),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                shadowColor: Colors.black12,
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onLogout,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    child: const Row(
                      children: [
                        Icon(Icons.logout, color: Color(0xFFFFA96B)),
                        SizedBox(width: 20),
                        Text(
                          'Log out',
                          style: TextStyle(
                            color: Color(0xFFFFA96B),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFA96B),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFFFA96B)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onMenuPressed;

  const _DashboardHeader({
    required this.userName,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _DashboardWaveClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 60),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE0C7), Color(0xFFFFA96B)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context))
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.arrow_back, color: Colors.black87, size: 24),
                          ),
                        ),
                      ),
                    InkWell(
                      onTap: onMenuPressed,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.menu, color: Colors.black87, size: 26),
                      ),
                    ),
                  ],
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none, color: Color.fromARGB(221, 251, 250, 250), size: 26),
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8231F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Hello,',
              style: TextStyle(fontSize: 20, color: Colors.black87),
            ),
            Text(
              '$userName!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE8231F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 30,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8231F),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8231F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}