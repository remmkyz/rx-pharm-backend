import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_session.dart';
import 'user_data_service.dart';
import 'package:rx_pharm_assist/screens/login_screen.dart';

class AuthHelper {
  static Future<void> performLogout(BuildContext context) async {
    try {
      // 1. Clear in-memory active session data
      UserDataService.clearActiveSessionData();

      // 2. Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // 3. Clear Google Sign-In instance cache
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect(); // Clears cached account scope
      }

      // 4. Reset User Session state
      UserSession.clear();

      if (!context.mounted) return;

      // 5. Navigate to Login Screen and clear navigation stack
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