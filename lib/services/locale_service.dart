import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that extends ChangeNotifier to support reactive language changes.
/// Loaded once in main() before runApp(), then set by LanguageSelectScreen.
class LocaleService extends ChangeNotifier {
  static final LocaleService instance = LocaleService._();
  LocaleService._();

  bool isEnglish = false;
  bool hasChosenLanguage = false; // true if user ever picked a language

  /// Load persisted preference (called in main before runApp).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hasChosenLanguage = prefs.containsKey('lang_en');
    isEnglish = prefs.getBool('lang_en') ?? false;
  }

  /// Save and apply a new language choice.
  Future<void> setEnglish(bool value) async {
    isEnglish = value;
    hasChosenLanguage = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lang_en', value);
    notifyListeners();
  }
}
