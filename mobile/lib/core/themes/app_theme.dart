import 'package:flutter/material.dart';

/// Material 3 theme used across the citizen app.
class AppTheme {
  AppTheme._();

  static const seed = Color(0xFF1B5E20); // civic green

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return ThemeData(useMaterial3: true, colorScheme: scheme);
  }
}
