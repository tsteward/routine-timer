import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/schedule_status.dart';

void main() {
  group('ScheduleStatus', () {
    test('should create schedule status with all properties', () {
      final estimatedTime = DateTime(2025, 1, 1, 12, 0);

      final status = ScheduleStatus(
        type: ScheduleStatusType.ahead,
        minutesDifference: 5,
        estimatedCompletionTime: estimatedTime,
        totalExpectedDuration: 3600,
        totalActualDuration: 3300,
        totalRemainingDuration: 300,
      );

      expect(status.type, equals(ScheduleStatusType.ahead));
      expect(status.minutesDifference, equals(5));
      expect(status.estimatedCompletionTime, equals(estimatedTime));
      expect(status.totalExpectedDuration, equals(3600));
      expect(status.totalActualDuration, equals(3300));
      expect(status.totalRemainingDuration, equals(300));
    });

    test('should create copy with updated properties', () {
      final originalTime = DateTime(2025, 1, 1, 12, 0);
      final newTime = DateTime(2025, 1, 1, 13, 0);

      final original = ScheduleStatus(
        type: ScheduleStatusType.onTrack,
        minutesDifference: 0,
        estimatedCompletionTime: originalTime,
        totalExpectedDuration: 3600,
        totalActualDuration: 3600,
        totalRemainingDuration: 0,
      );

      final updated = original.copyWith(
        type: ScheduleStatusType.behind,
        minutesDifference: 3,
        estimatedCompletionTime: newTime,
      );

      expect(updated.type, equals(ScheduleStatusType.behind));
      expect(updated.minutesDifference, equals(3));
      expect(updated.estimatedCompletionTime, equals(newTime));
      expect(updated.totalExpectedDuration, equals(3600)); // unchanged
      expect(updated.totalActualDuration, equals(3600)); // unchanged
      expect(updated.totalRemainingDuration, equals(0)); // unchanged
    });

    test('should serialize to and from Map', () {
      final estimatedTime = DateTime(2025, 1, 1, 12, 0);

      final original = ScheduleStatus(
        type: ScheduleStatusType.behind,
        minutesDifference: 10,
        estimatedCompletionTime: estimatedTime,
        totalExpectedDuration: 7200,
        totalActualDuration: 7800,
        totalRemainingDuration: 1200,
      );

      final map = original.toMap();
      final restored = ScheduleStatus.fromMap(map);

      expect(restored.type, equals(original.type));
      expect(restored.minutesDifference, equals(original.minutesDifference));
      expect(
        restored.estimatedCompletionTime,
        equals(original.estimatedCompletionTime),
      );
      expect(
        restored.totalExpectedDuration,
        equals(original.totalExpectedDuration),
      );
      expect(
        restored.totalActualDuration,
        equals(original.totalActualDuration),
      );
      expect(
        restored.totalRemainingDuration,
        equals(original.totalRemainingDuration),
      );
    });

    test('should serialize to and from JSON', () {
      final estimatedTime = DateTime(2025, 1, 1, 12, 0);

      final original = ScheduleStatus(
        type: ScheduleStatusType.ahead,
        minutesDifference: 2,
        estimatedCompletionTime: estimatedTime,
        totalExpectedDuration: 1800,
        totalActualDuration: 1680,
        totalRemainingDuration: 120,
      );

      final json = original.toJson();
      final restored = ScheduleStatus.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.minutesDifference, equals(original.minutesDifference));
      expect(
        restored.estimatedCompletionTime,
        equals(original.estimatedCompletionTime),
      );
      expect(
        restored.totalExpectedDuration,
        equals(original.totalExpectedDuration),
      );
      expect(
        restored.totalActualDuration,
        equals(original.totalActualDuration),
      );
      expect(
        restored.totalRemainingDuration,
        equals(original.totalRemainingDuration),
      );
    });

    test('should handle invalid ScheduleStatusType gracefully in fromMap', () {
      final map = {
        'type': 'invalid_type',
        'minutesDifference': 0,
        'estimatedCompletionTime': DateTime.now().millisecondsSinceEpoch,
        'totalExpectedDuration': 0,
        'totalActualDuration': 0,
        'totalRemainingDuration': 0,
      };

      final status = ScheduleStatus.fromMap(map);

      expect(status.type, equals(ScheduleStatusType.onTrack));
    });
  });

  group('ScheduleStatusType', () {
    test('should have correct enum values', () {
      expect(ScheduleStatusType.values.length, equals(3));
      expect(ScheduleStatusType.values, contains(ScheduleStatusType.ahead));
      expect(ScheduleStatusType.values, contains(ScheduleStatusType.behind));
      expect(ScheduleStatusType.values, contains(ScheduleStatusType.onTrack));
    });

    test('should have correct string names', () {
      expect(ScheduleStatusType.ahead.name, equals('ahead'));
      expect(ScheduleStatusType.behind.name, equals('behind'));
      expect(ScheduleStatusType.onTrack.name, equals('onTrack'));
    });
  });
}
