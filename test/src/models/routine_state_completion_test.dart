import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('RoutineStateModel completion helpers', () {
    final settings = RoutineSettingsModel(
      startTime: DateTime(2025, 1, 1, 6, 0).millisecondsSinceEpoch,
      breaksEnabledByDefault: true,
      defaultBreakDuration: 120,
    );

    test('isRoutineCompleted returns false when no tasks exist', () {
      final state = RoutineStateModel(tasks: const [], settings: settings);

      expect(state.isRoutineCompleted, isFalse);
    });

    test('isRoutineCompleted returns false when some tasks incomplete', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 580,
            order: 0,
          ),
          TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 600,
            isCompleted: false,
            order: 1,
          ),
        ],
        settings: settings,
      );

      expect(state.isRoutineCompleted, isFalse);
    });

    test('isRoutineCompleted returns true when all tasks completed', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 580,
            order: 0,
          ),
          TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 620,
            order: 1,
          ),
        ],
        settings: settings,
      );

      expect(state.isRoutineCompleted, isTrue);
    });

    test('completedTasksCount returns correct count', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 580,
            order: 0,
          ),
          TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 600,
            isCompleted: false,
            order: 1,
          ),
          TaskModel(
            id: '3',
            name: 'Task 3',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 590,
            order: 2,
          ),
        ],
        settings: settings,
      );

      expect(state.completedTasksCount, 2);
    });

    test('completedTasksCount returns 0 when no tasks completed', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: false,
            order: 0,
          ),
          TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 600,
            isCompleted: false,
            order: 1,
          ),
        ],
        settings: settings,
      );

      expect(state.completedTasksCount, 0);
    });

    test('totalTimeSpent calculates correctly', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 580,
            order: 0,
          ),
          TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 620,
            order: 1,
          ),
          TaskModel(
            id: '3',
            name: 'Task 3',
            estimatedDuration: 600,
            isCompleted: false,
            order: 2,
          ),
        ],
        settings: settings,
      );

      expect(state.totalTimeSpent, 1200); // 580 + 620
    });

    test('totalTimeSpent returns 0 when no tasks completed', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: false,
            order: 0,
          ),
        ],
        settings: settings,
      );

      expect(state.totalTimeSpent, 0);
    });

    test('totalTimeSpent handles null actualDuration gracefully', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: null,
            order: 0,
          ),
        ],
        settings: settings,
      );

      expect(state.totalTimeSpent, 0);
    });

    test('totalEstimatedTime calculates correctly', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task 1', estimatedDuration: 600, order: 0),
          TaskModel(id: '2', name: 'Task 2', estimatedDuration: 900, order: 1),
          TaskModel(id: '3', name: 'Task 3', estimatedDuration: 300, order: 2),
        ],
        settings: settings,
      );

      expect(state.totalEstimatedTime, 1800); // 600 + 900 + 300
    });

    test('totalEstimatedTime returns 0 when no tasks', () {
      final state = RoutineStateModel(tasks: const [], settings: settings);

      expect(state.totalEstimatedTime, 0);
    });

    test('scheduleVariance calculates correctly when ahead', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 550,
            order: 0,
          ),
          TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 580,
            order: 1,
          ),
        ],
        settings: settings,
      );

      // Total spent: 550 + 580 = 1130
      // Total estimated: 600 + 600 = 1200
      // Variance: 1130 - 1200 = -70 (ahead by 70 seconds)
      expect(state.scheduleVariance, -70);
    });

    test('scheduleVariance calculates correctly when behind', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 650,
            order: 0,
          ),
          TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 630,
            order: 1,
          ),
        ],
        settings: settings,
      );

      // Total spent: 650 + 630 = 1280
      // Total estimated: 600 + 600 = 1200
      // Variance: 1280 - 1200 = 80 (behind by 80 seconds)
      expect(state.scheduleVariance, 80);
    });

    test('scheduleVariance is 0 when on schedule', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            isCompleted: true,
            actualDuration: 600,
            order: 0,
          ),
        ],
        settings: settings,
      );

      expect(state.scheduleVariance, 0);
    });
  });
}
