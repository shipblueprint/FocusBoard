import 'package:flutter/material.dart';

/// Locale metadata for the languages we support.
class Language {
  final Locale locale;
  final bool supportRTL;
  final String languageName;

  static final List<Language> languages = <Language>[
    Language(const Locale('en'), 'English'),
  ];

  Language(this.locale, this.languageName, [this.supportRTL = false]);

  static Future<bool> init() async {
    return true;
  }

  static List<Locale> getLocales() {
    return languages.map((Language e) => e.locale).toList();
  }

  static List<String> getLanguagesCodes() {
    return languages
        .map((Language e) => e.locale.languageCode)
        .toList(growable: false);
  }

  static Future<Language> getLanguage() async {
    return languages.first;
  }

  static Language getLanguageFromCode(String code) {
    Language selected = languages.first;
    for (final Language language in languages) {
      if (language.locale.languageCode == code) selected = language;
    }
    return selected;
  }

  static Language? findFromLocale(Locale locale) {
    for (final Language language in languages) {
      if (language.locale.languageCode == locale.languageCode) return language;
    }
    return null;
  }

  Language clone() => Language(locale, languageName, supportRTL);

  @override
  String toString() =>
      'Language{locale: $locale, isRTL: $supportRTL, languageName: $languageName}';
}
