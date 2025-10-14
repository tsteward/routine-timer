import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_completion.dart';

void main() {
  group('RoutineCompletionModel', () {
    test('should create completion model with required fields', () {
      const completion = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      expect(completion.completedAt, 1234567890);
      expect(completion.totalTasksCompleted, 4);
      expect(completion.totalTimeSpent, 3000);
      expect(completion.totalEstimatedTime, 3600);
      expect(completion.routineName, 'Morning Routine');
      expect(completion.tasksDetails, isNull);
    });

    test('should calculate time difference correctly when ahead', () {
      const completion = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      expect(completion.timeDifference, 600); // 3600 - 3000 = 600 seconds ahead
      expect(completion.isAhead, true);
    });

    test('should calculate time difference correctly when behind', () {
      const completion = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 4000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      expect(
        completion.timeDifference,
        -400,
      ); // 3600 - 4000 = -400 seconds behind
      expect(completion.isAhead, false);
    });

    test('should serialize to and from map', () {
      const completion = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
        tasksDetails: [
          TaskCompletionDetail(
            taskName: 'Task 1',
            estimatedDuration: 900,
            actualDuration: 850,
          ),
        ],
      );

      final map = completion.toMap();
      final restored = RoutineCompletionModel.fromMap(map);

      expect(restored.completedAt, completion.completedAt);
      expect(restored.totalTasksCompleted, completion.totalTasksCompleted);
      expect(restored.totalTimeSpent, completion.totalTimeSpent);
      expect(restored.totalEstimatedTime, completion.totalEstimatedTime);
      expect(restored.routineName, completion.routineName);
      expect(restored.tasksDetails?.length, 1);
      expect(restored.tasksDetails![0].taskName, 'Task 1');
    });

    test('should serialize to and from JSON', () {
      const completion = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      final json = completion.toJson();
      final restored = RoutineCompletionModel.fromJson(json);

      expect(restored.completedAt, completion.completedAt);
      expect(restored.totalTasksCompleted, completion.totalTasksCompleted);
      expect(restored.totalTimeSpent, completion.totalTimeSpent);
      expect(restored.totalEstimatedTime, completion.totalEstimatedTime);
      expect(restored.routineName, completion.routineName);
    });

    test('should handle null tasksDetails in serialization', () {
      const completion = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      final map = completion.toMap();
      final restored = RoutineCompletionModel.fromMap(map);

      expect(restored.tasksDetails, isNull);
    });
  });

  group('TaskCompletionDetail', () {
    test('should create task detail with required fields', () {
      const detail = TaskCompletionDetail(
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1100,
      );

      expect(detail.taskName, 'Morning Workout');
      expect(detail.estimatedDuration, 1200);
      expect(detail.actualDuration, 1100);
    });

    test('should calculate time difference when faster', () {
      const detail = TaskCompletionDetail(
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1100,
      );

      expect(detail.timeDifference, 100); // Positive means faster
    });

    test('should calculate time difference when slower', () {
      const detail = TaskCompletionDetail(
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1300,
      );

      expect(detail.timeDifference, -100); // Negative means slower
    });

    test('should serialize to and from map', () {
      const detail = TaskCompletionDetail(
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1100,
      );

      final map = detail.toMap();
      final restored = TaskCompletionDetail.fromMap(map);

      expect(restored.taskName, detail.taskName);
      expect(restored.estimatedDuration, detail.estimatedDuration);
      expect(restored.actualDuration, detail.actualDuration);
    });

    test('should serialize to and from JSON', () {
      const detail = TaskCompletionDetail(
        taskName: 'Morning Workout',
        estimatedDuration: 1200,
        actualDuration: 1100,
      );

      final json = detail.toJson();
      final restored = TaskCompletionDetail.fromJson(json);

      expect(restored.taskName, detail.taskName);
      expect(restored.estimatedDuration, detail.estimatedDuration);
      expect(restored.actualDuration, detail.actualDuration);
    });
  });
}
