import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('RoutineStateModel', () {
    test('toMap/fromMap roundtrip', () {
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
      expect(
        decoded.currentTaskIndex,
        1,
      ); // Should be 1 because task '2' is at index 1
      expect(decoded.selectedTaskId, '2');
      expect(decoded.isRunning, true);
    });

    test('copyWith updates nested fields', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'A', estimatedDuration: 60, order: 0),
          TaskModel(id: '2', name: 'B', estimatedDuration: 120, order: 1),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 60,
        ),
      );
      final updated = state.copyWith(selectedTaskId: '2', isRunning: true);
      expect(updated.currentTaskIndex, 1); // Task '2' is at index 1
      expect(updated.selectedTaskId, '2');
      expect(updated.isRunning, true);
      expect(updated.tasks.length, 2);
    });

    test('fromMap handles migration from old currentTaskIndex', () {
      // Simulate old data format with currentTaskIndex instead of selectedTaskId
      final oldFormatMap = {
        'tasks': [
          {
            'id': '1',
            'name': 'Task1',
            'estimatedDuration': 60,
            'order': 0,
            'isCompleted': false,
          },
          {
            'id': '2',
            'name': 'Task2',
            'estimatedDuration': 120,
            'order': 1,
            'isCompleted': false,
          },
        ],
        'breaks': [
          {'duration': 30, 'isEnabled': true, 'isCustomized': false},
        ],
        'settings': {
          'startTime': 2,
          'breaksEnabledByDefault': true,
          'defaultBreakDuration': 30,
        },
        'currentTaskIndex': 1, // Old format
        'isRunning': true,
      };

      final decoded = RoutineStateModel.fromMap(oldFormatMap);
      expect(
        decoded.selectedTaskId,
        '2',
      ); // Should migrate to task ID at index 1
      expect(decoded.currentTaskIndex, 1); // Should still work
    });

    test('selectedTask getter returns correct task', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'First', estimatedDuration: 60, order: 0),
          TaskModel(id: '2', name: 'Second', estimatedDuration: 120, order: 1),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 60,
        ),
        selectedTaskId: '2',
      );

      expect(state.selectedTask?.id, '2');
      expect(state.selectedTask?.name, 'Second');
    });

    test('selectedTask getter handles null selection', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'First', estimatedDuration: 60, order: 0),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 60,
        ),
        selectedTaskId: null,
      );

      expect(state.selectedTask?.id, '1'); // Should default to first task
    });

    test('selectedTask getter handles non-existent selection', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'First', estimatedDuration: 60, order: 0),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 60,
        ),
        selectedTaskId: 'non-existent',
      );

      expect(state.selectedTask?.id, '1'); // Should fall back to first task
    });

    test('break state fields serialize correctly', () {
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
        selectedTaskId: '1',
        isRunning: true,
        isInBreak: true,
        currentBreakIndex: 0,
      );

      final map = state.toMap();
      final decoded = RoutineStateModel.fromMap(map);

      expect(decoded.isInBreak, true);
      expect(decoded.currentBreakIndex, 0);
    });

    test('break state defaults to false when not specified', () {
      final map = {
        'tasks': [
          {
            'id': '1',
            'name': 'Task1',
            'estimatedDuration': 60,
            'order': 0,
            'isCompleted': false,
          },
        ],
        'settings': {
          'startTime': 0,
          'breaksEnabledByDefault': true,
          'defaultBreakDuration': 30,
        },
        'isRunning': false,
        // isInBreak and currentBreakIndex not specified
      };

      final decoded = RoutineStateModel.fromMap(map);
      expect(decoded.isInBreak, false);
      expect(decoded.currentBreakIndex, null);
    });

    test('copyWith updates break state fields', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 30,
        ),
        isInBreak: false,
        currentBreakIndex: null,
      );

      final updated = state.copyWith(isInBreak: true, currentBreakIndex: 0);

      expect(updated.isInBreak, true);
      expect(updated.currentBreakIndex, 0);
      expect(updated.tasks, state.tasks); // Other fields unchanged
    });

    test('copyWith can clear break state', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 30,
        ),
        isInBreak: true,
        currentBreakIndex: 0,
      );

      final updated = state.copyWith(isInBreak: false);

      expect(updated.isInBreak, false);
      // Note: copyWith doesn't clear currentBreakIndex when not explicitly provided
      // This is standard Dart copyWith behavior - fields retain their value unless overridden
      expect(updated.currentBreakIndex, 0);
    });

    test('toJson/fromJson roundtrip with break state', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
        ],
        breaks: const [BreakModel(duration: 120, isEnabled: true)],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 30,
        ),
        isInBreak: true,
        currentBreakIndex: 0,
      );

      final json = state.toJson();
      final decoded = RoutineStateModel.fromJson(json);

      expect(decoded.isInBreak, true);
      expect(decoded.currentBreakIndex, 0);
      expect(decoded.tasks.length, 1);
      expect(decoded.breaks!.length, 1);
    });
  });
}
