import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_session.dart';
import 'user_data_service.dart';
import 'alarm_service.dart'; // Clears in-memory alarms
import '../models/prescription.dart'; // Clears in-memory scan history
import 'package:rx_pharm_assist/screens/login_screen.dart';

class AuthHelper {
  static Future<void> performLogout(BuildContext context) async {
    try {
      // 1. Clear in-memory active session data from UserDataService
      UserDataService.clearActiveSessionData();

      // 2. Clear AlarmService in-memory list
      AlarmService().clearAlarms();

      // 3. Clear global scanner prescription history
      prescriptionHistory.clear();

      // 4. Reset static UserSession state
      UserSession.clear();

      // 5. Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // 6. Clear Google Sign-In instance cache and revoke access tokens
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        try {
          await googleSignIn.disconnect(); // Clears cached account scope
        } catch (e) {
          debugPrint("Google disconnect skipped/failed: $e");
        }
      }

      if (!context.mounted) return;

      // 7. Navigate to Login Screen and clear the entire navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }
}