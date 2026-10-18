import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'services/app_settings_provider.dart';

// Instantiate the global app settings provider
final appSettingsProvider = AppSettingsProvider();

void main() async {
  // Ensure Flutter engine bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the generated configuration options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load account-isolated app preferences (theme, language, text size)
  await appSettingsProvider.loadPreferences();

  runApp(const RxPharmAssistApp());
}

class RxPharmAssistApp extends StatelessWidget {
  const RxPharmAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettingsProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Rx Pharm Assist',
          debugShowCheckedModeBanner: false,
          
          // Live Theme Mode Switch (Light / Dark / System)
          themeMode: appSettingsProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFFE8231F),
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFE8231F),
            scaffoldBackgroundColor: const Color(0xFF121212),
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          
          // Live App-wide Text Size Scaler
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(appSettingsProvider.textScaleFactor),
              ),
              child: child!,
            );
          },
          
          home: const WelcomeScreen(),
        );
      },
    );
  }
}