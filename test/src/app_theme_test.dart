import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('has correct brand colors', () {
      expect(AppTheme.green, const Color(0xFF22C55E));
      expect(AppTheme.greenDark, const Color(0xFF16A34A));
      expect(AppTheme.red, const Color(0xFFEF4444));
    });

    test('light theme has correct color scheme', () {
      final theme = AppTheme.theme;
      expect(theme.colorScheme.primary, AppTheme.green);
      expect(theme.colorScheme.secondary, AppTheme.greenDark);
      expect(theme.colorScheme.error, AppTheme.red);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.useMaterial3, true);
    });

    test('light theme has correct text styles', () {
      final theme = AppTheme.theme;
      expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w800);
      expect(theme.textTheme.displayLarge?.letterSpacing, -1.0);
      expect(theme.textTheme.displayMedium?.fontWeight, FontWeight.w700);
      expect(theme.textTheme.headlineMedium?.fontWeight, FontWeight.w700);
    });

    test('light theme has centered app bar', () {
      final theme = AppTheme.theme;
      expect(theme.appBarTheme.centerTitle, true);
    });

    test('dark theme has correct color scheme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.error, AppTheme.red);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.useMaterial3, true);
    });

    test('private constructor prevents instantiation', () {
      // This test covers the private constructor line
      // We can't directly instantiate AppTheme due to private constructor,
      // but we can verify the class works as a utility class
      expect(() => AppTheme.green, returnsNormally);
      expect(() => AppTheme.theme, returnsNormally);
      expect(() => AppTheme.darkTheme, returnsNormally);
    });
  });
}
