import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';

void main() {
  group('Task Start Time Calculations', () {
    test('calculates start times correctly with no breaks', () {
      final startTime = DateTime(2024, 1, 1, 8, 0); // 8:00 AM

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ), // 10 min
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 900,
          order: 1,
        ), // 15 min
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 300,
          order: 2,
        ), // 5 min
      ];

      final settings = RoutineSettingsModel(
        startTime: startTime.millisecondsSinceEpoch,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 120, // 2 min
      );

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: null, // No breaks
        settings: settings,
        currentTaskIndex: 0,
        isRunning: false,
      );

      final startTimes = _computeTaskStartTimes(model);

      expect(startTimes.length, 3);
      expect(startTimes[0], startTime); // 8:00 AM
      expect(
        startTimes[1],
        startTime.add(const Duration(minutes: 10)),
      ); // 8:10 AM
      expect(
        startTimes[2],
        startTime.add(const Duration(minutes: 25)),
      ); // 8:25 AM
    });

    test('calculates start times correctly with all breaks enabled', () {
      final startTime = DateTime(2024, 1, 1, 8, 0); // 8:00 AM

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ), // 10 min
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 900,
          order: 1,
        ), // 15 min
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 300,
          order: 2,
        ), // 5 min
      ];

      final breaks = [
        const BreakModel(
          duration: 120,
          isEnabled: true,
        ), // 2 min break after task 1
        const BreakModel(
          duration: 180,
          isEnabled: true,
        ), // 3 min break after task 2
      ];

      final settings = RoutineSettingsModel(
        startTime: startTime.millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
        isRunning: false,
      );

      final startTimes = _computeTaskStartTimes(model);

      expect(startTimes.length, 3);
      expect(startTimes[0], startTime); // 8:00 AM
      expect(
        startTimes[1],
        startTime.add(const Duration(minutes: 12)),
      ); // 8:12 AM (10 min + 2 min break)
      expect(
        startTimes[2],
        startTime.add(const Duration(minutes: 30)),
      ); // 8:30 AM (10 + 2 + 15 + 3)
    });

    test('calculates start times correctly with some breaks disabled', () {
      final startTime = DateTime(2024, 1, 1, 8, 0); // 8:00 AM

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ), // 10 min
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 900,
          order: 1,
        ), // 15 min
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 300,
          order: 2,
        ), // 5 min
      ];

      final breaks = [
        const BreakModel(
          duration: 120,
          isEnabled: false,
        ), // Disabled break after task 1
        const BreakModel(
          duration: 180,
          isEnabled: true,
        ), // 3 min break after task 2
      ];

      final settings = RoutineSettingsModel(
        startTime: startTime.millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
        isRunning: false,
      );

      final startTimes = _computeTaskStartTimes(model);

      expect(startTimes.length, 3);
      expect(startTimes[0], startTime); // 8:00 AM
      expect(
        startTimes[1],
        startTime.add(const Duration(minutes: 10)),
      ); // 8:10 AM (no break)
      expect(
        startTimes[2],
        startTime.add(const Duration(minutes: 28)),
      ); // 8:28 AM (10 + 15 + 3)
    });

    test('handles empty task list', () {
      final startTime = DateTime(2024, 1, 1, 8, 0);

      final settings = RoutineSettingsModel(
        startTime: startTime.millisecondsSinceEpoch,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: [],
        breaks: null,
        settings: settings,
        currentTaskIndex: 0,
        isRunning: false,
      );

      final startTimes = _computeTaskStartTimes(model);

      expect(startTimes, isEmpty);
    });

    test('handles single task', () {
      final startTime = DateTime(2024, 1, 1, 8, 0);

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: startTime.millisecondsSinceEpoch,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: null,
        settings: settings,
        currentTaskIndex: 0,
        isRunning: false,
      );

      final startTimes = _computeTaskStartTimes(model);

      expect(startTimes.length, 1);
      expect(startTimes[0], startTime);
    });

    test('handles more breaks than tasks', () {
      final startTime = DateTime(2024, 1, 1, 8, 0);

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 900,
          order: 1,
        ),
      ];

      final breaks = [
        const BreakModel(duration: 120, isEnabled: true),
        const BreakModel(duration: 180, isEnabled: true),
        const BreakModel(
          duration: 240,
          isEnabled: true,
        ), // Extra break (should be ignored)
      ];

      final settings = RoutineSettingsModel(
        startTime: startTime.millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
        isRunning: false,
      );

      final startTimes = _computeTaskStartTimes(model);

      expect(startTimes.length, 2);
      expect(startTimes[0], startTime); // 8:00 AM
      expect(
        startTimes[1],
        startTime.add(const Duration(minutes: 12)),
      ); // 8:12 AM (10 + 2)
    });
  });

  group('Time Formatting', () {
    test('formats time correctly in HH:MM format', () {
      expect(_formatTimeHHmm(DateTime(2024, 1, 1, 8, 0)), '08:00');
      expect(_formatTimeHHmm(DateTime(2024, 1, 1, 14, 30)), '14:30');
      expect(_formatTimeHHmm(DateTime(2024, 1, 1, 9, 5)), '09:05');
      expect(_formatTimeHHmm(DateTime(2024, 1, 1, 23, 59)), '23:59');
    });

    test('formats duration correctly in minutes', () {
      expect(_formatDurationMinutes(60), '1 min');
      expect(_formatDurationMinutes(120), '2 min');
      expect(_formatDurationMinutes(90), '2 min'); // Rounds up
      expect(_formatDurationMinutes(30), '1 min'); // Rounds up
      expect(_formatDurationMinutes(600), '10 min');
      expect(_formatDurationMinutes(0), '0 min');
    });
  });
}

// Copy of the private methods from TaskManagementScreen for testing
List<DateTime> _computeTaskStartTimes(RoutineStateModel model) {
  final start = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
  final results = <DateTime>[];
  int accumulatedSeconds = 0;

  for (var i = 0; i < model.tasks.length; i++) {
    results.add(start.add(Duration(seconds: accumulatedSeconds)));
    // Add this task's duration to accumulate for the next index
    accumulatedSeconds += model.tasks[i].estimatedDuration;
    // If there is a break after this task (i < breaks.length), and it is enabled, include it
    if (model.breaks != null && i < (model.breaks!.length)) {
      final breakModel = model.breaks![i];
      if (breakModel.isEnabled) {
        accumulatedSeconds += breakModel.duration;
      }
    }
  }
  return results;
}

String _formatTimeHHmm(DateTime time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String _formatDurationMinutes(int seconds) {
  final minutes = (seconds / 60).round();
  return '$minutes min';
}
