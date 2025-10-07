import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
  group('RoutineSettingsModel', () {
    test('creates instance with required parameters', () {
      const settings = RoutineSettingsModel(
        startTime: 1000,
        defaultBreakDuration: 300,
      );
      expect(settings.startTime, 1000);
      expect(settings.breaksEnabledByDefault, true); // default value
      expect(settings.defaultBreakDuration, 300);
    });

    test('creates instance with all parameters', () {
      const settings = RoutineSettingsModel(
        startTime: 2000,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 180,
      );
      expect(settings.startTime, 2000);
      expect(settings.breaksEnabledByDefault, false);
      expect(settings.defaultBreakDuration, 180);
    });

    test('toMap/fromMap roundtrip', () {
      final settings = RoutineSettingsModel(
        startTime: DateTime(2024, 1, 1, 8, 0).millisecondsSinceEpoch,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 120,
      );
      final map = settings.toMap();
      final decoded = RoutineSettingsModel.fromMap(map);
      expect(decoded.startTime, settings.startTime);
      expect(decoded.breaksEnabledByDefault, false);
      expect(decoded.defaultBreakDuration, 120);
    });

    test('fromMap uses default values when optional fields are missing', () {
      final map = {
        'startTime': 5000,
        'defaultBreakDuration': 200,
      };
      final settings = RoutineSettingsModel.fromMap(map);
      expect(settings.startTime, 5000);
      expect(settings.breaksEnabledByDefault, true);
      expect(settings.defaultBreakDuration, 200);
    });

    test('toJson creates valid JSON string', () {
      const settings = RoutineSettingsModel(
        startTime: 12345,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 240,
      );
      final json = settings.toJson();
      expect(json, isA<String>());
      expect(json, contains('12345'));
      expect(json, contains('false'));
      expect(json, contains('240'));
    });

    test('fromJson parses valid JSON string', () {
      const jsonString = 
          '{"startTime":67890,"breaksEnabledByDefault":true,"defaultBreakDuration":360}';
      final settings = RoutineSettingsModel.fromJson(jsonString);
      expect(settings.startTime, 67890);
      expect(settings.breaksEnabledByDefault, true);
      expect(settings.defaultBreakDuration, 360);
    });

    test('toJson/fromJson roundtrip', () {
      const original = RoutineSettingsModel(
        startTime: 99999,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 420,
      );
      final json = original.toJson();
      final decoded = RoutineSettingsModel.fromJson(json);
      expect(decoded.startTime, original.startTime);
      expect(decoded.breaksEnabledByDefault, original.breaksEnabledByDefault);
      expect(decoded.defaultBreakDuration, original.defaultBreakDuration);
    });

    test('copyWith updates fields', () {
      final settings = RoutineSettingsModel(
        startTime: 1,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 60,
      );
      final updated = settings.copyWith(
        defaultBreakDuration: 90,
        breaksEnabledByDefault: false,
      );
      expect(updated.defaultBreakDuration, 90);
      expect(updated.breaksEnabledByDefault, false);
      expect(updated.startTime, 1);
    });

    test('copyWith updates only specified fields', () {
      const settings = RoutineSettingsModel(
        startTime: 10000,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 300,
      );
      final updated = settings.copyWith(startTime: 20000);
      expect(updated.startTime, 20000); // changed
      expect(updated.breaksEnabledByDefault, true); // unchanged
      expect(updated.defaultBreakDuration, 300); // unchanged
    });

    test('copyWith with no parameters returns copy with same values', () {
      const settings = RoutineSettingsModel(
        startTime: 30000,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 150,
      );
      final updated = settings.copyWith();
      expect(updated.startTime, settings.startTime);
      expect(updated.breaksEnabledByDefault, settings.breaksEnabledByDefault);
      expect(updated.defaultBreakDuration, settings.defaultBreakDuration);
    });
  });
}
