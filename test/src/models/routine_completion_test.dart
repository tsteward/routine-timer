import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_completion.dart';

void main() {
  group('RoutineCompletion', () {
    test('should create a valid RoutineCompletion instance', () {
      final completion = RoutineCompletion(
        completedAt: 1234567890,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: const [],
      );

      expect(completion.completedAt, 1234567890);
      expect(completion.totalTimeSpent, 3600);
      expect(completion.tasksCompleted, 4);
      expect(completion.totalEstimatedTime, 3000);
      expect(completion.taskDetails, isEmpty);
    });

    test('should calculate time difference correctly (ahead of schedule)', () {
      final completion = RoutineCompletion(
        completedAt: 1234567890,
        totalTimeSpent: 2700, // 45 minutes
        tasksCompleted: 4,
        totalEstimatedTime: 3000, // 50 minutes
        taskDetails: const [],
      );

      expect(completion.timeDifference, 300); // 5 minutes ahead
      expect(completion.isAheadOfSchedule, isTrue);
    });

    test('should calculate time difference correctly (behind schedule)', () {
      final completion = RoutineCompletion(
        completedAt: 1234567890,
        totalTimeSpent: 3600, // 60 minutes
        tasksCompleted: 4,
        totalEstimatedTime: 3000, // 50 minutes
        taskDetails: const [],
      );

      expect(completion.timeDifference, -600); // 10 minutes behind
      expect(completion.isAheadOfSchedule, isFalse);
    });

    test('should serialize to and from map correctly', () {
      final taskDetail = TaskCompletionDetail(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1000,
      );

      final completion = RoutineCompletion(
        completedAt: 1234567890,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: [taskDetail],
      );

      final map = completion.toMap();
      final restored = RoutineCompletion.fromMap(map);

      expect(restored.completedAt, completion.completedAt);
      expect(restored.totalTimeSpent, completion.totalTimeSpent);
      expect(restored.tasksCompleted, completion.tasksCompleted);
      expect(restored.totalEstimatedTime, completion.totalEstimatedTime);
      expect(restored.taskDetails.length, 1);
      expect(restored.taskDetails[0].taskId, 'task1');
    });

    test('should serialize to and from JSON correctly', () {
      final completion = RoutineCompletion(
        completedAt: 1234567890,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: const [],
      );

      final json = completion.toJson();
      final restored = RoutineCompletion.fromJson(json);

      expect(restored.completedAt, completion.completedAt);
      expect(restored.totalTimeSpent, completion.totalTimeSpent);
      expect(restored.tasksCompleted, completion.tasksCompleted);
      expect(restored.totalEstimatedTime, completion.totalEstimatedTime);
    });
  });

  group('TaskCompletionDetail', () {
    test('should create a valid TaskCompletionDetail instance', () {
      const detail = TaskCompletionDetail(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1000,
      );

      expect(detail.taskId, 'task1');
      expect(detail.taskName, 'Morning Workout');
      expect(detail.estimatedDuration, 1200);
      expect(detail.actualDuration, 1000);
    });

    test('should calculate time difference correctly (faster)', () {
      const detail = TaskCompletionDetail(
        taskId: 'task1',
        taskName: 'Shower',
        estimatedDuration: 600,
        actualDuration: 480,
      );

      expect(detail.timeDifference, -120); // 2 minutes faster
    });

    test('should calculate time difference correctly (slower)', () {
      const detail = TaskCompletionDetail(
        taskId: 'task1',
        taskName: 'Breakfast',
        estimatedDuration: 900,
        actualDuration: 1200,
      );

      expect(detail.timeDifference, 300); // 5 minutes slower
    });

    test('should serialize to and from map correctly', () {
      const detail = TaskCompletionDetail(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1000,
      );

      final map = detail.toMap();
      final restored = TaskCompletionDetail.fromMap(map);

      expect(restored.taskId, detail.taskId);
      expect(restored.taskName, detail.taskName);
      expect(restored.estimatedDuration, detail.estimatedDuration);
      expect(restored.actualDuration, detail.actualDuration);
    });

    test('should serialize to and from JSON correctly', () {
      const detail = TaskCompletionDetail(
        taskId: 'task1',
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1000,
      );

      final json = detail.toJson();
      final restored = TaskCompletionDetail.fromJson(json);

      expect(restored.taskId, detail.taskId);
      expect(restored.taskName, detail.taskName);
      expect(restored.estimatedDuration, detail.estimatedDuration);
      expect(restored.actualDuration, detail.actualDuration);
    });
  });
}
