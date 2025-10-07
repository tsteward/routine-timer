import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
  group('RoutineSettingsModel', () {
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

    test('toJson/fromJson roundtrip', () {
      final settings = RoutineSettingsModel(
        startTime: 1234567890,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 300,
      );
      final json = settings.toJson();
      final decoded = RoutineSettingsModel.fromJson(json);
      expect(decoded.startTime, 1234567890);
      expect(decoded.breaksEnabledByDefault, true);
      expect(decoded.defaultBreakDuration, 300);
    });

    test('toJson produces valid JSON string', () {
      const settings = RoutineSettingsModel(
        startTime: 999999,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 180,
      );
      final json = settings.toJson();
      expect(json, isA<String>());
      expect(json.contains('startTime'), true);
      expect(json.contains('breaksEnabledByDefault'), true);
      expect(json.contains('defaultBreakDuration'), true);
    });

    test('fromJson handles JSON string correctly', () {
      const jsonString = '{"startTime":111111,"breaksEnabledByDefault":true,"defaultBreakDuration":240}';
      final settings = RoutineSettingsModel.fromJson(jsonString);
      expect(settings.startTime, 111111);
      expect(settings.breaksEnabledByDefault, true);
      expect(settings.defaultBreakDuration, 240);
    });

    test('fromMap defaults breaksEnabledByDefault to true when missing', () {
      final map = {
        'startTime': 123456,
        'defaultBreakDuration': 300,
      };
      final settings = RoutineSettingsModel.fromMap(map);
      expect(settings.startTime, 123456);
      expect(settings.breaksEnabledByDefault, true);
      expect(settings.defaultBreakDuration, 300);
    });

    test('copyWith preserves fields when not specified', () {
      const settings = RoutineSettingsModel(
        startTime: 555555,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 120,
      );
      final updated = settings.copyWith(startTime: 666666);
      expect(updated.startTime, 666666);
      expect(updated.breaksEnabledByDefault, false);
      expect(updated.defaultBreakDuration, 120);
    });

    test('copyWith can update all fields', () {
      const settings = RoutineSettingsModel(
        startTime: 111,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 60,
      );
      final updated = settings.copyWith(
        startTime: 222,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 90,
      );
      expect(updated.startTime, 222);
      expect(updated.breaksEnabledByDefault, false);
      expect(updated.defaultBreakDuration, 90);
    });

    test('toMap includes all fields', () {
      const settings = RoutineSettingsModel(
        startTime: 777777,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 360,
      );
      final map = settings.toMap();
      expect(map['startTime'], 777777);
      expect(map['breaksEnabledByDefault'], false);
      expect(map['defaultBreakDuration'], 360);
      expect(map.length, 3);
    });

    test('default constructor sets breaksEnabledByDefault to true', () {
      const settings = RoutineSettingsModel(
        startTime: 123,
        defaultBreakDuration: 300,
      );
      expect(settings.breaksEnabledByDefault, true);
    });
  });
}
