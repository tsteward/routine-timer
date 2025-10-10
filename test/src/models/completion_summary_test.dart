import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/completion_summary.dart';

void main() {
  group('CompletionSummary', () {
    const mockDateTime = '2025-01-01T08:00:00.000Z';
    final testDateTime = DateTime.parse(mockDateTime);

    final sampleTasks = [
      const CompletedTaskSummary(
        name: 'Task 1',
        estimatedDuration: 300, // 5 minutes
        actualDuration: 240, // 4 minutes (faster)
        wasCompleted: true,
        order: 0,
      ),
      const CompletedTaskSummary(
        name: 'Task 2',
        estimatedDuration: 600, // 10 minutes
        actualDuration: 720, // 12 minutes (slower)
        wasCompleted: true,
        order: 1,
      ),
      const CompletedTaskSummary(
        name: 'Task 3',
        estimatedDuration: 300, // 5 minutes
        actualDuration: 0, // not completed
        wasCompleted: false,
        order: 2,
      ),
    ];

    final sampleSummary = CompletionSummary(
      completedAt: testDateTime,
      totalTimeSpent: 960, // 16 minutes actual
      totalEstimatedTime: 1200, // 20 minutes estimated
      tasksCompleted: 2,
      totalTasks: 3,
      tasks: sampleTasks,
    );

    test('calculates isAheadOfSchedule correctly when ahead', () {
      final aheadSummary = sampleSummary.copyWith(
        totalTimeSpent: 1000, // 16.67 minutes
        totalEstimatedTime: 1200, // 20 minutes
      );

      expect(aheadSummary.isAheadOfSchedule, isTrue);
    });

    test('calculates isAheadOfSchedule correctly when behind', () {
      final behindSummary = sampleSummary.copyWith(
        totalTimeSpent: 1500, // 25 minutes
        totalEstimatedTime: 1200, // 20 minutes
      );

      expect(behindSummary.isAheadOfSchedule, isFalse);
    });

    test('calculates timeDifference correctly', () {
      expect(sampleSummary.timeDifference, equals(-240)); // 4 minutes ahead

      final behindSummary = sampleSummary.copyWith(
        totalTimeSpent: 1500, // 25 minutes
        totalEstimatedTime: 1200, // 20 minutes
      );
      expect(behindSummary.timeDifference, equals(300)); // 5 minutes behind
    });

    test('calculates completionPercentage correctly', () {
      expect(sampleSummary.completionPercentage, equals(2.0 / 3.0));

      final fullCompletion = sampleSummary.copyWith(
        tasksCompleted: 3,
        totalTasks: 3,
      );
      expect(fullCompletion.completionPercentage, equals(1.0));

      final noCompletion = sampleSummary.copyWith(
        tasksCompleted: 0,
        totalTasks: 3,
      );
      expect(noCompletion.completionPercentage, equals(0.0));
    });

    test('handles empty tasks list', () {
      final emptySummary = CompletionSummary(
        completedAt: testDateTime,
        totalTimeSpent: 0,
        totalEstimatedTime: 0,
        tasksCompleted: 0,
        totalTasks: 0,
        tasks: const [],
      );

      expect(emptySummary.completionPercentage, equals(0.0));
      expect(emptySummary.timeDifference, equals(0));
      expect(emptySummary.isAheadOfSchedule, isFalse);
    });

    test('copyWith works correctly', () {
      final newDateTime = DateTime.parse('2025-01-02T10:00:00.000Z');
      final copied = sampleSummary.copyWith(
        completedAt: newDateTime,
        tasksCompleted: 3,
        routineName: 'Evening Routine',
      );

      expect(copied.completedAt, equals(newDateTime));
      expect(copied.tasksCompleted, equals(3));
      expect(copied.routineName, equals('Evening Routine'));

      // Unchanged properties should remain the same
      expect(copied.totalTimeSpent, equals(sampleSummary.totalTimeSpent));
      expect(
        copied.totalEstimatedTime,
        equals(sampleSummary.totalEstimatedTime),
      );
      expect(copied.totalTasks, equals(sampleSummary.totalTasks));
    });

    test('toMap/fromMap serialization works correctly', () {
      final map = sampleSummary.toMap();
      final restored = CompletionSummary.fromMap(map);

      expect(
        restored.completedAt.millisecondsSinceEpoch,
        equals(sampleSummary.completedAt.millisecondsSinceEpoch),
      );
      expect(restored.totalTimeSpent, equals(sampleSummary.totalTimeSpent));
      expect(
        restored.totalEstimatedTime,
        equals(sampleSummary.totalEstimatedTime),
      );
      expect(restored.tasksCompleted, equals(sampleSummary.tasksCompleted));
      expect(restored.totalTasks, equals(sampleSummary.totalTasks));
      expect(restored.routineName, equals(sampleSummary.routineName));
      expect(restored.tasks.length, equals(sampleSummary.tasks.length));

      for (int i = 0; i < restored.tasks.length; i++) {
        expect(restored.tasks[i].name, equals(sampleSummary.tasks[i].name));
        expect(
          restored.tasks[i].estimatedDuration,
          equals(sampleSummary.tasks[i].estimatedDuration),
        );
        expect(
          restored.tasks[i].actualDuration,
          equals(sampleSummary.tasks[i].actualDuration),
        );
        expect(
          restored.tasks[i].wasCompleted,
          equals(sampleSummary.tasks[i].wasCompleted),
        );
        expect(restored.tasks[i].order, equals(sampleSummary.tasks[i].order));
      }
    });

    test('toJson/fromJson serialization works correctly', () {
      final json = sampleSummary.toJson();
      final restored = CompletionSummary.fromJson(json);

      expect(
        restored.completedAt.millisecondsSinceEpoch,
        equals(sampleSummary.completedAt.millisecondsSinceEpoch),
      );
      expect(restored.totalTimeSpent, equals(sampleSummary.totalTimeSpent));
      expect(restored.routineName, equals(sampleSummary.routineName));
    });

    test('uses default routine name when not provided in fromMap', () {
      final mapWithoutName = sampleSummary.toMap()..remove('routineName');
      final restored = CompletionSummary.fromMap(mapWithoutName);

      expect(restored.routineName, equals('Morning Routine'));
    });
  });

  group('CompletedTaskSummary', () {
    const sampleTask = CompletedTaskSummary(
      name: 'Sample Task',
      estimatedDuration: 600, // 10 minutes
      actualDuration: 480, // 8 minutes
      wasCompleted: true,
      order: 0,
    );

    test('calculates timeDifference correctly', () {
      expect(sampleTask.timeDifference, equals(-120)); // 2 minutes faster

      const slowerTask = CompletedTaskSummary(
        name: 'Slower Task',
        estimatedDuration: 300, // 5 minutes
        actualDuration: 420, // 7 minutes
        wasCompleted: true,
        order: 1,
      );
      expect(slowerTask.timeDifference, equals(120)); // 2 minutes slower
    });

    test('calculates wasFaster correctly', () {
      expect(sampleTask.wasFaster, isTrue);

      const slowerTask = CompletedTaskSummary(
        name: 'Slower Task',
        estimatedDuration: 300, // 5 minutes
        actualDuration: 420, // 7 minutes
        wasCompleted: true,
        order: 1,
      );
      expect(slowerTask.wasFaster, isFalse);

      const exactTask = CompletedTaskSummary(
        name: 'Exact Task',
        estimatedDuration: 300, // 5 minutes
        actualDuration: 300, // 5 minutes exactly
        wasCompleted: true,
        order: 2,
      );
      expect(exactTask.wasFaster, isFalse);
    });

    test('copyWith works correctly', () {
      final copied = sampleTask.copyWith(
        name: 'Updated Task',
        actualDuration: 720,
        wasCompleted: false,
      );

      expect(copied.name, equals('Updated Task'));
      expect(copied.actualDuration, equals(720));
      expect(copied.wasCompleted, isFalse);

      // Unchanged properties should remain the same
      expect(copied.estimatedDuration, equals(sampleTask.estimatedDuration));
      expect(copied.order, equals(sampleTask.order));
    });

    test('toMap/fromMap serialization works correctly', () {
      final map = sampleTask.toMap();
      final restored = CompletedTaskSummary.fromMap(map);

      expect(restored.name, equals(sampleTask.name));
      expect(restored.estimatedDuration, equals(sampleTask.estimatedDuration));
      expect(restored.actualDuration, equals(sampleTask.actualDuration));
      expect(restored.wasCompleted, equals(sampleTask.wasCompleted));
      expect(restored.order, equals(sampleTask.order));
    });

    test('toJson/fromJson serialization works correctly', () {
      final json = sampleTask.toJson();
      final restored = CompletedTaskSummary.fromJson(json);

      expect(restored.name, equals(sampleTask.name));
      expect(restored.estimatedDuration, equals(sampleTask.estimatedDuration));
      expect(restored.actualDuration, equals(sampleTask.actualDuration));
      expect(restored.wasCompleted, equals(sampleTask.wasCompleted));
      expect(restored.order, equals(sampleTask.order));
    });

    test('handles not completed task', () {
      const incompleteTask = CompletedTaskSummary(
        name: 'Incomplete Task',
        estimatedDuration: 600,
        actualDuration: 0,
        wasCompleted: false,
        order: 0,
      );

      expect(incompleteTask.timeDifference, equals(-600));
      expect(
        incompleteTask.wasFaster,
        isTrue,
      ); // technically true since 0 < 600
    });
  });
}
