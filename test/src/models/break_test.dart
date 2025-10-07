import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';

void main() {
  group('BreakModel', () {
    test('toMap/fromMap roundtrip', () {
      const br = BreakModel(duration: 120, isEnabled: false);
      final map = br.toMap();
      final decoded = BreakModel.fromMap(map);
      expect(decoded.duration, 120);
      expect(decoded.isEnabled, false);
    });

    test('copyWith toggles fields', () {
      const br = BreakModel(duration: 60, isEnabled: true);
      final updated = br.copyWith(isEnabled: false, duration: 90);
      expect(updated.duration, 90);
      expect(updated.isEnabled, false);
    });

    test('toJson/fromJson roundtrip', () {
      const br = BreakModel(duration: 180, isEnabled: false);
      final json = br.toJson();
      final decoded = BreakModel.fromJson(json);
      expect(decoded.duration, 180);
      expect(decoded.isEnabled, false);
    });

    test('copyWith preserves unchanged fields', () {
      const br = BreakModel(duration: 120, isEnabled: true);
      final updated = br.copyWith(duration: 150);
      expect(updated.duration, 150);
      expect(updated.isEnabled, true); // Should remain unchanged
    });

    test('fromMap handles default isEnabled value', () {
      final map = {'duration': 90};
      final br = BreakModel.fromMap(map);
      expect(br.duration, 90);
      expect(br.isEnabled, true); // Should default to true
    });
  });
}
