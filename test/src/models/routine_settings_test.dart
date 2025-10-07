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
        startTime: DateTime(2024, 6, 15, 7, 30).millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 180,
      );
      final json = settings.toJson();
      final decoded = RoutineSettingsModel.fromJson(json);
      expect(decoded.startTime, settings.startTime);
      expect(decoded.breaksEnabledByDefault, true);
      expect(decoded.defaultBreakDuration, 180);
    });

    test('fromMap handles default breaksEnabledByDefault value', () {
      final map = {'startTime': 1000, 'defaultBreakDuration': 60};
      final settings = RoutineSettingsModel.fromMap(map);
      expect(settings.breaksEnabledByDefault, true); // Should default to true
    });

    test('copyWith can update all fields', () {
      final settings = RoutineSettingsModel(
        startTime: 100,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 60,
      );
      final updated = settings.copyWith(
        startTime: 200,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );
      expect(updated.startTime, 200);
      expect(updated.breaksEnabledByDefault, true);
      expect(updated.defaultBreakDuration, 120);
    });
  });
}
