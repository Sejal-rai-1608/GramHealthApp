import 'package:flutter/material.dart';
import 'translations.dart';

enum AppLanguage {
  english(code: 'en', nativeName: 'English', englishName: 'English'),
  hindi(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
  marathi(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
  gujarati(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati');

  final String code;
  final String nativeName;
  final String englishName;

  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });

  Locale get locale => Locale(code);
}

class LanguageController {
  LanguageController._();
  static final LanguageController instance = LanguageController._();

  final ValueNotifier<AppLanguage> currentLanguage = ValueNotifier<AppLanguage>(AppLanguage.hindi);

  void setLanguage(AppLanguage language) {
    currentLanguage.value = language;
  }

  String translate(String key) {
    final langCode = currentLanguage.value.code;
    return kTranslations[langCode]?[key] ?? kTranslations['en']?[key] ?? key;
  }
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return LanguageController.instance.translate(key);
  }

  AppLanguage get currentLanguage => LanguageController.instance.currentLanguage.value;
}
