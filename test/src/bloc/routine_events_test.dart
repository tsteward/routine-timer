import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('RoutineEvent', () {
    test('LoadSampleRoutine props are empty', () {
      const event = LoadSampleRoutine();
      expect(event.props, isEmpty);
    });

    test('LoadSampleRoutine instances are equal', () {
      const event1 = LoadSampleRoutine();
      const event2 = LoadSampleRoutine();
      expect(event1, equals(event2));
    });

    test('SelectTask props contain index', () {
      const event = SelectTask(2);
      expect(event.props, [2]);
    });

    test('SelectTask instances are equal with same index', () {
      const event1 = SelectTask(2);
      const event2 = SelectTask(2);
      expect(event1, equals(event2));
    });

    test('SelectTask instances are not equal with different index', () {
      const event1 = SelectTask(2);
      const event2 = SelectTask(3);
      expect(event1, isNot(equals(event2)));
    });

    test('ReorderTasks props contain oldIndex and newIndex', () {
      const event = ReorderTasks(oldIndex: 1, newIndex: 3);
      expect(event.props, [1, 3]);
    });

    test('ReorderTasks instances are equal with same indices', () {
      const event1 = ReorderTasks(oldIndex: 1, newIndex: 3);
      const event2 = ReorderTasks(oldIndex: 1, newIndex: 3);
      expect(event1, equals(event2));
    });

    test('ReorderTasks instances are not equal with different indices', () {
      const event1 = ReorderTasks(oldIndex: 1, newIndex: 3);
      const event2 = ReorderTasks(oldIndex: 2, newIndex: 3);
      expect(event1, isNot(equals(event2)));
    });

    test('ToggleBreakAtIndex props contain index', () {
      const event = ToggleBreakAtIndex(1);
      expect(event.props, [1]);
    });

    test('ToggleBreakAtIndex instances are equal with same index', () {
      const event1 = ToggleBreakAtIndex(1);
      const event2 = ToggleBreakAtIndex(1);
      expect(event1, equals(event2));
    });

    test('ToggleBreakAtIndex instances are not equal with different index', () {
      const event1 = ToggleBreakAtIndex(1);
      const event2 = ToggleBreakAtIndex(2);
      expect(event1, isNot(equals(event2)));
    });

    test('UpdateSettings props contain settings', () {
      const settings = RoutineSettingsModel(
        startTime: 123456789,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 300,
      );
      const event = UpdateSettings(settings);
      expect(event.props, [settings]);
    });

    test('UpdateSettings instances are equal with same settings', () {
      const settings = RoutineSettingsModel(
        startTime: 123456789,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 300,
      );
      const event1 = UpdateSettings(settings);
      const event2 = UpdateSettings(settings);
      expect(event1, equals(event2));
    });

    test('MarkTaskDone props contain actualDuration', () {
      const event = MarkTaskDone(actualDuration: 600);
      expect(event.props, [600]);
    });

    test('MarkTaskDone instances are equal with same duration', () {
      const event1 = MarkTaskDone(actualDuration: 600);
      const event2 = MarkTaskDone(actualDuration: 600);
      expect(event1, equals(event2));
    });

    test('MarkTaskDone instances are not equal with different duration', () {
      const event1 = MarkTaskDone(actualDuration: 600);
      const event2 = MarkTaskDone(actualDuration: 700);
      expect(event1, isNot(equals(event2)));
    });

    test('GoToPreviousTask props are empty', () {
      const event = GoToPreviousTask();
      expect(event.props, isEmpty);
    });

    test('GoToPreviousTask instances are equal', () {
      const event1 = GoToPreviousTask();
      const event2 = GoToPreviousTask();
      expect(event1, equals(event2));
    });

    test('UpdateTask props contain index and task', () {
      const task = TaskModel(
        id: 'task-1',
        name: 'Test Task',
        estimatedDuration: 300,
        order: 0,
      );
      const event = UpdateTask(index: 2, task: task);
      expect(event.props, [2, task]);
    });

    test('UpdateTask instances are equal with same index and task', () {
      const task = TaskModel(
        id: 'task-1',
        name: 'Test Task',
        estimatedDuration: 300,
        order: 0,
      );
      const event1 = UpdateTask(index: 2, task: task);
      const event2 = UpdateTask(index: 2, task: task);
      expect(event1, equals(event2));
    });

    test('UpdateTask instances are not equal with different index', () {
      const task = TaskModel(
        id: 'task-1',
        name: 'Test Task',
        estimatedDuration: 300,
        order: 0,
      );
      const event1 = UpdateTask(index: 2, task: task);
      const event2 = UpdateTask(index: 3, task: task);
      expect(event1, isNot(equals(event2)));
    });

    test('DuplicateTask props contain index', () {
      const event = DuplicateTask(1);
      expect(event.props, [1]);
    });

    test('DuplicateTask instances are equal with same index', () {
      const event1 = DuplicateTask(1);
      const event2 = DuplicateTask(1);
      expect(event1, equals(event2));
    });

    test('DuplicateTask instances are not equal with different index', () {
      const event1 = DuplicateTask(1);
      const event2 = DuplicateTask(2);
      expect(event1, isNot(equals(event2)));
    });

    test('DeleteTask props contain index', () {
      const event = DeleteTask(1);
      expect(event.props, [1]);
    });

    test('DeleteTask instances are equal with same index', () {
      const event1 = DeleteTask(1);
      const event2 = DeleteTask(1);
      expect(event1, equals(event2));
    });

    test('DeleteTask instances are not equal with different index', () {
      const event1 = DeleteTask(1);
      const event2 = DeleteTask(2);
      expect(event1, isNot(equals(event2)));
    });

    test('AddTask props contain name and durationSeconds', () {
      const event = AddTask(name: 'New Task', durationSeconds: 600);
      expect(event.props, ['New Task', 600]);
    });

    test('AddTask instances are equal with same name and duration', () {
      const event1 = AddTask(name: 'New Task', durationSeconds: 600);
      const event2 = AddTask(name: 'New Task', durationSeconds: 600);
      expect(event1, equals(event2));
    });

    test('AddTask instances are not equal with different name', () {
      const event1 = AddTask(name: 'Task A', durationSeconds: 600);
      const event2 = AddTask(name: 'Task B', durationSeconds: 600);
      expect(event1, isNot(equals(event2)));
    });

    test('AddTask instances are not equal with different duration', () {
      const event1 = AddTask(name: 'New Task', durationSeconds: 600);
      const event2 = AddTask(name: 'New Task', durationSeconds: 700);
      expect(event1, isNot(equals(event2)));
    });

    test('UpdateBreakDuration props contain index and duration', () {
      const event = UpdateBreakDuration(index: 1, duration: 300);
      expect(event.props, [1, 300]);
    });

    test('UpdateBreakDuration instances are equal with same values', () {
      const event1 = UpdateBreakDuration(index: 1, duration: 300);
      const event2 = UpdateBreakDuration(index: 1, duration: 300);
      expect(event1, equals(event2));
    });

    test('UpdateBreakDuration instances are not equal with different index', () {
      const event1 = UpdateBreakDuration(index: 1, duration: 300);
      const event2 = UpdateBreakDuration(index: 2, duration: 300);
      expect(event1, isNot(equals(event2)));
    });

    test('UpdateBreakDuration instances are not equal with different duration',
        () {
      const event1 = UpdateBreakDuration(index: 1, duration: 300);
      const event2 = UpdateBreakDuration(index: 1, duration: 400);
      expect(event1, isNot(equals(event2)));
    });

    test('ResetBreakToDefault props contain index', () {
      const event = ResetBreakToDefault(index: 1);
      expect(event.props, [1]);
    });

    test('ResetBreakToDefault instances are equal with same index', () {
      const event1 = ResetBreakToDefault(index: 1);
      const event2 = ResetBreakToDefault(index: 1);
      expect(event1, equals(event2));
    });

    test('ResetBreakToDefault instances are not equal with different index', () {
      const event1 = ResetBreakToDefault(index: 1);
      const event2 = ResetBreakToDefault(index: 2);
      expect(event1, isNot(equals(event2)));
    });

    test('All event types extend RoutineEvent', () {
      expect(const LoadSampleRoutine(), isA<RoutineEvent>());
      expect(const SelectTask(0), isA<RoutineEvent>());
      expect(const ReorderTasks(oldIndex: 0, newIndex: 1), isA<RoutineEvent>());
      expect(const ToggleBreakAtIndex(0), isA<RoutineEvent>());
      expect(
        UpdateSettings(
          const RoutineSettingsModel(
            startTime: 0,
            defaultBreakDuration: 300,
          ),
        ),
        isA<RoutineEvent>(),
      );
      expect(const MarkTaskDone(actualDuration: 0), isA<RoutineEvent>());
      expect(const GoToPreviousTask(), isA<RoutineEvent>());
      expect(
        UpdateTask(
          index: 0,
          task: const TaskModel(
            id: 'id',
            name: 'name',
            estimatedDuration: 0,
            order: 0,
          ),
        ),
        isA<RoutineEvent>(),
      );
      expect(const DuplicateTask(0), isA<RoutineEvent>());
      expect(const DeleteTask(0), isA<RoutineEvent>());
      expect(const AddTask(name: 'name', durationSeconds: 0), isA<RoutineEvent>());
      expect(const UpdateBreakDuration(index: 0, duration: 0), isA<RoutineEvent>());
      expect(const ResetBreakToDefault(index: 0), isA<RoutineEvent>());
    });
  });
}
