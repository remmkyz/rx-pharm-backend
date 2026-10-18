import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prescription.dart';
import 'user_session.dart';

class UserDataService {
  static String _getUserKey(String suffix) {
    final user = FirebaseAuth.instance.currentUser;
    return 'user_${suffix}_${user?.email ?? user?.uid ?? 'guest'}';
  }

  // --- Profile Data ---
  static Future<void> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getUserKey('profile'));

    if (jsonString != null) {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      UserSession.firstName = data['firstName'] ?? '';
      UserSession.lastName = data['lastName'] ?? '';
      UserSession.age = data['age'] ?? '';
      UserSession.dob = data['dob'] ?? '';
      UserSession.emergencyContact = data['emergencyContact'] ?? '';
      UserSession.bloodType = data['bloodType'] ?? '';
      UserSession.gender = data['gender'] ?? '';

      final fullName = '${UserSession.firstName} ${UserSession.lastName}'.trim();
      UserSession.name = fullName.isNotEmpty ? fullName : 'Guest';
    }
  }

  static Future<void> saveUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'firstName': UserSession.firstName,
      'lastName': UserSession.lastName,
      'age': UserSession.age,
      'dob': UserSession.dob,
      'emergencyContact': UserSession.emergencyContact,
      'bloodType': UserSession.bloodType,
      'gender': UserSession.gender,
    };
    await prefs.setString(_getUserKey('profile'), jsonEncode(data));
  }

  // --- Contact Information ---
  static Future<Map<String, String>> loadContactInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final jsonString = prefs.getString(_getUserKey('contact'));

    if (jsonString != null) {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return {
        'email': data['email'] ?? user?.email ?? '',
        'primaryPhone': data['primaryPhone'] ?? '',
        'altPhone': data['altPhone'] ?? '',
        'mailingAddress': data['mailingAddress'] ?? '',
      };
    }
    return {
      'email': user?.email ?? '',
      'primaryPhone': '',
      'altPhone': '',
      'mailingAddress': '',
    };
  }

  static Future<void> saveContactInfo({
    required String email,
    required String primaryPhone,
    required String altPhone,
    required String mailingAddress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'email': email,
      'primaryPhone': primaryPhone,
      'altPhone': altPhone,
      'mailingAddress': mailingAddress,
    };
    await prefs.setString(_getUserKey('contact'), jsonEncode(data));
  }

  // --- Notification Preferences ---
  static Future<Map<String, bool>> loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getUserKey('notifications'));

    if (jsonString != null) {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return {
        'medicineReminders': data['medicineReminders'] ?? true,
        'refillAlerts': data['refillAlerts'] ?? true,
        'healthTips': data['healthTips'] ?? false,
        'emailNotifications': data['emailNotifications'] ?? true,
        'soundVibration': data['soundVibration'] ?? true,
      };
    }
    return {
      'medicineReminders': true,
      'refillAlerts': true,
      'healthTips': false,
      'emailNotifications': true,
      'soundVibration': true,
    };
  }

  static Future<void> saveNotificationPreferences(Map<String, bool> prefsMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getUserKey('notifications'), jsonEncode(prefsMap));
  }

  // ==========================================
  // --- SETTINGS PREFERENCES ---
  // ==========================================
  static Future<Map<String, dynamic>> loadSettingsPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getUserKey('app_settings'));

    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return {
      'twoFactorAuth': true,
      'appTheme': 'Light Theme (Default)',
      'language': 'English (US)',
      'textSize': 2.0,
      'locationService': true,
      'cameraAccess': false,
      'anonymousDiagnostics': true,
    };
  }

  static Future<void> saveSettingsPreferences(Map<String, dynamic> settingsMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getUserKey('app_settings'), jsonEncode(settingsMap));
  }

  // ==========================================
  // --- PRESCRIPTION HISTORY (per account) ---
  // Saved under the logged-in user's email, exactly like the profile data,
  // so it survives Log Out, the Back button and app restarts.
  // ==========================================
  static Map<String, dynamic> _prescriptionToMap(Prescription p) => {
        'id': p.id,
        'patientName': p.patientName,
        'patientAge': p.patientAge,
        'date': p.date,
        'doctorName': p.doctorName,
        'doctorLicense': p.doctorLicense,
        'imagePath': p.imagePath,
        'status': p.status,
        'medications': p.medications
            .map((m) => {
                  'genericName': m.genericName,
                  'brandName': m.brandName,
                  'quantity': m.quantity,
                  'instruction': m.instruction,
                })
            .toList(),
      };

  static Prescription _prescriptionFromMap(Map<String, dynamic> m) {
    final meds = (m['medications'] as List? ?? []).map((e) {
      final mm = Map<String, dynamic>.from(e as Map);
      return Medication(
        genericName: mm['genericName']?.toString() ?? '',
        brandName: mm['brandName']?.toString() ?? '',
        quantity: mm['quantity']?.toString() ?? '',
        instruction: mm['instruction']?.toString() ?? '',
      );
    }).toList();

    return Prescription(
      id: m['id']?.toString() ?? '',
      patientName: m['patientName']?.toString() ?? '',
      patientAge: (m['patientAge'] as num?)?.toInt() ?? 0,
      date: m['date']?.toString() ?? '',
      doctorName: m['doctorName']?.toString() ?? '',
      doctorLicense: m['doctorLicense']?.toString() ?? '',
      imagePath: m['imagePath']?.toString() ?? '',
      status: m['status']?.toString() ?? 'Pending',
      medications: meds,
    );
  }

  /// Reads the current account's saved prescriptions from storage.
  static Future<List<Prescription>> loadPrescriptionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getUserKey('prescriptions'));
    if (jsonString == null) return [];
    try {
      final list = jsonDecode(jsonString) as List;
      return list
          .map((e) => _prescriptionFromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('Failed to read prescription history: $e');
      return [];
    }
  }

  static Future<void> savePrescriptionHistory(List<Prescription> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _getUserKey('prescriptions'),
      jsonEncode(list.map(_prescriptionToMap).toList()),
    );
  }

  /// Loads the current account's history into the in-memory
  /// [prescriptionHistory] list used by the screens.
  static Future<void> syncPrescriptionHistory() async {
    final list = await loadPrescriptionHistory();
    prescriptionHistory
      ..clear()
      ..addAll(list);
  }

  /// Next free id ("001", "002", ...). Never reuses an id after a delete.
  static Future<String> nextPrescriptionId() async {
    final list = await loadPrescriptionHistory();
    var maxId = 0;
    for (final p in list) {
      final n = int.tryParse(p.id) ?? 0;
      if (n > maxId) maxId = n;
    }
    return (maxId + 1).toString().padLeft(3, '0');
  }

  /// Adds a new prescription (newest first) and saves it to storage.
  static Future<void> addPrescription(Prescription p) async {
    final list = await loadPrescriptionHistory();
    list.insert(0, p);
    await savePrescriptionHistory(list);
    await syncPrescriptionHistory();
  }

  /// Deletes a prescription (and its saved photo) from storage.
  static Future<void> deletePrescription(String id) async {
    final list = await loadPrescriptionHistory();
    for (final p in list.where((p) => p.id == id)) {
      if (p.imagePath.isNotEmpty) {
        try {
          final f = File(p.imagePath);
          if (await f.exists()) await f.delete();
        } catch (e) {
          debugPrint('Could not delete prescription photo: $e');
        }
      }
    }
    list.removeWhere((p) => p.id == id);
    await savePrescriptionHistory(list);
    await syncPrescriptionHistory();
  }

  // --- Helper to check if any notification is enabled for Header Bell ---
  static Future<bool> hasActiveNotifications() async {
    final prefs = await loadNotificationPreferences();
    return prefs.values.contains(true);
  }

  static void clearActiveSessionData() {
    UserSession.clear();
  }
}
