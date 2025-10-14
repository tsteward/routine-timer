import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_completion.dart';

void main() {
  group('RoutineCompletionData', () {
    test('creates instance with required fields', () {
      final completion = RoutineCompletionData(
        completedAt: 1000000,
        totalDurationSeconds: 3600,
        tasksCompleted: 5,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700,
        routineName: 'Morning Routine',
      );

      expect(completion.completedAt, 1000000);
      expect(completion.totalDurationSeconds, 3600);
      expect(completion.tasksCompleted, 5);
      expect(completion.totalEstimatedDuration, 3000);
      expect(completion.totalActualDuration, 2700);
      expect(completion.routineName, 'Morning Routine');
    });

    test('calculates time difference correctly when ahead', () {
      final completion = RoutineCompletionData(
        completedAt: 1000000,
        totalDurationSeconds: 3600,
        tasksCompleted: 5,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700, // 300 seconds ahead
        routineName: 'Morning Routine',
      );

      expect(completion.timeDifference, -300);
      expect(completion.isAheadOfSchedule, true);
    });

    test('calculates time difference correctly when behind', () {
      final completion = RoutineCompletionData(
        completedAt: 1000000,
        totalDurationSeconds: 3600,
        tasksCompleted: 5,
        totalEstimatedDuration: 3000,
        totalActualDuration: 3300, // 300 seconds behind
        routineName: 'Morning Routine',
      );

      expect(completion.timeDifference, 300);
      expect(completion.isAheadOfSchedule, false);
    });

    test('calculates time difference correctly when exactly on time', () {
      final completion = RoutineCompletionData(
        completedAt: 1000000,
        totalDurationSeconds: 3600,
        tasksCompleted: 5,
        totalEstimatedDuration: 3000,
        totalActualDuration: 3000, // Exactly on time
        routineName: 'Morning Routine',
      );

      expect(completion.timeDifference, 0);
      expect(completion.isAheadOfSchedule, false);
    });

    test('serializes to map correctly', () {
      final completion = RoutineCompletionData(
        completedAt: 1000000,
        totalDurationSeconds: 3600,
        tasksCompleted: 5,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700,
        routineName: 'Morning Routine',
      );

      final map = completion.toMap();

      expect(map['completedAt'], 1000000);
      expect(map['totalDurationSeconds'], 3600);
      expect(map['tasksCompleted'], 5);
      expect(map['totalEstimatedDuration'], 3000);
      expect(map['totalActualDuration'], 2700);
      expect(map['routineName'], 'Morning Routine');
    });

    test('deserializes from map correctly', () {
      final map = {
        'completedAt': 1000000,
        'totalDurationSeconds': 3600,
        'tasksCompleted': 5,
        'totalEstimatedDuration': 3000,
        'totalActualDuration': 2700,
        'routineName': 'Morning Routine',
      };

      final completion = RoutineCompletionData.fromMap(map);

      expect(completion.completedAt, 1000000);
      expect(completion.totalDurationSeconds, 3600);
      expect(completion.tasksCompleted, 5);
      expect(completion.totalEstimatedDuration, 3000);
      expect(completion.totalActualDuration, 2700);
      expect(completion.routineName, 'Morning Routine');
    });

    test('serializes to JSON correctly', () {
      final completion = RoutineCompletionData(
        completedAt: 1000000,
        totalDurationSeconds: 3600,
        tasksCompleted: 5,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700,
        routineName: 'Morning Routine',
      );

      final json = completion.toJson();
      expect(json, isA<String>());
      expect(json.contains('1000000'), true);
      expect(json.contains('Morning Routine'), true);
    });

    test('deserializes from JSON correctly', () {
      const json =
          '{"completedAt":1000000,"totalDurationSeconds":3600,"tasksCompleted":5,'
          '"totalEstimatedDuration":3000,"totalActualDuration":2700,'
          '"routineName":"Morning Routine"}';

      final completion = RoutineCompletionData.fromJson(json);

      expect(completion.completedAt, 1000000);
      expect(completion.totalDurationSeconds, 3600);
      expect(completion.tasksCompleted, 5);
      expect(completion.totalEstimatedDuration, 3000);
      expect(completion.totalActualDuration, 2700);
      expect(completion.routineName, 'Morning Routine');
    });

    test('round-trip serialization preserves data', () {
      final original = RoutineCompletionData(
        completedAt: 1234567890,
        totalDurationSeconds: 7200,
        tasksCompleted: 10,
        totalEstimatedDuration: 8000,
        totalActualDuration: 7500,
        routineName: 'Evening Routine',
      );

      final json = original.toJson();
      final deserialized = RoutineCompletionData.fromJson(json);

      expect(deserialized.completedAt, original.completedAt);
      expect(deserialized.totalDurationSeconds, original.totalDurationSeconds);
      expect(deserialized.tasksCompleted, original.tasksCompleted);
      expect(
        deserialized.totalEstimatedDuration,
        original.totalEstimatedDuration,
      );
      expect(deserialized.totalActualDuration, original.totalActualDuration);
      expect(deserialized.routineName, original.routineName);
    });

    test('handles zero values correctly', () {
      final completion = RoutineCompletionData(
        completedAt: 0,
        totalDurationSeconds: 0,
        tasksCompleted: 0,
        totalEstimatedDuration: 0,
        totalActualDuration: 0,
        routineName: '',
      );

      expect(completion.timeDifference, 0);
      expect(completion.isAheadOfSchedule, false);
    });

    test('handles large values correctly', () {
      final completion = RoutineCompletionData(
        completedAt: 9999999999,
        totalDurationSeconds: 86400, // 24 hours
        tasksCompleted: 100,
        totalEstimatedDuration: 90000,
        totalActualDuration: 86400,
        routineName: 'Super Long Routine',
      );

      expect(completion.timeDifference, -3600); // 1 hour ahead
      expect(completion.isAheadOfSchedule, true);
    });
  });
}
