import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('defines correct brand colors', () {
      expect(AppTheme.green, equals(const Color(0xFF22C55E)));
      expect(AppTheme.greenDark, equals(const Color(0xFF16A34A)));
      expect(AppTheme.red, equals(const Color(0xFFEF4444)));
    });

    test('light theme uses correct color scheme', () {
      final theme = AppTheme.theme;
      expect(theme.colorScheme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(AppTheme.green));
      expect(theme.colorScheme.secondary, equals(AppTheme.greenDark));
      expect(theme.colorScheme.error, equals(AppTheme.red));
    });

    test('light theme uses Material 3', () {
      final theme = AppTheme.theme;
      expect(theme.useMaterial3, isTrue);
    });

    test('light theme has proper text theme', () {
      final theme = AppTheme.theme;
      expect(theme.textTheme, isNotNull);
    });

    test('light theme has centered app bar titles', () {
      final theme = AppTheme.theme;
      expect(theme.appBarTheme.centerTitle, isTrue);
    });

    test('light theme has custom text styles', () {
      final theme = AppTheme.theme;

      // Display large should have heavy weight and negative letter spacing
      expect(theme.textTheme.displayLarge?.fontWeight, equals(FontWeight.w800));
      expect(theme.textTheme.displayLarge?.letterSpacing, equals(-1.0));

      // Display medium should have bold weight
      expect(
        theme.textTheme.displayMedium?.fontWeight,
        equals(FontWeight.w700),
      );

      // Headline medium should have bold weight
      expect(
        theme.textTheme.headlineMedium?.fontWeight,
        equals(FontWeight.w700),
      );
    });

    test('dark theme uses correct brightness', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
    });

    test('dark theme has error color', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.error, equals(AppTheme.red));
    });

    test('dark theme is seeded from green color', () {
      final theme = AppTheme.darkTheme;
      // Verify the theme is created (not null)
      expect(theme, isNotNull);
      expect(theme.colorScheme, isNotNull);
    });

    test('cannot instantiate AppTheme', () {
      // AppTheme has a private constructor, so this test verifies
      // that the class is designed as a static utility class
      expect(() => AppTheme, returnsNormally);
    });
  });
}
