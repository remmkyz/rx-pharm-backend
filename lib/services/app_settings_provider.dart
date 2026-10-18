import 'package:flutter/material.dart';
import 'user_data_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'English (US)';
  double _textScaleFactor = 1.0; // 0.85 (Small), 1.0 (Medium), 1.2 (Large)

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  double get textScaleFactor => _textScaleFactor;

  // Load preferences from account storage
  Future<void> loadPreferences() async {
    final settings = await UserDataService.loadSettingsPreferences();
    
    final themeStr = settings['appTheme'] ?? 'Light Theme (Default)';
    if (themeStr == 'Dark Theme') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'System Default') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    _language = settings['language'] ?? 'English (US)';
    
    final sizeVal = (settings['textSize'] as num?)?.toDouble() ?? 2.0;
    if (sizeVal == 1.0) {
      _textScaleFactor = 0.85; // Small
    } else if (sizeVal == 3.0) {
      _textScaleFactor = 1.25; // Large
    } else {
      _textScaleFactor = 1.0;  // Medium
    }

    notifyListeners();
  }

  // Update Theme
  Future<void> setTheme(String themeName) async {
    if (themeName == 'Dark Theme') {
      _themeMode = ThemeMode.dark;
    } else if (themeName == 'System Default') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();

    final settings = await UserDataService.loadSettingsPreferences();
    settings['appTheme'] = themeName;
    await UserDataService.saveSettingsPreferences(settings);
  }

  // Update Language
  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();

    final settings = await UserDataService.loadSettingsPreferences();
    settings['language'] = lang;
    await UserDataService.saveSettingsPreferences(settings);
  }

  // Update Text Size
  Future<void> setTextSize(double sliderValue) async {
    if (sliderValue == 1.0) {
      _textScaleFactor = 0.85;
    } else if (sliderValue == 3.0) {
      _textScaleFactor = 1.25;
    } else {
      _textScaleFactor = 1.0;
    }
    notifyListeners();

    final settings = await UserDataService.loadSettingsPreferences();
    settings['textSize'] = sliderValue;
    await UserDataService.saveSettingsPreferences(settings);
  }
}