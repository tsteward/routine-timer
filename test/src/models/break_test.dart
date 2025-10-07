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
      const br = BreakModel(duration: 180, isEnabled: true, isCustomized: true);
      final json = br.toJson();
      final decoded = BreakModel.fromJson(json);
      expect(decoded.duration, 180);
      expect(decoded.isEnabled, true);
      expect(decoded.isCustomized, true);
    });

    test('toJson produces valid JSON string', () {
      const br = BreakModel(duration: 300, isEnabled: false);
      final json = br.toJson();
      expect(json, isA<String>());
      expect(json.contains('duration'), true);
      expect(json.contains('isEnabled'), true);
    });

    test('fromJson handles JSON string correctly', () {
      const jsonString = '{"duration":240,"isEnabled":true,"isCustomized":false}';
      final br = BreakModel.fromJson(jsonString);
      expect(br.duration, 240);
      expect(br.isEnabled, true);
      expect(br.isCustomized, false);
    });

    test('fromMap defaults isEnabled to true when missing', () {
      final map = {'duration': 120};
      final br = BreakModel.fromMap(map);
      expect(br.duration, 120);
      expect(br.isEnabled, true);
    });

    test('fromMap defaults isCustomized to false when missing', () {
      final map = {'duration': 120, 'isEnabled': true};
      final br = BreakModel.fromMap(map);
      expect(br.duration, 120);
      expect(br.isEnabled, true);
      expect(br.isCustomized, false);
    });

    test('copyWith preserves fields when not specified', () {
      const br = BreakModel(
        duration: 60,
        isEnabled: true,
        isCustomized: true,
      );
      final updated = br.copyWith(duration: 90);
      expect(updated.duration, 90);
      expect(updated.isEnabled, true);
      expect(updated.isCustomized, true);
    });

    test('copyWith can update isCustomized field', () {
      const br = BreakModel(duration: 60, isEnabled: true);
      final updated = br.copyWith(isCustomized: true);
      expect(updated.duration, 60);
      expect(updated.isEnabled, true);
      expect(updated.isCustomized, true);
    });

    test('toMap includes all fields', () {
      const br = BreakModel(
        duration: 300,
        isEnabled: false,
        isCustomized: true,
      );
      final map = br.toMap();
      expect(map['duration'], 300);
      expect(map['isEnabled'], false);
      expect(map['isCustomized'], true);
    });

    test('default constructor sets isEnabled to true', () {
      const br = BreakModel(duration: 120);
      expect(br.isEnabled, true);
    });

    test('default constructor sets isCustomized to false', () {
      const br = BreakModel(duration: 120);
      expect(br.isCustomized, false);
    });
  });
}
