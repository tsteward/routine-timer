import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('AddTask Event', () {
    test('adds task to end of list', () async {
      final bloc = RoutineBloc();

      // Load initial sample data
      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      final initialTaskCount = bloc.state.model!.tasks.length;

      // Add a new task
      bloc.add(const AddTask(name: 'New Task', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model!.tasks.length, initialTaskCount + 1);
      expect(bloc.state.model!.tasks.last.name, 'New Task');
      expect(bloc.state.model!.tasks.last.estimatedDuration, 600);

      bloc.close();
    });

    test('assigns correct order to new task', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      final initialTaskCount = bloc.state.model!.tasks.length;

      bloc.add(const AddTask(name: 'New Task', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model!.tasks.last.order, initialTaskCount);

      bloc.close();
    });

    test('generates unique ID for new task', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const AddTask(name: 'Task 1', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);

      final id1 = bloc.state.model!.tasks.last.id;

      // Add a small delay to ensure different timestamp
      await Future<void>.delayed(const Duration(milliseconds: 2));

      // Add another task
      bloc.add(const AddTask(name: 'Task 2', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);

      final id2 = bloc.state.model!.tasks.last.id;

      expect(id1, isNot(equals(id2)));

      bloc.close();
    });

    test('adds break after new task with default settings', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      final initialBreakCount = bloc.state.model!.breaks!.length;
      final defaultBreakDuration =
          bloc.state.model!.settings.defaultBreakDuration;
      final breaksEnabledByDefault =
          bloc.state.model!.settings.breaksEnabledByDefault;

      bloc.add(const AddTask(name: 'New Task', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model!.breaks!.length, initialBreakCount + 1);
      expect(bloc.state.model!.breaks!.last.duration, defaultBreakDuration);
      expect(bloc.state.model!.breaks!.last.isEnabled, breaksEnabledByDefault);

      bloc.close();
    });

    test('handles adding task when model is null', () async {
      final bloc = RoutineBloc();

      // Don't load sample data, so model is null
      bloc.add(const AddTask(name: 'New Task', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model, isNull);

      bloc.close();
    });

    test('adds task with various durations', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      // Add task with 5 minutes
      bloc.add(const AddTask(name: 'Short Task', estimatedDuration: 5 * 60));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.model!.tasks.last.estimatedDuration, 5 * 60);

      // Add task with 2 hours
      bloc.add(
        const AddTask(name: 'Long Task', estimatedDuration: 2 * 60 * 60),
      );
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.model!.tasks.last.estimatedDuration, 2 * 60 * 60);

      bloc.close();
    });

    test('adds task with various names', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const AddTask(name: 'Morning Exercise', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.model!.tasks.last.name, 'Morning Exercise');

      bloc.add(const AddTask(name: 'Coffee Break ☕', estimatedDuration: 300));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.model!.tasks.last.name, 'Coffee Break ☕');

      bloc.close();
    });

    test('new task is not completed by default', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const AddTask(name: 'New Task', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model!.tasks.last.isCompleted, false);
      expect(bloc.state.model!.tasks.last.actualDuration, isNull);

      bloc.close();
    });

    test('adding multiple tasks in sequence', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      final initialCount = bloc.state.model!.tasks.length;

      bloc.add(const AddTask(name: 'Task 1', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AddTask(name: 'Task 2', estimatedDuration: 900));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AddTask(name: 'Task 3', estimatedDuration: 1200));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model!.tasks.length, initialCount + 3);
      expect(bloc.state.model!.tasks[initialCount].name, 'Task 1');
      expect(bloc.state.model!.tasks[initialCount + 1].name, 'Task 2');
      expect(bloc.state.model!.tasks[initialCount + 2].name, 'Task 3');

      bloc.close();
    });
  });

  group('Time Calculations', () {
    test('calculates total time with only tasks', () {
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
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 1200,
          order: 2,
        ),
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        ),
      );

      int total = 0;
      for (final task in model.tasks) {
        total += task.estimatedDuration;
      }

      expect(total, 600 + 900 + 1200);
    });

    test('calculates total time with tasks and enabled breaks', () {
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
        const BreakModel(duration: 120, isEnabled: true),
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        ),
      );

      int total = 0;
      for (final task in model.tasks) {
        total += task.estimatedDuration;
      }
      for (final breakItem in model.breaks!) {
        if (breakItem.isEnabled) {
          total += breakItem.duration;
        }
      }

      expect(total, 600 + 900 + 120 + 120);
    });

    test('calculates total time excluding disabled breaks', () {
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
        const BreakModel(duration: 120, isEnabled: false),
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        ),
      );

      int total = 0;
      for (final task in model.tasks) {
        total += task.estimatedDuration;
      }
      for (final breakItem in model.breaks!) {
        if (breakItem.isEnabled) {
          total += breakItem.duration;
        }
      }

      expect(total, 600 + 900 + 120); // Only one break is enabled
    });

    test('calculates finish time correctly', () {
      final startTime = DateTime(2025, 10, 6, 8, 0); // 8:00 AM

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 30 * 60,
          order: 0,
        ), // 30 min
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 45 * 60,
          order: 1,
        ), // 45 min
      ];

      final breaks = [
        const BreakModel(duration: 5 * 60, isEnabled: true), // 5 min
        const BreakModel(duration: 5 * 60, isEnabled: true), // 5 min
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          defaultBreakDuration: 5 * 60,
        ),
      );

      int totalTime = 0;
      for (final task in model.tasks) {
        totalTime += task.estimatedDuration;
      }
      for (final breakItem in model.breaks!) {
        if (breakItem.isEnabled) {
          totalTime += breakItem.duration;
        }
      }

      final finishTime = startTime.add(Duration(seconds: totalTime));

      // 8:00 + 30 min + 5 min + 45 min + 5 min = 9:25
      expect(finishTime.hour, 9);
      expect(finishTime.minute, 25);
    });

    test('handles empty task list', () {
      final model = RoutineStateModel(
        tasks: [],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        ),
      );

      int total = 0;
      for (final task in model.tasks) {
        total += task.estimatedDuration;
      }

      expect(total, 0);
    });

    test('handles null breaks list', () {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        ),
      );

      int total = 0;
      for (final task in model.tasks) {
        total += task.estimatedDuration;
      }
      if (model.breaks != null) {
        for (final breakItem in model.breaks!) {
          if (breakItem.isEnabled) {
            total += breakItem.duration;
          }
        }
      }

      expect(total, 600);
    });
  });

  group('Edge Cases', () {
    test('adding task with zero duration', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const AddTask(name: 'Zero Task', estimatedDuration: 0));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model!.tasks.last.estimatedDuration, 0);

      bloc.close();
    });

    test('adding task with very long duration', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      const veryLongDuration = 24 * 60 * 60; // 24 hours
      bloc.add(
        const AddTask(name: 'Long Task', estimatedDuration: veryLongDuration),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model!.tasks.last.estimatedDuration, veryLongDuration);

      bloc.close();
    });

    test('adding task with empty name', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const AddTask(name: '', estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model!.tasks.last.name, '');

      bloc.close();
    });

    test('adding task with special characters in name', () async {
      final bloc = RoutineBloc();

      bloc.add(const LoadSampleRoutine());
      await Future<void>.delayed(Duration.zero);

      const specialName = '🏃‍♂️ Run & Stretch (15\' max!)';
      bloc.add(const AddTask(name: specialName, estimatedDuration: 600));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.model!.tasks.last.name, specialName);

      bloc.close();
    });
  });
}
