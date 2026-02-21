import 'dart:convert';
import 'package:flutter/services.dart';

/// Localization service for managing app language
class LocalizationService {
  static LocalizationService? _instance;
  Map<String, dynamic> _translations = {};
  String _currentLocale = 'de'; // Default to German

  LocalizationService._();

  factory LocalizationService() {
    _instance ??= LocalizationService._();
    return _instance!;
  }

  String get currentLocale => _currentLocale;

  /// Load translations for the specified locale
  Future<void> setLocale(String locale) async {
    _currentLocale = locale;
    await _loadTranslations(locale);
  }

  /// Load translation file from assets
  Future<void> _loadTranslations(String locale) async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/l10n/app_$locale.arb');
      _translations = jsonDecode(jsonString);
    } catch (e) {
      print('Error loading translations for $locale: $e');
      // Fallback to German if file not found
      if (locale != 'de') {
        await _loadTranslations('de');
      }
    }
  }

  /// Get translated string by key
  String t(String key, {Map<String, String>? args}) {
    var value = _translations[key] as String? ?? key;

    // Replace placeholders if arguments provided
    if (args != null) {
      args.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }

    return value;
  }

  /// Get all available locales
  static const List<String> availableLocales = ['en', 'de'];

  /// Get locale display name
  static String getLocaleName(String locale) {
    switch (locale) {
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      default:
        return locale;
    }
  }
}

/// Extension to access localization service easily
extension LocalizeString on String {
  String tr({Map<String, String>? args}) {
    return LocalizationService().t(this, args: args);
  }
}
