import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm_item.dart';
import '../services/alarm_service.dart';
import '../services/auth_helper.dart';
import '../services/user_session.dart';
import 'alarm_setting_screen.dart';
import 'user_info_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AlarmService _alarmService = AlarmService();
  final Set<String> _selectedAlarmIds = {};
  bool _isSelectionMode = false;

  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _triggeredThisMinute = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkAlarms());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _checkAlarms() async {
    final now = DateTime.now();
    final currentMinuteKey = "${now.hour}:${now.minute}";

    for (var alarm in _alarmService.alarms) {
      if (!alarm.enabled) continue;

      if (alarm.time.hour == now.hour && alarm.time.minute == now.minute) {
        final triggerId = "${alarm.id}_$currentMinuteKey";
        if (_triggeredThisMinute.contains(triggerId)) continue;

        _triggeredThisMinute.add(triggerId);
        _triggerAlarm(alarm);
      }
    }
  }

  Future<void> _triggerAlarm(AlarmItem alarm) async {
    if (alarm.vibration) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 2000);
      }
    }

    try {
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ALARM: ${alarm.label}'),
        backgroundColor: const Color(0xFFE8231F),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _getUserDisplayName({bool fullName = false}) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    String name = 'User';

    if (firebaseUser?.displayName != null && firebaseUser!.displayName!.isNotEmpty) {
      name = firebaseUser.displayName!;
    } else if (UserSession.name.isNotEmpty && UserSession.name != 'User') {
      name = UserSession.name;
    }

    if (!fullName) {
      return name.split(' ').first;
    }
    return name;
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthHelper.performLogout(context);
  }

  Future<void> _addAlarm() async {
    final newAlarm = await Navigator.push<AlarmItem>(
      context,
      MaterialPageRoute(builder: (_) => const AlarmSettingScreen()),
    );

    if (newAlarm != null) {
      setState(() {
        _alarmService.addAlarm(newAlarm);
      });
    }
  }

  Future<void> _editAlarm(AlarmItem alarm) async {
    final updatedAlarm = await Navigator.push<AlarmItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AlarmSettingScreen(existingAlarm: alarm),
      ),
    );

    if (updatedAlarm != null) {
      setState(() {
        _alarmService.updateAlarm(updatedAlarm);
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedAlarmIds.contains(id)) {
        _selectedAlarmIds.remove(id);
        if (_selectedAlarmIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedAlarmIds.add(id);
      }
    });
  }

  void _deleteSelectedAlarms() {
    setState(() {
      _alarmService.deleteMultipleAlarms(_selectedAlarmIds);
      _selectedAlarmIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _getUserDisplayName(fullName: true);
    final alarms = _alarmService.alarms;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _DashboardDrawer(
        fullName: fullName,
        onLogout: () => _handleLogout(context),
      ),
      body: Column(
        children: [
          _AlarmHeader(
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            isSelectionMode: _isSelectionMode,
            selectedCount: _selectedAlarmIds.length,
            onDeleteSelected: _deleteSelectedAlarms,
            onToggleSelectionMode: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) _selectedAlarmIds.clear();
              });
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 24, color: Colors.black),
                          children: [
                            TextSpan(text: 'Your '),
                            TextSpan(
                              text: 'Alarm',
                              style: TextStyle(
                                color: Color(0xFFE8231F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (alarms.isNotEmpty && !_isSelectionMode)
                        IconButton(
                          icon: const Icon(Icons.checklist, color: Color(0xFFE8231F)),
                          onPressed: () {
                            setState(() => _isSelectionMode = true);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (alarms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No alarms set.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ...alarms.map((alarm) {
                      final isSelected = _selectedAlarmIds.contains(alarm.id);
                      return Dismissible(
                        key: Key(alarm.id),
                        direction: _isSelectionMode
                            ? DismissDirection.none
                            : DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() {
                            _alarmService.deleteAlarm(alarm.id);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedAlarmIds.add(alarm.id);
                                });
                              }
                            },
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(alarm.id);
                              } else {
                                _editAlarm(alarm);
                              }
                            },
                            child: _AlarmCard(
                              alarm: alarm,
                              isSelectionMode: _isSelectionMode,
                              isSelected: isSelected,
                              onSelectChanged: (_) => _toggleSelection(alarm.id),
                              onToggle: (value) {
                                setState(() => alarm.enabled = value);
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  if (!_isSelectionMode)
                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _addAlarm,
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8231F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add New Alarm',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onDeleteSelected;
  final VoidCallback onToggleSelectionMode;

  const _AlarmHeader({
    required this.onMenuPressed,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onDeleteSelected,
    required this.onToggleSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _AlarmWaveClipper(),
      child: Container(
        width: double.infinity,
        height: 130,
        padding: const EdgeInsets.fromLTRB(16, 44, 16, 40),
        color: const Color(0xFFF4711E),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (Navigator.canPop(context)) ...[
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: onMenuPressed,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.menu, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            if (isSelectionMode)
              Row(
                children: [
                  Text(
                    '$selectedCount Selected',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: selectedCount > 0 ? onDeleteSelected : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onToggleSelectionMode,
                  ),
                ],
              )
            else
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AlarmWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AlarmCard extends StatelessWidget {
  final AlarmItem alarm;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;
  final ValueChanged<bool> onToggle;

  const _AlarmCard({
    required this.alarm,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectChanged,
    required this.onToggle,
  });

  String _formatTimeWithPeriod(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String get _repeatLabel {
    if (alarm.days.isEmpty) {
      return 'Once';
    } else if (alarm.days.length == 7) {
      return 'Repeat';
    } else {
      return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF0ED) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFE8231F) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      activeColor: const Color(0xFFE8231F),
                      onChanged: onSelectChanged,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _formatTimeWithPeriod(alarm.time),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _repeatLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE8231F),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isSelectionMode)
                Switch(
                  value: alarm.enabled,
                  onChanged: onToggle,
                  activeThumbColor: const Color(0xFFE8231F),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            alarm.label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dayLabels.map((day) {
              final isSelectedDay = alarm.days.contains(day);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelectedDay ? const Color(0xFFE8231F) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelectedDay ? Colors.white : Colors.grey[600],
                    fontWeight: isSelectedDay ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  final String fullName;
  final VoidCallback onLogout;

  const _DashboardDrawer({
    required this.fullName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F2FA),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB074),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _DrawerCardMenuItem(
                      icon: Icons.person_outline,
                      title: 'User',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserInfoScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _DrawerCardMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _DrawerCardMenuItem(
                      icon: Icons.access_time,
                      title: 'History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(
                      Icons.logout,
                      color: Color(0xFFFFB074),
                    ),
                    title: const Text(
                      'Log out',
                      style: TextStyle(
                        color: Color(0xFFFFB074),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
                    },
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

class _DrawerCardMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerCardMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFB074),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFFFFB074),
        ),
        onTap: onTap,
      ),
    );
  }
}