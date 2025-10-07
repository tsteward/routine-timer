import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('RoutineEvent', () {
    group('LoadSampleRoutine', () {
      test('creates instance', () {
        const event = LoadSampleRoutine();
        expect(event, isA<RoutineEvent>());
      });

      test('props are empty', () {
        const event = LoadSampleRoutine();
        expect(event.props, isEmpty);
      });

      test('equality works correctly', () {
        const event1 = LoadSampleRoutine();
        const event2 = LoadSampleRoutine();
        expect(event1, equals(event2));
      });
    });

    group('SelectTask', () {
      test('creates instance with index', () {
        const event = SelectTask(2);
        expect(event.index, equals(2));
      });

      test('props includes index', () {
        const event = SelectTask(3);
        expect(event.props, equals([3]));
      });

      test('equality works correctly for same index', () {
        const event1 = SelectTask(1);
        const event2 = SelectTask(1);
        expect(event1, equals(event2));
      });

      test('inequality works correctly for different index', () {
        const event1 = SelectTask(1);
        const event2 = SelectTask(2);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('ReorderTasks', () {
      test('creates instance with oldIndex and newIndex', () {
        const event = ReorderTasks(oldIndex: 0, newIndex: 2);
        expect(event.oldIndex, equals(0));
        expect(event.newIndex, equals(2));
      });

      test('props includes oldIndex and newIndex', () {
        const event = ReorderTasks(oldIndex: 1, newIndex: 3);
        expect(event.props, equals([1, 3]));
      });

      test('equality works correctly for same indices', () {
        const event1 = ReorderTasks(oldIndex: 0, newIndex: 2);
        const event2 = ReorderTasks(oldIndex: 0, newIndex: 2);
        expect(event1, equals(event2));
      });

      test('inequality works correctly for different indices', () {
        const event1 = ReorderTasks(oldIndex: 0, newIndex: 2);
        const event2 = ReorderTasks(oldIndex: 1, newIndex: 2);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('ToggleBreakAtIndex', () {
      test('creates instance with index', () {
        const event = ToggleBreakAtIndex(1);
        expect(event.index, equals(1));
      });

      test('props includes index', () {
        const event = ToggleBreakAtIndex(2);
        expect(event.props, equals([2]));
      });

      test('equality works correctly', () {
        const event1 = ToggleBreakAtIndex(1);
        const event2 = ToggleBreakAtIndex(1);
        expect(event1, equals(event2));
      });

      test('inequality works correctly', () {
        const event1 = ToggleBreakAtIndex(1);
        const event2 = ToggleBreakAtIndex(2);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('UpdateSettings', () {
      test('creates instance with settings', () {
        const settings = RoutineSettingsModel(
          startTime: 100,
          defaultBreakDuration: 60,
        );
        const event = UpdateSettings(settings);
        expect(event.settings, equals(settings));
      });

      test('props includes settings', () {
        const settings = RoutineSettingsModel(
          startTime: 200,
          defaultBreakDuration: 120,
        );
        const event = UpdateSettings(settings);
        expect(event.props, equals([settings]));
      });

      test('equality works correctly for same settings', () {
        const settings = RoutineSettingsModel(
          startTime: 100,
          defaultBreakDuration: 60,
        );
        const event1 = UpdateSettings(settings);
        const event2 = UpdateSettings(settings);
        expect(event1, equals(event2));
      });
    });

    group('MarkTaskDone', () {
      test('creates instance with actualDuration', () {
        const event = MarkTaskDone(actualDuration: 300);
        expect(event.actualDuration, equals(300));
      });

      test('props includes actualDuration', () {
        const event = MarkTaskDone(actualDuration: 450);
        expect(event.props, equals([450]));
      });

      test('equality works correctly', () {
        const event1 = MarkTaskDone(actualDuration: 300);
        const event2 = MarkTaskDone(actualDuration: 300);
        expect(event1, equals(event2));
      });

      test('inequality works correctly', () {
        const event1 = MarkTaskDone(actualDuration: 300);
        const event2 = MarkTaskDone(actualDuration: 400);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('GoToPreviousTask', () {
      test('creates instance', () {
        const event = GoToPreviousTask();
        expect(event, isA<RoutineEvent>());
      });

      test('props are empty', () {
        const event = GoToPreviousTask();
        expect(event.props, isEmpty);
      });

      test('equality works correctly', () {
        const event1 = GoToPreviousTask();
        const event2 = GoToPreviousTask();
        expect(event1, equals(event2));
      });
    });

    group('UpdateTask', () {
      test('creates instance with index and task', () {
        const task = TaskModel(
          id: 't1',
          name: 'Test',
          estimatedDuration: 600,
          order: 0,
        );
        const event = UpdateTask(index: 1, task: task);
        expect(event.index, equals(1));
        expect(event.task, equals(task));
      });

      test('props includes index and task', () {
        const task = TaskModel(
          id: 't2',
          name: 'Task',
          estimatedDuration: 300,
          order: 1,
        );
        const event = UpdateTask(index: 2, task: task);
        expect(event.props, equals([2, task]));
      });

      test('equality works correctly for same index and task', () {
        const task = TaskModel(
          id: 't1',
          name: 'Test',
          estimatedDuration: 600,
          order: 0,
        );
        const event1 = UpdateTask(index: 1, task: task);
        const event2 = UpdateTask(index: 1, task: task);
        expect(event1, equals(event2));
      });

      test('inequality works correctly for different index', () {
        const task = TaskModel(
          id: 't1',
          name: 'Test',
          estimatedDuration: 600,
          order: 0,
        );
        const event1 = UpdateTask(index: 1, task: task);
        const event2 = UpdateTask(index: 2, task: task);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('DuplicateTask', () {
      test('creates instance with index', () {
        const event = DuplicateTask(2);
        expect(event.index, equals(2));
      });

      test('props includes index', () {
        const event = DuplicateTask(1);
        expect(event.props, equals([1]));
      });

      test('equality works correctly', () {
        const event1 = DuplicateTask(1);
        const event2 = DuplicateTask(1);
        expect(event1, equals(event2));
      });

      test('inequality works correctly', () {
        const event1 = DuplicateTask(1);
        const event2 = DuplicateTask(2);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('DeleteTask', () {
      test('creates instance with index', () {
        const event = DeleteTask(3);
        expect(event.index, equals(3));
      });

      test('props includes index', () {
        const event = DeleteTask(2);
        expect(event.props, equals([2]));
      });

      test('equality works correctly', () {
        const event1 = DeleteTask(1);
        const event2 = DeleteTask(1);
        expect(event1, equals(event2));
      });

      test('inequality works correctly', () {
        const event1 = DeleteTask(1);
        const event2 = DeleteTask(2);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('AddTask', () {
      test('creates instance with name and duration', () {
        const event = AddTask(name: 'New Task', durationSeconds: 600);
        expect(event.name, equals('New Task'));
        expect(event.durationSeconds, equals(600));
      });

      test('props includes name and duration', () {
        const event = AddTask(name: 'Task', durationSeconds: 300);
        expect(event.props, equals(['Task', 300]));
      });

      test('equality works correctly for same values', () {
        const event1 = AddTask(name: 'Task', durationSeconds: 600);
        const event2 = AddTask(name: 'Task', durationSeconds: 600);
        expect(event1, equals(event2));
      });

      test('inequality works correctly for different name', () {
        const event1 = AddTask(name: 'Task A', durationSeconds: 600);
        const event2 = AddTask(name: 'Task B', durationSeconds: 600);
        expect(event1, isNot(equals(event2)));
      });

      test('inequality works correctly for different duration', () {
        const event1 = AddTask(name: 'Task', durationSeconds: 600);
        const event2 = AddTask(name: 'Task', durationSeconds: 300);
        expect(event1, isNot(equals(event2)));
      });
    });
  });
}
