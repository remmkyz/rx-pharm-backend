import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the generated configuration options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RxPharmAssistApp());
}

class RxPharmAssistApp extends StatelessWidget {
  const RxPharmAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rx Pharm Assist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFE8231F),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}