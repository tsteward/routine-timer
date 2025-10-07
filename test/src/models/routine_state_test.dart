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

    test('toJson/fromJson roundtrip', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: 't1', name: 'Task1', estimatedDuration: 100, order: 0),
          TaskModel(id: 't2', name: 'Task2', estimatedDuration: 200, order: 1),
        ],
        breaks: const [BreakModel(duration: 50, isEnabled: true)],
        settings: RoutineSettingsModel(
          startTime: 5000,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 45,
        ),
        currentTaskIndex: 1,
        isRunning: true,
      );

      final json = state.toJson();
      expect(json, isA<String>());

      final decoded = RoutineStateModel.fromJson(json);
      expect(decoded.tasks.length, 2);
      expect(decoded.tasks[0].name, 'Task1');
      expect(decoded.tasks[1].name, 'Task2');
      expect(decoded.breaks!.length, 1);
      expect(decoded.breaks![0].duration, 50);
      expect(decoded.settings.startTime, 5000);
      expect(decoded.settings.defaultBreakDuration, 45);
      expect(decoded.currentTaskIndex, 1);
      expect(decoded.isRunning, true);
    });
  });
}
