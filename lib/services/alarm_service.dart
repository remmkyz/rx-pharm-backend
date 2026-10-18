import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_item.dart';
import 'alarm_audio_service.dart'; // Import the alarm audio service

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  List<AlarmItem> _alarms = [];

  List<AlarmItem> get alarms => List.unmodifiable(_alarms);

  // Key generator tied directly to logged-in user[cite: 17]
  String _getUserStorageKey() {
    final user = FirebaseAuth.instance.currentUser;
    return 'alarms_${user?.email ?? user?.uid ?? 'guest'}';
  }

  // Load user-specific alarms from SharedPreferences[cite: 17]
  Future<void> loadUserAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserStorageKey();
    final String? jsonString = prefs.getString(key);

    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      _alarms = decoded.map((item) {
        final List<String> daysList = (item['days'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        return AlarmItem(
          id: item['id'] ?? '',
          label: item['label'] ?? '',
          time: TimeOfDay(
            hour: item['hour'] ?? 0,
            minute: item['minute'] ?? 0,
          ),
          enabled: item['enabled'] ?? true,
          vibration: item['vibration'] ?? true,
          days: daysList.toSet(),
        );
      }).toList();
    } else {
      _alarms = [];
    }
  }

  // Save current alarms bound to active user[cite: 17]
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserStorageKey();

    final List<Map<String, dynamic>> mappedList = _alarms.map((alarm) {
      return {
        'id': alarm.id,
        'label': alarm.label,
        'hour': alarm.time.hour,
        'minute': alarm.time.minute,
        'enabled': alarm.enabled,
        'vibration': alarm.vibration,
        'days': alarm.days.toList(),
      };
    }).toList();

    await prefs.setString(key, jsonEncode(mappedList));
  }

  Future<void> addAlarm(AlarmItem alarm) async {
    _alarms.add(alarm);
    await _saveToStorage();
  }

  Future<void> updateAlarm(AlarmItem updated) async {
    final index = _alarms.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _alarms[index] = updated;
      await _saveToStorage();
    }
  }

  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
    await _saveToStorage();
  }

  Future<void> deleteMultipleAlarms(Set<String> ids) async {
    _alarms.removeWhere((a) => ids.contains(a.id));
    await _saveToStorage();
  }

  void clearAlarms() {
    _alarms.clear();
  }

  // ==========================================
  // --- AUDIO ALARM TRIGGERS ---
  // ==========================================

  // Call this method when a scheduled alarm rings
  Future<void> triggerAlarmSound() async {
    await AlarmAudioService.playAlarm();
  }

  // Call this method when the user dismisses or takes their medicine
  Future<void> dismissAlarmSound() async {
    await AlarmAudioService.stopAlarm();
  }
}