import 'package:flutter/material.dart';

class AlarmSoundSelectionScreen extends StatelessWidget {
  final String currentSound;

  const AlarmSoundSelectionScreen({super.key, required this.currentSound});

  @override
  Widget build(BuildContext context) {
    final List<String> availableSounds = [
      'Nature',
      'Alarm (MP3)',
      'Digital Beep',
      'Gentle Chime',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Select Alarm Sound', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFE8231F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: availableSounds.length,
        itemBuilder: (context, index) {
          final sound = availableSounds[index];
          final isSelected = sound == currentSound;

          return ListTile(
            title: Text(sound, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Color(0xFFE8231F))
                : const Icon(Icons.circle_outlined, color: Colors.grey),
            onTap: () {
              Navigator.pop(context, sound); // Return selected sound name back to alarm settings
            },
          );
        },
      ),
    );
  }
}