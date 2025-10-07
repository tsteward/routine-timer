import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';

void main() {
  group('BreakModel', () {
    test('creates instance with required parameters', () {
      const br = BreakModel(duration: 120);
      expect(br.duration, 120);
      expect(br.isEnabled, true); // default value
      expect(br.isCustomized, false); // default value
    });

    test('creates instance with all parameters', () {
      const br = BreakModel(
        duration: 180,
        isEnabled: false,
        isCustomized: true,
      );
      expect(br.duration, 180);
      expect(br.isEnabled, false);
      expect(br.isCustomized, true);
    });

    test('toMap/fromMap roundtrip', () {
      const br = BreakModel(duration: 120, isEnabled: false);
      final map = br.toMap();
      final decoded = BreakModel.fromMap(map);
      expect(decoded.duration, 120);
      expect(decoded.isEnabled, false);
    });

    test('toMap/fromMap roundtrip with isCustomized', () {
      const br = BreakModel(
        duration: 300,
        isEnabled: true,
        isCustomized: true,
      );
      final map = br.toMap();
      final decoded = BreakModel.fromMap(map);
      expect(decoded.duration, 300);
      expect(decoded.isEnabled, true);
      expect(decoded.isCustomized, true);
    });

    test('fromMap uses default values when fields are missing', () {
      final map = {'duration': 100};
      final br = BreakModel.fromMap(map);
      expect(br.duration, 100);
      expect(br.isEnabled, true);
      expect(br.isCustomized, false);
    });

    test('toJson creates valid JSON string', () {
      const br = BreakModel(duration: 150, isEnabled: false, isCustomized: true);
      final json = br.toJson();
      expect(json, isA<String>());
      expect(json, contains('150'));
      expect(json, contains('false'));
    });

    test('fromJson parses valid JSON string', () {
      const jsonString = '{"duration":200,"isEnabled":true,"isCustomized":false}';
      final br = BreakModel.fromJson(jsonString);
      expect(br.duration, 200);
      expect(br.isEnabled, true);
      expect(br.isCustomized, false);
    });

    test('toJson/fromJson roundtrip', () {
      const original = BreakModel(
        duration: 240,
        isEnabled: false,
        isCustomized: true,
      );
      final json = original.toJson();
      final decoded = BreakModel.fromJson(json);
      expect(decoded.duration, original.duration);
      expect(decoded.isEnabled, original.isEnabled);
      expect(decoded.isCustomized, original.isCustomized);
    });

    test('copyWith toggles fields', () {
      const br = BreakModel(duration: 60, isEnabled: true);
      final updated = br.copyWith(isEnabled: false, duration: 90);
      expect(updated.duration, 90);
      expect(updated.isEnabled, false);
    });

    test('copyWith updates only specified fields', () {
      const br = BreakModel(
        duration: 100,
        isEnabled: true,
        isCustomized: false,
      );
      final updated = br.copyWith(isCustomized: true);
      expect(updated.duration, 100); // unchanged
      expect(updated.isEnabled, true); // unchanged
      expect(updated.isCustomized, true); // changed
    });

    test('copyWith with no parameters returns copy with same values', () {
      const br = BreakModel(
        duration: 180,
        isEnabled: false,
        isCustomized: true,
      );
      final updated = br.copyWith();
      expect(updated.duration, br.duration);
      expect(updated.isEnabled, br.isEnabled);
      expect(updated.isCustomized, br.isCustomized);
    });
  });
}
