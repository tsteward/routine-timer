import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_completion.dart';

void main() {
  group('RoutineCompletion', () {
    final testDateTime = DateTime(2025, 10, 14, 10, 30, 0);
    final testStartTime = DateTime(2025, 10, 14, 6, 0, 0);

    group('constructor', () {
      test('creates instance with required fields', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 120,
          routineStartTime: testStartTime,
        );

        expect(completion.completedAt, testDateTime);
        expect(completion.totalTimeSpent, 3600);
        expect(completion.tasksCompleted, 5);
        expect(completion.scheduleVariance, 120);
        expect(completion.routineStartTime, testStartTime);
        expect(completion.completionId, isNull);
      });

      test('creates instance with optional completionId', () {
        final completion = RoutineCompletion(
          completionId: 'test-id-123',
          completedAt: testDateTime,
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 120,
          routineStartTime: testStartTime,
        );

        expect(completion.completionId, 'test-id-123');
      });
    });

    group('statusText', () {
      test('returns "On track" when variance is zero', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 0,
          routineStartTime: testStartTime,
        );

        expect(completion.statusText, 'On track');
      });

      test(
        'returns "Ahead by X min" when variance is positive (minutes only)',
        () {
          final completion = RoutineCompletion(
            completedAt: testDateTime,
            totalTimeSpent: 3600,
            tasksCompleted: 5,
            scheduleVariance: 120, // 2 minutes
            routineStartTime: testStartTime,
          );

          expect(completion.statusText, 'Ahead by 2 min ');
        },
      );

      test(
        'returns "Ahead by X min Y sec" when variance is positive (minutes and seconds)',
        () {
          final completion = RoutineCompletion(
            completedAt: testDateTime,
            totalTimeSpent: 3600,
            tasksCompleted: 5,
            scheduleVariance: 125, // 2 min 5 sec
            routineStartTime: testStartTime,
          );

          expect(completion.statusText, 'Ahead by 2 min 5 sec');
        },
      );

      test(
        'returns "Ahead by X sec" when variance is positive (seconds only)',
        () {
          final completion = RoutineCompletion(
            completedAt: testDateTime,
            totalTimeSpent: 3600,
            tasksCompleted: 5,
            scheduleVariance: 45, // 45 seconds
            routineStartTime: testStartTime,
          );

          expect(completion.statusText, 'Ahead by 45 sec');
        },
      );

      test(
        'returns "Behind by X min" when variance is negative (minutes only)',
        () {
          final completion = RoutineCompletion(
            completedAt: testDateTime,
            totalTimeSpent: 3600,
            tasksCompleted: 5,
            scheduleVariance: -120, // 2 minutes behind
            routineStartTime: testStartTime,
          );

          expect(completion.statusText, 'Behind by 2 min ');
        },
      );

      test(
        'returns "Behind by X min Y sec" when variance is negative (minutes and seconds)',
        () {
          final completion = RoutineCompletion(
            completedAt: testDateTime,
            totalTimeSpent: 3600,
            tasksCompleted: 5,
            scheduleVariance: -125, // 2 min 5 sec behind
            routineStartTime: testStartTime,
          );

          expect(completion.statusText, 'Behind by 2 min 5 sec');
        },
      );

      test(
        'returns "Behind by X sec" when variance is negative (seconds only)',
        () {
          final completion = RoutineCompletion(
            completedAt: testDateTime,
            totalTimeSpent: 3600,
            tasksCompleted: 5,
            scheduleVariance: -45, // 45 seconds behind
            routineStartTime: testStartTime,
          );

          expect(completion.statusText, 'Behind by 45 sec');
        },
      );
    });

    group('formattedTotalTime', () {
      test('formats time correctly for hours and minutes', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 3661, // 1 hour, 1 minute, 1 second
          tasksCompleted: 5,
          scheduleVariance: 0,
          routineStartTime: testStartTime,
        );

        expect(completion.formattedTotalTime, '61:01');
      });

      test('formats time correctly for minutes and seconds', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 125, // 2 minutes, 5 seconds
          tasksCompleted: 5,
          scheduleVariance: 0,
          routineStartTime: testStartTime,
        );

        expect(completion.formattedTotalTime, '02:05');
      });

      test('formats time correctly for seconds only', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 45, // 45 seconds
          tasksCompleted: 5,
          scheduleVariance: 0,
          routineStartTime: testStartTime,
        );

        expect(completion.formattedTotalTime, '00:45');
      });

      test('pads single digits with zeros', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 65, // 1 minute, 5 seconds
          tasksCompleted: 5,
          scheduleVariance: 0,
          routineStartTime: testStartTime,
        );

        expect(completion.formattedTotalTime, '01:05');
      });
    });

    group('copyWith', () {
      test('returns new instance with updated fields', () {
        final original = RoutineCompletion(
          completionId: 'original-id',
          completedAt: testDateTime,
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 120,
          routineStartTime: testStartTime,
        );

        final newDateTime = DateTime(2025, 10, 15, 10, 30, 0);
        final copied = original.copyWith(
          completionId: 'new-id',
          completedAt: newDateTime,
          totalTimeSpent: 7200,
        );

        expect(copied.completionId, 'new-id');
        expect(copied.completedAt, newDateTime);
        expect(copied.totalTimeSpent, 7200);
        expect(copied.tasksCompleted, 5); // Unchanged
        expect(copied.scheduleVariance, 120); // Unchanged
      });

      test(
        'returns new instance with no changes when no parameters provided',
        () {
          final original = RoutineCompletion(
            completionId: 'original-id',
            completedAt: testDateTime,
            totalTimeSpent: 3600,
            tasksCompleted: 5,
            scheduleVariance: 120,
            routineStartTime: testStartTime,
          );

          final copied = original.copyWith();

          expect(copied.completionId, original.completionId);
          expect(copied.completedAt, original.completedAt);
          expect(copied.totalTimeSpent, original.totalTimeSpent);
          expect(copied.tasksCompleted, original.tasksCompleted);
          expect(copied.scheduleVariance, original.scheduleVariance);
        },
      );
    });

    group('serialization', () {
      test('toMap converts to map correctly', () {
        final completion = RoutineCompletion(
          completionId: 'test-id',
          completedAt: testDateTime,
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 120,
          routineStartTime: testStartTime,
        );

        final map = completion.toMap();

        expect(map['completionId'], 'test-id');
        expect(map['completedAt'], testDateTime.millisecondsSinceEpoch);
        expect(map['totalTimeSpent'], 3600);
        expect(map['tasksCompleted'], 5);
        expect(map['scheduleVariance'], 120);
        expect(map['routineStartTime'], testStartTime.millisecondsSinceEpoch);
      });

      test('fromMap creates instance from map correctly', () {
        final map = {
          'completionId': 'test-id',
          'completedAt': testDateTime.millisecondsSinceEpoch,
          'totalTimeSpent': 3600,
          'tasksCompleted': 5,
          'scheduleVariance': 120,
          'routineStartTime': testStartTime.millisecondsSinceEpoch,
        };

        final completion = RoutineCompletion.fromMap(map);

        expect(completion.completionId, 'test-id');
        expect(completion.completedAt, testDateTime);
        expect(completion.totalTimeSpent, 3600);
        expect(completion.tasksCompleted, 5);
        expect(completion.scheduleVariance, 120);
        expect(completion.routineStartTime, testStartTime);
      });

      test('fromMap handles null completionId', () {
        final map = {
          'completionId': null,
          'completedAt': testDateTime.millisecondsSinceEpoch,
          'totalTimeSpent': 3600,
          'tasksCompleted': 5,
          'scheduleVariance': 120,
          'routineStartTime': testStartTime.millisecondsSinceEpoch,
        };

        final completion = RoutineCompletion.fromMap(map);

        expect(completion.completionId, isNull);
      });

      test('toJson and fromJson work correctly', () {
        final original = RoutineCompletion(
          completionId: 'test-id',
          completedAt: testDateTime,
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 120,
          routineStartTime: testStartTime,
        );

        final json = original.toJson();
        final deserialized = RoutineCompletion.fromJson(json);

        expect(deserialized.completionId, original.completionId);
        expect(deserialized.completedAt, original.completedAt);
        expect(deserialized.totalTimeSpent, original.totalTimeSpent);
        expect(deserialized.tasksCompleted, original.tasksCompleted);
        expect(deserialized.scheduleVariance, original.scheduleVariance);
        expect(deserialized.routineStartTime, original.routineStartTime);
      });
    });

    group('edge cases', () {
      test('handles zero total time', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 0,
          tasksCompleted: 0,
          scheduleVariance: 0,
          routineStartTime: testStartTime,
        );

        expect(completion.formattedTotalTime, '00:00');
      });

      test('handles large total time', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 86399, // 23:59:59
          tasksCompleted: 100,
          scheduleVariance: 0,
          routineStartTime: testStartTime,
        );

        expect(completion.formattedTotalTime, '1439:59');
      });

      test('handles large positive schedule variance', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 3661, // 1 hour 1 min 1 sec ahead
          routineStartTime: testStartTime,
        );

        expect(completion.statusText, 'Ahead by 61 min 1 sec');
      });

      test('handles large negative schedule variance', () {
        final completion = RoutineCompletion(
          completedAt: testDateTime,
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: -3661, // 1 hour 1 min 1 sec behind
          routineStartTime: testStartTime,
        );

        expect(completion.statusText, 'Behind by 61 min 1 sec');
      });
    });
  });
}
