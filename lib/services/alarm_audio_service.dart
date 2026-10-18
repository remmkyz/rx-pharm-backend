import 'package:audioplayers/audioplayers.dart';

class AlarmAudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playAlarm({String soundName = 'Alarm (MP3)'}) async {
    try {
      String assetPath = 'sounds/alarm.mp3'; // Default custom MP3 file
      
      if (soundName == 'Digital Beep') {
        assetPath = 'sounds/beep.mp3'; // Optional alternative if you add it
      }

      await _audioPlayer.setSource(AssetSource(assetPath));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume();
    } catch (e) {
      print("Error playing alarm sound: $e");
    }
  }

  static Future<void> stopAlarm() async {
    await _audioPlayer.stop();
  }
}