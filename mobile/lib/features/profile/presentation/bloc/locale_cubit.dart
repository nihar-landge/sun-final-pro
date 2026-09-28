import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the app language (en / hi / mr).
class LocaleCubit extends Cubit<Locale> {
  static const _prefKey = 'app_locale';

  final SharedPreferences _prefs;

  LocaleCubit(this._prefs) : super(_load(_prefs));

  static Locale _load(SharedPreferences prefs) =>
      switch (prefs.getString(_prefKey)) {
        'hi' => const Locale('hi'),
        'mr' => const Locale('mr'),
        _ => const Locale('en'),
      };

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_prefKey, locale.languageCode);
    emit(locale);
  }
}

/// Languages offered in Profile; `nativeName` stays in its own script.
enum AppLanguage {
  english('English', Locale('en')),
  hindi('हिन्दी', Locale('hi')),
  marathi('मराठी', Locale('mr'));

  const AppLanguage(this.nativeName, this.locale);

  final String nativeName;
  final Locale locale;

  static AppLanguage forLocale(Locale locale) => values.firstWhere(
        (language) => language.locale.languageCode == locale.languageCode,
        orElse: () => english,
      );
}
