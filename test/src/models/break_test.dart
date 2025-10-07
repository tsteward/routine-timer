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
  });
}
