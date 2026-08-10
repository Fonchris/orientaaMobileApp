import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active app [Locale] and persists it to SharedPreferences so the
/// user's language choice survives restarts.
class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_locale';
  static const Map<String, String> _languageToCode = {
    'English': 'en',
    'French': 'fr',
    'Arabic': 'ar',
    'Portuguese': 'pt',
  };
  static const Map<String, String> _codeToLanguage = {
    'en': 'English',
    'fr': 'French',
    'ar': 'Arabic',
    'pt': 'Portuguese',
  };

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// The display name of the current language (e.g. 'French').
  String get languageName => _codeToLanguage[_locale.languageCode] ?? 'English';

  /// Maps the Firestore `settings.language` display value to a locale code.
  static String codeForLanguage(String language) =>
      _languageToCode[language] ?? 'en';

  /// Maps a locale code back to the stored display value.
  static String languageForCode(String code) =>
      _codeToLanguage[code] ?? 'English';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && _codeToLanguage.containsKey(code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
