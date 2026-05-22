import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that holds the current language choice.
/// Loaded once in main() before runApp(), then set by LanguageSelectScreen.
class LocaleService {
  static final LocaleService instance = LocaleService._();
  LocaleService._();

  bool isEnglish = false;

  /// Load persisted preference (called in main before runApp).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isEnglish = prefs.getBool('lang_en') ?? false;
  }

  /// Save and apply a new language choice.
  Future<void> setEnglish(bool value) async {
    isEnglish = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lang_en', value);
  }
}
