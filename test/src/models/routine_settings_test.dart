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
        startTime: DateTime(2024, 3, 15, 9, 30).millisecondsSinceEpoch,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 240,
      );
      final json = settings.toJson();
      expect(json, isA<String>());

      final decoded = RoutineSettingsModel.fromJson(json);
      expect(decoded.startTime, settings.startTime);
      expect(decoded.breaksEnabledByDefault, false);
      expect(decoded.defaultBreakDuration, 240);
    });

    test('copyWith can update individual fields', () {
      final settings = RoutineSettingsModel(
        startTime: 1000,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 60,
      );

      final withStartTime = settings.copyWith(startTime: 2000);
      expect(withStartTime.startTime, 2000);
      expect(withStartTime.breaksEnabledByDefault, true);
      expect(withStartTime.defaultBreakDuration, 60);

      final withBreaksEnabled = settings.copyWith(
        breaksEnabledByDefault: false,
      );
      expect(withBreaksEnabled.startTime, 1000);
      expect(withBreaksEnabled.breaksEnabledByDefault, false);

      final withBreakDuration = settings.copyWith(defaultBreakDuration: 90);
      expect(withBreakDuration.defaultBreakDuration, 90);
    });
  });
}
