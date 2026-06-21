import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/profile_repository.dart';

class AppLocaleController extends ValueNotifier<Locale?> {
  AppLocaleController() : super(null);

  static const _languageKey = 'preferred_language';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_languageKey);
    if (languageCode == null || languageCode.isEmpty) {
      value = null;
      return;
    }

    value = Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, languageCode);
    value = Locale(languageCode);
    await ProfileRepository().updatePreferredLanguage(languageCode);
  }
}

final appLocaleController = AppLocaleController();
