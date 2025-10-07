import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('RoutineStateModel', () {
    test('creates instance with required parameters', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
        ],
        settings: RoutineSettingsModel(
          startTime: 1000,
          defaultBreakDuration: 300,
        ),
      );
      expect(state.tasks.length, 1);
      expect(state.settings.startTime, 1000);
      expect(state.currentTaskIndex, 0); // default
      expect(state.isRunning, false); // default
      expect(state.breaks, isNull); // optional
    });

    test('creates instance with all parameters', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
          TaskModel(id: '2', name: 'Task2', estimatedDuration: 120, order: 1),
        ],
        breaks: const [BreakModel(duration: 180)],
        settings: RoutineSettingsModel(
          startTime: 2000,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 180,
        ),
        currentTaskIndex: 1,
        isRunning: true,
      );
      expect(state.tasks.length, 2);
      expect(state.breaks?.length, 1);
      expect(state.currentTaskIndex, 1);
      expect(state.isRunning, true);
    });

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
        currentTaskIndex: 1,
        isRunning: true,
      );
      final map = state.toMap();
      final decoded = RoutineStateModel.fromMap(map);
      expect(decoded.tasks.length, 2);
      expect(decoded.breaks!.length, 1);
      expect(decoded.settings.defaultBreakDuration, 30);
      expect(decoded.currentTaskIndex, 1);
      expect(decoded.isRunning, true);
    });

    test('fromMap handles null breaks', () {
      final map = {
        'tasks': [
          {'id': '1', 'name': 'Task', 'estimatedDuration': 100, 'order': 0},
        ],
        'breaks': null,
        'settings': {
          'startTime': 5000,
          'breaksEnabledByDefault': true,
          'defaultBreakDuration': 200,
        },
        'currentTaskIndex': 0,
        'isRunning': false,
      };
      final state = RoutineStateModel.fromMap(map);
      expect(state.breaks, isNull);
      expect(state.tasks.length, 1);
    });

    test('fromMap uses default values when fields are missing', () {
      final map = {
        'tasks': [
          {'id': '1', 'name': 'Task', 'estimatedDuration': 100, 'order': 0},
        ],
        'settings': {
          'startTime': 5000,
          'defaultBreakDuration': 200,
        },
      };
      final state = RoutineStateModel.fromMap(map);
      expect(state.currentTaskIndex, 0);
      expect(state.isRunning, false);
    });

    test('toJson creates valid JSON string', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
        ],
        breaks: const [BreakModel(duration: 120, isEnabled: true)],
        settings: RoutineSettingsModel(
          startTime: 7000,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        ),
        currentTaskIndex: 0,
        isRunning: false,
      );
      final json = state.toJson();
      expect(json, isA<String>());
      expect(json, contains('Task1'));
      expect(json, contains('7000'));
    });

    test('fromJson parses valid JSON string', () {
      const jsonString = '{"tasks":[{"id":"t1","name":"Test",'
          '"estimatedDuration":300,"actualDuration":null,"isCompleted":false,'
          '"order":0}],"breaks":[],"settings":{"startTime":8000,'
          '"breaksEnabledByDefault":true,"defaultBreakDuration":150},'
          '"currentTaskIndex":0,"isRunning":false}';
      final state = RoutineStateModel.fromJson(jsonString);
      expect(state.tasks.length, 1);
      expect(state.tasks.first.name, 'Test');
      expect(state.settings.startTime, 8000);
    });

    test('toJson/fromJson roundtrip', () {
      final original = RoutineStateModel(
        tasks: const [
          TaskModel(id: 't1', name: 'Task A', estimatedDuration: 200, order: 0),
          TaskModel(id: 't2', name: 'Task B', estimatedDuration: 300, order: 1),
        ],
        breaks: const [
          BreakModel(duration: 100, isEnabled: true, isCustomized: false),
        ],
        settings: RoutineSettingsModel(
          startTime: 9000,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 100,
        ),
        currentTaskIndex: 1,
        isRunning: true,
      );
      final json = original.toJson();
      final decoded = RoutineStateModel.fromJson(json);
      expect(decoded.tasks.length, original.tasks.length);
      expect(decoded.breaks?.length, original.breaks?.length);
      expect(decoded.settings.startTime, original.settings.startTime);
      expect(decoded.currentTaskIndex, original.currentTaskIndex);
      expect(decoded.isRunning, original.isRunning);
    });

    test('copyWith updates nested fields', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'A', estimatedDuration: 60, order: 0),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 60,
        ),
      );
      final updated = state.copyWith(currentTaskIndex: 2, isRunning: true);
      expect(updated.currentTaskIndex, 2);
      expect(updated.isRunning, true);
      expect(updated.tasks.length, 1);
    });

    test('copyWith can update tasks and breaks', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Old', estimatedDuration: 60, order: 0),
        ],
        breaks: const [BreakModel(duration: 100)],
        settings: RoutineSettingsModel(
          startTime: 1000,
          defaultBreakDuration: 100,
        ),
      );
      final newTasks = [
        const TaskModel(id: '2', name: 'New', estimatedDuration: 120, order: 0),
      ];
      final newBreaks = [const BreakModel(duration: 200)];
      final updated = state.copyWith(tasks: newTasks, breaks: newBreaks);
      expect(updated.tasks.length, 1);
      expect(updated.tasks.first.name, 'New');
      expect(updated.breaks?.first.duration, 200);
    });

    test('copyWith can update settings', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task', estimatedDuration: 60, order: 0),
        ],
        settings: RoutineSettingsModel(
          startTime: 1000,
          defaultBreakDuration: 100,
        ),
      );
      final newSettings = RoutineSettingsModel(
        startTime: 2000,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 200,
      );
      final updated = state.copyWith(settings: newSettings);
      expect(updated.settings.startTime, 2000);
      expect(updated.settings.breaksEnabledByDefault, false);
      expect(updated.settings.defaultBreakDuration, 200);
      // Original task should remain
      expect(updated.tasks.first.name, 'Task');
    });

    test('copyWith with no parameters returns copy with same values', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task', estimatedDuration: 60, order: 0),
        ],
        breaks: const [BreakModel(duration: 150)],
        settings: RoutineSettingsModel(
          startTime: 3000,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 150,
        ),
        currentTaskIndex: 0,
        isRunning: false,
      );
      final updated = state.copyWith();
      expect(updated.tasks.length, state.tasks.length);
      expect(updated.breaks?.length, state.breaks?.length);
      expect(updated.settings.startTime, state.settings.startTime);
      expect(updated.currentTaskIndex, state.currentTaskIndex);
      expect(updated.isRunning, state.isRunning);
    });
  });
}
