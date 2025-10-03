import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';

void main() {
  group('TaskModel', () {
    test('toMap/fromMap roundtrip', () {
      const task = TaskModel(
        id: 't1',
        name: 'Shower',
        estimatedDuration: 600,
        actualDuration: 580,
        isCompleted: true,
        order: 1,
      );
      final map = task.toMap();
      final decoded = TaskModel.fromMap(map);
      expect(decoded.id, task.id);
      expect(decoded.name, task.name);
      expect(decoded.estimatedDuration, task.estimatedDuration);
      expect(decoded.actualDuration, task.actualDuration);
      expect(decoded.isCompleted, task.isCompleted);
      expect(decoded.order, task.order);
    });

    test('copyWith updates selected fields', () {
      const task = TaskModel(
        id: 't',
        name: 'A',
        estimatedDuration: 60,
        order: 0,
      );
      final updated = task.copyWith(name: 'B', order: 2);
      expect(updated.name, 'B');
      expect(updated.order, 2);
      expect(updated.id, task.id);
      expect(updated.estimatedDuration, task.estimatedDuration);
    });
  });

  group('BreakModel', () {
    test('toMap/fromMap roundtrip', () {
      const br = BreakModel(duration: 120, isEnabled: false);
      final map = br.toMap();
      final decoded = BreakModel.fromMap(map);
      expect(decoded.duration, 120);
      expect(decoded.isEnabled, false);
    });

    test('copyWith toggles fields', () {
      const br = BreakModel(duration: 60, isEnabled: true);
      final updated = br.copyWith(isEnabled: false, duration: 90);
      expect(updated.duration, 90);
      expect(updated.isEnabled, false);
    });
  });

  group('RoutineSettingsModel', () {
    test('toMap/fromMap roundtrip', () {
      final settings = RoutineSettingsModel(
        startTime: DateTime(2024, 1, 1, 8, 0).millisecondsSinceEpoch,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 120,
      );
      final map = settings.toMap();
      final decoded = RoutineSettingsModel.fromMap(map);
      expect(decoded.startTime, settings.startTime);
      expect(decoded.breaksEnabledByDefault, false);
      expect(decoded.defaultBreakDuration, 120);
    });

    test('copyWith updates fields', () {
      final settings = RoutineSettingsModel(
        startTime: 1,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 60,
      );
      final updated = settings.copyWith(defaultBreakDuration: 90, breaksEnabledByDefault: false);
      expect(updated.defaultBreakDuration, 90);
      expect(updated.breaksEnabledByDefault, false);
      expect(updated.startTime, 1);
    });
  });

  group('RoutineStateModel', () {
    test('toMap/fromMap roundtrip', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
          TaskModel(id: '2', name: 'Task2', estimatedDuration: 120, order: 1),
        ],
        breaks: const [
          BreakModel(duration: 30, isEnabled: true),
        ],
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

    test('copyWith updates nested fields', () {
      final state = RoutineStateModel(
        tasks: const [TaskModel(id: '1', name: 'A', estimatedDuration: 60, order: 0)],
        settings: RoutineSettingsModel(startTime: 0, breaksEnabledByDefault: true, defaultBreakDuration: 60),
      );
      final updated = state.copyWith(currentTaskIndex: 2, isRunning: true);
      expect(updated.currentTaskIndex, 2);
      expect(updated.isRunning, true);
      expect(updated.tasks.length, 1);
    });
  });
}
