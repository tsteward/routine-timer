import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('RoutineEvent', () {
    group('LoadSampleRoutine', () {
      test('supports value equality', () {
        expect(
          const LoadSampleRoutine(),
          equals(const LoadSampleRoutine()),
        );
      });

      test('props are empty', () {
        expect(const LoadSampleRoutine().props, isEmpty);
      });
    });

    group('SelectTask', () {
      test('supports value equality', () {
        expect(
          const SelectTask(1),
          equals(const SelectTask(1)),
        );
      });

      test('different indices are not equal', () {
        expect(
          const SelectTask(1),
          isNot(equals(const SelectTask(2))),
        );
      });

      test('props contains index', () {
        expect(const SelectTask(3).props, equals([3]));
      });
    });

    group('ReorderTasks', () {
      test('supports value equality', () {
        expect(
          const ReorderTasks(oldIndex: 1, newIndex: 2),
          equals(const ReorderTasks(oldIndex: 1, newIndex: 2)),
        );
      });

      test('different oldIndex are not equal', () {
        expect(
          const ReorderTasks(oldIndex: 1, newIndex: 2),
          isNot(equals(const ReorderTasks(oldIndex: 0, newIndex: 2))),
        );
      });

      test('different newIndex are not equal', () {
        expect(
          const ReorderTasks(oldIndex: 1, newIndex: 2),
          isNot(equals(const ReorderTasks(oldIndex: 1, newIndex: 3))),
        );
      });

      test('props contains oldIndex and newIndex', () {
        expect(
          const ReorderTasks(oldIndex: 5, newIndex: 7).props,
          equals([5, 7]),
        );
      });
    });

    group('ToggleBreakAtIndex', () {
      test('supports value equality', () {
        expect(
          const ToggleBreakAtIndex(2),
          equals(const ToggleBreakAtIndex(2)),
        );
      });

      test('different indices are not equal', () {
        expect(
          const ToggleBreakAtIndex(1),
          isNot(equals(const ToggleBreakAtIndex(2))),
        );
      });

      test('props contains index', () {
        expect(const ToggleBreakAtIndex(4).props, equals([4]));
      });
    });

    group('UpdateSettings', () {
      test('supports value equality', () {
        const settings1 = RoutineSettingsModel(
          startTime: 100,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 300,
        );
        const settings2 = RoutineSettingsModel(
          startTime: 100,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 300,
        );
        expect(
          UpdateSettings(settings1),
          equals(UpdateSettings(settings2)),
        );
      });

      test('different settings are not equal', () {
        const settings1 = RoutineSettingsModel(
          startTime: 100,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 300,
        );
        const settings2 = RoutineSettingsModel(
          startTime: 200,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 600,
        );
        expect(
          UpdateSettings(settings1),
          isNot(equals(UpdateSettings(settings2))),
        );
      });

      test('props contains settings', () {
        const settings = RoutineSettingsModel(
          startTime: 100,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 300,
        );
        expect(const UpdateSettings(settings).props, equals([settings]));
      });
    });

    group('MarkTaskDone', () {
      test('supports value equality', () {
        expect(
          const MarkTaskDone(actualDuration: 60),
          equals(const MarkTaskDone(actualDuration: 60)),
        );
      });

      test('different durations are not equal', () {
        expect(
          const MarkTaskDone(actualDuration: 60),
          isNot(equals(const MarkTaskDone(actualDuration: 120))),
        );
      });

      test('props contains actualDuration', () {
        expect(const MarkTaskDone(actualDuration: 90).props, equals([90]));
      });
    });

    group('GoToPreviousTask', () {
      test('supports value equality', () {
        expect(
          const GoToPreviousTask(),
          equals(const GoToPreviousTask()),
        );
      });

      test('props are empty', () {
        expect(const GoToPreviousTask().props, isEmpty);
      });
    });

    group('UpdateTask', () {
      test('supports value equality', () {
        const task = TaskModel(
          id: '1',
          name: 'Task',
          estimatedDuration: 600,
          order: 0,
        );
        expect(
          const UpdateTask(index: 0, task: task),
          equals(const UpdateTask(index: 0, task: task)),
        );
      });

      test('different indices are not equal', () {
        const task = TaskModel(
          id: '1',
          name: 'Task',
          estimatedDuration: 600,
          order: 0,
        );
        expect(
          const UpdateTask(index: 0, task: task),
          isNot(equals(const UpdateTask(index: 1, task: task))),
        );
      });

      test('different tasks are not equal', () {
        const task1 = TaskModel(
          id: '1',
          name: 'Task',
          estimatedDuration: 600,
          order: 0,
        );
        const task2 = TaskModel(
          id: '2',
          name: 'Other',
          estimatedDuration: 300,
          order: 1,
        );
        expect(
          const UpdateTask(index: 0, task: task1),
          isNot(equals(const UpdateTask(index: 0, task: task2))),
        );
      });

      test('props contains index and task', () {
        const task = TaskModel(
          id: '1',
          name: 'Task',
          estimatedDuration: 600,
          order: 0,
        );
        expect(const UpdateTask(index: 2, task: task).props, equals([2, task]));
      });
    });

    group('DuplicateTask', () {
      test('supports value equality', () {
        expect(
          const DuplicateTask(1),
          equals(const DuplicateTask(1)),
        );
      });

      test('different indices are not equal', () {
        expect(
          const DuplicateTask(1),
          isNot(equals(const DuplicateTask(2))),
        );
      });

      test('props contains index', () {
        expect(const DuplicateTask(3).props, equals([3]));
      });
    });

    group('DeleteTask', () {
      test('supports value equality', () {
        expect(
          const DeleteTask(1),
          equals(const DeleteTask(1)),
        );
      });

      test('different indices are not equal', () {
        expect(
          const DeleteTask(1),
          isNot(equals(const DeleteTask(2))),
        );
      });

      test('props contains index', () {
        expect(const DeleteTask(5).props, equals([5]));
      });
    });

    group('AddTask', () {
      test('supports value equality', () {
        expect(
          const AddTask(name: 'Task', durationSeconds: 600),
          equals(const AddTask(name: 'Task', durationSeconds: 600)),
        );
      });

      test('different names are not equal', () {
        expect(
          const AddTask(name: 'Task1', durationSeconds: 600),
          isNot(equals(const AddTask(name: 'Task2', durationSeconds: 600))),
        );
      });

      test('different durations are not equal', () {
        expect(
          const AddTask(name: 'Task', durationSeconds: 600),
          isNot(equals(const AddTask(name: 'Task', durationSeconds: 300))),
        );
      });

      test('props contains name and durationSeconds', () {
        expect(
          const AddTask(name: 'MyTask', durationSeconds: 900).props,
          equals(['MyTask', 900]),
        );
      });
    });

    group('UpdateBreakDuration', () {
      test('supports value equality', () {
        expect(
          const UpdateBreakDuration(index: 1, duration: 300),
          equals(const UpdateBreakDuration(index: 1, duration: 300)),
        );
      });

      test('different indices are not equal', () {
        expect(
          const UpdateBreakDuration(index: 1, duration: 300),
          isNot(equals(const UpdateBreakDuration(index: 2, duration: 300))),
        );
      });

      test('different durations are not equal', () {
        expect(
          const UpdateBreakDuration(index: 1, duration: 300),
          isNot(equals(const UpdateBreakDuration(index: 1, duration: 600))),
        );
      });

      test('props contains index and duration', () {
        expect(
          const UpdateBreakDuration(index: 2, duration: 450).props,
          equals([2, 450]),
        );
      });
    });

    group('ResetBreakToDefault', () {
      test('supports value equality', () {
        expect(
          const ResetBreakToDefault(index: 1),
          equals(const ResetBreakToDefault(index: 1)),
        );
      });

      test('different indices are not equal', () {
        expect(
          const ResetBreakToDefault(index: 1),
          isNot(equals(const ResetBreakToDefault(index: 2))),
        );
      });

      test('props contains index', () {
        expect(const ResetBreakToDefault(index: 3).props, equals([3]));
      });
    });
  });
}
