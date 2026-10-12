import 'package:flutter/material.dart';

/// Temporary stand-in screen for a Dashboard destination that hasn't
/// been built out yet. Once a real screen exists (e.g. the Schedule &
/// Alarm list), swap the navigation target in dashboard_screen.dart
/// away from this and point it at the real screen instead.
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFE8231F),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          '"$title" screen coming soon.',
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}