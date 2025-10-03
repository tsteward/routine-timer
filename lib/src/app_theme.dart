import 'package:flutter/material.dart';

/// Centralized app theme and color definitions for Routine Timer.
class AppTheme {
  AppTheme._();

  // Brand colors
  static const Color green = Color(0xFF22C55E); // emerald 500
  static const Color greenDark = Color(0xFF16A34A); // emerald 600
  static const Color red = Color(0xFFEF4444); // red 500

  static ThemeData get theme {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: Brightness.light,
      ).copyWith(
        primary: green,
        secondary: greenDark,
        error: red,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: base.textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        brightness: Brightness.dark,
      ).copyWith(error: red),
      useMaterial3: true,
    );
    return base;
  }
}


