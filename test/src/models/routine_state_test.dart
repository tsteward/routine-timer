import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('RoutineStateModel', () {
    test('toMap/fromMap roundtrip with selectedTaskId', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
          TaskModel(id: '2', name: 'Task2', estimatedDuration: 120, order: 1),
        ],
        breaks: const [BreakModel(duration: 30, isEnabled: true)],
        settings: RoutineSettingsModel(
          startTime: 2,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 30,
        ),
        selectedTaskId: '2',
        isRunning: true,
      );
      final map = state.toMap();
      final decoded = RoutineStateModel.fromMap(map);
      expect(decoded.tasks.length, 2);
      expect(decoded.breaks!.length, 1);
      expect(decoded.settings.defaultBreakDuration, 30);
      expect(decoded.selectedTaskId, '2');
      expect(decoded.isRunning, true);
    });

    test('copyWith updates nested fields including selectedTaskId', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'A', estimatedDuration: 60, order: 0),
          TaskModel(id: '2', name: 'B', estimatedDuration: 90, order: 1),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 60,
        ),
        selectedTaskId: '1',
      );
      final updated = state.copyWith(selectedTaskId: '2', isRunning: true);
      expect(updated.selectedTaskId, '2');
      expect(updated.isRunning, true);
      expect(updated.tasks.length, 2);
    });

    test('handles null selectedTaskId', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 60,
        ),
        selectedTaskId: null,
      );
      final map = state.toMap();
      final decoded = RoutineStateModel.fromMap(map);
      expect(decoded.selectedTaskId, isNull);
      expect(decoded.tasks.length, 1);
    });

    group(
      'backward compatibility (regression tests for currentTaskIndex migration)',
      () {
        test(
          'migrates currentTaskIndex to selectedTaskId when loading old data',
          () {
            // Test backward compatibility: old data format with currentTaskIndex
            final oldFormatMap = {
              'tasks': [
                {
                  'id': 'task1',
                  'name': 'Task 1',
                  'estimatedDuration': 600,
                  'isCompleted': false,
                  'order': 0,
                },
                {
                  'id': 'task2',
                  'name': 'Task 2',
                  'estimatedDuration': 900,
                  'isCompleted': false,
                  'order': 1,
                },
                {
                  'id': 'task3',
                  'name': 'Task 3',
                  'estimatedDuration': 300,
                  'isCompleted': false,
                  'order': 2,
                },
              ],
              'settings': {
                'startTime': DateTime.now().millisecondsSinceEpoch,
                'breaksEnabledByDefault': true,
                'defaultBreakDuration': 120,
              },
              'currentTaskIndex':
                  2, // Old format field - should select task at index 2
              'isRunning': false,
            };

            // Import using fromMap (which should handle migration)
            final state = RoutineStateModel.fromMap(oldFormatMap);

            // Should migrate currentTaskIndex to selectedTaskId
            expect(
              state.selectedTaskId,
              'task3',
            ); // Should select task at index 2
            expect(state.tasks.length, 3);

            // Verify the selected task is correct
            final selectedTask = state.tasks.firstWhere(
              (t) => t.id == state.selectedTaskId,
            );
            expect(selectedTask.name, 'Task 3');
            expect(selectedTask.order, 2);
          },
        );

        test(
          'prefers selectedTaskId over currentTaskIndex when both present',
          () {
            // Test case where both old and new fields are present
            final mixedFormatMap = {
              'tasks': [
                {
                  'id': 'task1',
                  'name': 'Task 1',
                  'estimatedDuration': 600,
                  'isCompleted': false,
                  'order': 0,
                },
                {
                  'id': 'task2',
                  'name': 'Task 2',
                  'estimatedDuration': 900,
                  'isCompleted': false,
                  'order': 1,
                },
              ],
              'settings': {
                'startTime': DateTime.now().millisecondsSinceEpoch,
                'breaksEnabledByDefault': true,
                'defaultBreakDuration': 120,
              },
              'currentTaskIndex': 0, // Old format field
              'selectedTaskId':
                  'task2', // New format field - should take precedence
              'isRunning': false,
            };

            final state = RoutineStateModel.fromMap(mixedFormatMap);

            // Should prefer the new selectedTaskId field
            expect(state.selectedTaskId, 'task2');
          },
        );

        test('handles invalid currentTaskIndex gracefully', () {
          // Test edge case where currentTaskIndex is out of bounds
          final invalidIndexMap = {
            'tasks': [
              {
                'id': 'task1',
                'name': 'Task 1',
                'estimatedDuration': 600,
                'isCompleted': false,
                'order': 0,
              },
            ],
            'settings': {
              'startTime': DateTime.now().millisecondsSinceEpoch,
              'breaksEnabledByDefault': true,
              'defaultBreakDuration': 120,
            },
            'currentTaskIndex': 5, // Out of bounds - only 1 task exists
            'isRunning': false,
          };

          final state = RoutineStateModel.fromMap(invalidIndexMap);

          // Should handle invalid index gracefully (set to null)
          expect(state.selectedTaskId, isNull);
          expect(state.tasks.length, 1);
        });

        test('handles negative currentTaskIndex', () {
          // Test edge case where currentTaskIndex is negative
          final negativeIndexMap = {
            'tasks': [
              {
                'id': 'task1',
                'name': 'Task 1',
                'estimatedDuration': 600,
                'isCompleted': false,
                'order': 0,
              },
            ],
            'settings': {
              'startTime': DateTime.now().millisecondsSinceEpoch,
              'breaksEnabledByDefault': true,
              'defaultBreakDuration': 120,
            },
            'currentTaskIndex': -1, // Negative index
            'isRunning': false,
          };

          final state = RoutineStateModel.fromMap(negativeIndexMap);

          // Should handle negative index gracefully (set to null)
          expect(state.selectedTaskId, isNull);
          expect(state.tasks.length, 1);
        });

        test('handles empty tasks list with currentTaskIndex', () {
          // Test edge case where there are no tasks but currentTaskIndex is set
          final emptyTasksMap = {
            'tasks': <Map<String, dynamic>>[],
            'settings': {
              'startTime': DateTime.now().millisecondsSinceEpoch,
              'breaksEnabledByDefault': true,
              'defaultBreakDuration': 120,
            },
            'currentTaskIndex': 0, // Index into empty list
            'isRunning': false,
          };

          final state = RoutineStateModel.fromMap(emptyTasksMap);

          // Should handle empty tasks gracefully (set to null)
          expect(state.selectedTaskId, isNull);
          expect(state.tasks.length, 0);
        });
      },
    );
  });
}
