import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_completion.dart';

void main() {
  group('RoutineCompletion', () {
    test('creates instance with all required fields', () {
      final completion = RoutineCompletion(
        completedAt: DateTime(2025, 1, 1, 8, 0),
        totalTimeSpent: 3000,
        tasksCompleted: 4,
        totalTasks: 4,
        scheduleVariance: -120,
        taskCompletions: const [],
      );

      expect(completion.completedAt, DateTime(2025, 1, 1, 8, 0));
      expect(completion.totalTimeSpent, 3000);
      expect(completion.tasksCompleted, 4);
      expect(completion.totalTasks, 4);
      expect(completion.scheduleVariance, -120);
      expect(completion.taskCompletions, isEmpty);
    });

    test('isFullyCompleted returns true when all tasks completed', () {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3000,
        tasksCompleted: 4,
        totalTasks: 4,
        scheduleVariance: 0,
        taskCompletions: const [],
      );

      expect(completion.isFullyCompleted, isTrue);
    });

    test('isFullyCompleted returns false when not all tasks completed', () {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3000,
        tasksCompleted: 3,
        totalTasks: 4,
        scheduleVariance: 0,
        taskCompletions: const [],
      );

      expect(completion.isFullyCompleted, isFalse);
    });

    test('scheduleStatus returns correct message when on schedule', () {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3000,
        tasksCompleted: 4,
        totalTasks: 4,
        scheduleVariance: 0,
        taskCompletions: const [],
      );

      expect(completion.scheduleStatus, 'On schedule');
    });

    test('scheduleStatus returns correct message when ahead', () {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3000,
        tasksCompleted: 4,
        totalTasks: 4,
        scheduleVariance: -125,
        taskCompletions: const [],
      );

      expect(completion.scheduleStatus, 'Ahead by 2 min 5s');
    });

    test(
      'scheduleStatus returns correct message when ahead by seconds only',
      () {
        final completion = RoutineCompletion(
          completedAt: DateTime.now(),
          totalTimeSpent: 3000,
          tasksCompleted: 4,
          totalTasks: 4,
          scheduleVariance: -45,
          taskCompletions: const [],
        );

        expect(completion.scheduleStatus, 'Ahead by 45s');
      },
    );

    test('scheduleStatus returns correct message when behind', () {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3000,
        tasksCompleted: 4,
        totalTasks: 4,
        scheduleVariance: 185,
        taskCompletions: const [],
      );

      expect(completion.scheduleStatus, 'Behind by 3 min 5s');
    });

    test(
      'scheduleStatus returns correct message when behind by seconds only',
      () {
        final completion = RoutineCompletion(
          completedAt: DateTime.now(),
          totalTimeSpent: 3000,
          tasksCompleted: 4,
          totalTasks: 4,
          scheduleVariance: 30,
          taskCompletions: const [],
        );

        expect(completion.scheduleStatus, 'Behind by 30s');
      },
    );

    test('toMap converts to map correctly', () {
      final completedAt = DateTime(2025, 1, 1, 8, 0);
      final completion = RoutineCompletion(
        completedAt: completedAt,
        totalTimeSpent: 3000,
        tasksCompleted: 4,
        totalTasks: 4,
        scheduleVariance: -120,
        taskCompletions: const [],
      );

      final map = completion.toMap();

      expect(map['completedAt'], completedAt.millisecondsSinceEpoch);
      expect(map['totalTimeSpent'], 3000);
      expect(map['tasksCompleted'], 4);
      expect(map['totalTasks'], 4);
      expect(map['scheduleVariance'], -120);
      expect(map['taskCompletions'], isEmpty);
    });

    test('fromMap creates instance from map correctly', () {
      final completedAt = DateTime(2025, 1, 1, 8, 0);
      final map = {
        'completedAt': completedAt.millisecondsSinceEpoch,
        'totalTimeSpent': 3000,
        'tasksCompleted': 4,
        'totalTasks': 4,
        'scheduleVariance': -120,
        'taskCompletions': [],
      };

      final completion = RoutineCompletion.fromMap(map);

      expect(completion.completedAt, completedAt);
      expect(completion.totalTimeSpent, 3000);
      expect(completion.tasksCompleted, 4);
      expect(completion.totalTasks, 4);
      expect(completion.scheduleVariance, -120);
      expect(completion.taskCompletions, isEmpty);
    });

    test('toJson and fromJson round trip correctly', () {
      final completedAt = DateTime(2025, 1, 1, 8, 0);
      final original = RoutineCompletion(
        completedAt: completedAt,
        totalTimeSpent: 3000,
        tasksCompleted: 4,
        totalTasks: 4,
        scheduleVariance: -120,
        taskCompletions: const [],
      );

      final json = original.toJson();
      final decoded = RoutineCompletion.fromJson(json);

      expect(decoded.completedAt, original.completedAt);
      expect(decoded.totalTimeSpent, original.totalTimeSpent);
      expect(decoded.tasksCompleted, original.tasksCompleted);
      expect(decoded.totalTasks, original.totalTasks);
      expect(decoded.scheduleVariance, original.scheduleVariance);
    });
  });

  group('TaskCompletion', () {
    test('creates instance with all required fields', () {
      final taskCompletion = TaskCompletion(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1150,
        completedAt: DateTime(2025, 1, 1, 6, 30),
      );

      expect(taskCompletion.taskId, 'task1');
      expect(taskCompletion.taskName, 'Morning Workout');
      expect(taskCompletion.estimatedDuration, 1200);
      expect(taskCompletion.actualDuration, 1150);
      expect(taskCompletion.completedAt, DateTime(2025, 1, 1, 6, 30));
    });

    test('variance returns positive when over time', () {
      final taskCompletion = TaskCompletion(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1350,
        completedAt: DateTime.now(),
      );

      expect(taskCompletion.variance, 150);
    });

    test('variance returns negative when under time', () {
      final taskCompletion = TaskCompletion(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1050,
        completedAt: DateTime.now(),
      );

      expect(taskCompletion.variance, -150);
    });

    test('variance returns zero when exactly on time', () {
      final taskCompletion = TaskCompletion(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1200,
        completedAt: DateTime.now(),
      );

      expect(taskCompletion.variance, 0);
    });

    test('toMap converts to map correctly', () {
      final completedAt = DateTime(2025, 1, 1, 6, 30);
      final taskCompletion = TaskCompletion(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1150,
        completedAt: completedAt,
      );

      final map = taskCompletion.toMap();

      expect(map['taskId'], 'task1');
      expect(map['taskName'], 'Morning Workout');
      expect(map['estimatedDuration'], 1200);
      expect(map['actualDuration'], 1150);
      expect(map['completedAt'], completedAt.millisecondsSinceEpoch);
    });

    test('fromMap creates instance from map correctly', () {
      final completedAt = DateTime(2025, 1, 1, 6, 30);
      final map = {
        'taskId': 'task1',
        'taskName': 'Morning Workout',
        'estimatedDuration': 1200,
        'actualDuration': 1150,
        'completedAt': completedAt.millisecondsSinceEpoch,
      };

      final taskCompletion = TaskCompletion.fromMap(map);

      expect(taskCompletion.taskId, 'task1');
      expect(taskCompletion.taskName, 'Morning Workout');
      expect(taskCompletion.estimatedDuration, 1200);
      expect(taskCompletion.actualDuration, 1150);
      expect(taskCompletion.completedAt, completedAt);
    });

    test('toJson and fromJson round trip correctly', () {
      final completedAt = DateTime(2025, 1, 1, 6, 30);
      final original = TaskCompletion(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1150,
        completedAt: completedAt,
      );

      final json = original.toJson();
      final decoded = TaskCompletion.fromJson(json);

      expect(decoded.taskId, original.taskId);
      expect(decoded.taskName, original.taskName);
      expect(decoded.estimatedDuration, original.estimatedDuration);
      expect(decoded.actualDuration, original.actualDuration);
      expect(decoded.completedAt, original.completedAt);
    });
  });
}
