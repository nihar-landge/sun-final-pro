import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the app theme mode (system / light / dark).
class ThemeCubit extends Cubit<ThemeMode> {
  static const _prefKey = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeCubit(this._prefs) : super(_load(_prefs));

  static ThemeMode _load(SharedPreferences prefs) =>
      switch (prefs.getString(_prefKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setMode(ThemeMode mode) async {
    await _prefs.setString(_prefKey, mode.name);
    emit(mode);
  }
}
