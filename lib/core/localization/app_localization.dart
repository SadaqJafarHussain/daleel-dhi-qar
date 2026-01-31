import 'package:flutter/material.dart';
import 'translations/en_translations.dart';
import 'translations/ar_translations.dart';

/// Supported locales for the app
class AppLocales {
  static const Locale english = Locale('en');
  static const Locale arabic = Locale('ar');

  static const List<Locale> supportedLocales = [english, arabic];

  static const List<String> supportedLanguageCodes = ['en', 'ar'];
}

/// Main localization class for the app
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Helper method to get the right translation from context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Static map of translations combining all language files
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': enTranslations,
    'ar': arTranslations,
  };

  /// Get translation by key
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  /// Short method for easy access
  String t(String key) => translate(key);

  /// Get current language code
  String get languageCode => locale.languageCode;

  /// Check if current locale is Arabic
  bool get isArabic => locale.languageCode == 'ar';

  /// Check if current locale is English
  bool get isEnglish => locale.languageCode == 'en';

  /// Get text direction based on locale
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;
}

/// Localization Delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocales.supportedLanguageCodes.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
