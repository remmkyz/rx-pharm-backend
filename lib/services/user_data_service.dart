import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// Note: You can replace standard SharedPreferences with Cloud Firestore for cross-device sync.
import 'package:shared_preferences/shared_preferences.dart';

class UserDataService {
  /// Returns the active user's unique ID or 'guest' if unauthenticated
  static String get _userKey {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'guest_user';
  }

  // --- SCHEDULE & ALARMS ---
  static Future<void> saveAlarms(List<String> alarmJsonList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_userKey}_alarms', alarmJsonList);
  }

  static Future<List<String>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_userKey}_alarms') ?? [];
  }

  // --- ASK AI CHAT HISTORY ---
  static Future<void> saveChatHistory(List<String> chatJsonList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_userKey}_ai_chat', chatJsonList);
  }

  static Future<List<String>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_userKey}_ai_chat') ?? [];
  }

  // --- MAP LOCATIONS / SAVED PLACES ---
  static Future<void> saveMapLocations(List<String> locationsJsonList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_userKey}_map_locations', locationsJsonList);
  }

  static Future<List<String>> loadMapLocations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_userKey}_map_locations') ?? [];
  }

  // --- SCANNER HISTORY ---
  static Future<void> saveScanHistory(List<String> scanJsonList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${_userKey}_scans', scanJsonList);
  }

  static Future<List<String>> loadScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('${_userKey}_scans') ?? [];
  }

  /// Called during logout to clear in-memory caches and unbind active listeners
  static void clearActiveSessionData() {
    // Reset in-memory cached state if you maintain local singleton lists
    debugPrint("Active session data unlinked for $_userKey");
  }
}