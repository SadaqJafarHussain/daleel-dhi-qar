import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'app_language';

  Locale _locale = WidgetsBinding.instance.window.locale; // Use device locale as default

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  // Initialize language from storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage != null) {
      if (savedLanguage == 'ar') {
        _locale = const Locale('ar', 'SA');
      } else if (savedLanguage == 'en') {
        _locale = const Locale('en', 'US');
      }
      notifyListeners();
    }
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == 'ar') {
      _locale = const Locale('ar', 'SA');
    } else if (languageCode == 'en') {
      _locale = const Locale('en', 'US');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'ar') {
      await changeLanguage('en');
    } else {
      await changeLanguage('ar');
    }
  }

  TextDirection get textDirection =>
      _locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
}