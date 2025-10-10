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
        isBreakActive: true,
        activeBreakIndex: 0,
      );
      final map = state.toMap();
      final decoded = RoutineStateModel.fromMap(map);
      expect(decoded.tasks.length, 2);
      expect(decoded.breaks!.length, 1);
      expect(decoded.settings.defaultBreakDuration, 30);
      expect(decoded.currentTaskIndex, 1);
      expect(decoded.isRunning, true);
      expect(decoded.isBreakActive, true);
      expect(decoded.activeBreakIndex, 0);
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
      final updated = state.copyWith(
        currentTaskIndex: 2,
        isRunning: true,
        isBreakActive: true,
        activeBreakIndex: 1,
      );
      expect(updated.currentTaskIndex, 2);
      expect(updated.isRunning, true);
      expect(updated.isBreakActive, true);
      expect(updated.activeBreakIndex, 1);
      expect(updated.tasks.length, 1);
    });

    test('break fields default to false/null', () {
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
      expect(state.isBreakActive, false);
      expect(state.activeBreakIndex, null);
    });

    test('copyWith can clear activeBreakIndex', () {
      final state = RoutineStateModel(
        tasks: const [
          TaskModel(id: '1', name: 'A', estimatedDuration: 60, order: 0),
        ],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 60,
        ),
        activeBreakIndex: 5,
      );

      // Clear activeBreakIndex using clearActiveBreakIndex flag
      final cleared = state.copyWith(clearActiveBreakIndex: true);
      expect(cleared.activeBreakIndex, null);

      // Regular copyWith should preserve existing value
      final preserved = state.copyWith(isRunning: true);
      expect(preserved.activeBreakIndex, 5);
    });
  });
}
