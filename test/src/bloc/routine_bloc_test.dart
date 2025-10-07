import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('RoutineEvent equality and props', () {
    test('LoadSampleRoutine props', () {
      const event1 = LoadSampleRoutine();
      const event2 = LoadSampleRoutine();
      expect(event1.props, event2.props);
      expect(event1, event2);
    });

    test('SelectTask props', () {
      const event1 = SelectTask(1);
      const event2 = SelectTask(1);
      const event3 = SelectTask(2);
      expect(event1.props, [1]);
      expect(event1, event2);
      expect(event1, isNot(event3));
    });

    test('ReorderTasks props', () {
      const event1 = ReorderTasks(oldIndex: 0, newIndex: 2);
      const event2 = ReorderTasks(oldIndex: 0, newIndex: 2);
      const event3 = ReorderTasks(oldIndex: 1, newIndex: 2);
      expect(event1.props, [0, 2]);
      expect(event1, event2);
      expect(event1, isNot(event3));
    });

    test('ToggleBreakAtIndex props', () {
      const event1 = ToggleBreakAtIndex(1);
      const event2 = ToggleBreakAtIndex(1);
      const event3 = ToggleBreakAtIndex(2);
      expect(event1.props, [1]);
      expect(event1, event2);
      expect(event1, isNot(event3));
    });

    test('UpdateSettings props', () {
      const settings1 = RoutineSettingsModel(
        startTime: 10,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 300,
      );
      const settings2 = RoutineSettingsModel(
        startTime: 20,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 600,
      );
      final event1 = UpdateSettings(settings1);
      final event2 = UpdateSettings(settings1);
      final event3 = UpdateSettings(settings2);
      expect(event1.props, [settings1]);
      expect(event1, event2);
      expect(event1, isNot(event3));
    });

    test('MarkTaskDone props', () {
      const event1 = MarkTaskDone(actualDuration: 100);
      const event2 = MarkTaskDone(actualDuration: 100);
      const event3 = MarkTaskDone(actualDuration: 200);
      expect(event1.props, [100]);
      expect(event1, event2);
      expect(event1, isNot(event3));
    });

    test('GoToPreviousTask props', () {
      const event1 = GoToPreviousTask();
      const event2 = GoToPreviousTask();
      expect(event1.props, event2.props);
      expect(event1, event2);
    });

    test('UpdateTask props', () {
      const task1 = TaskModel(
        id: '1',
        name: 'Task 1',
        estimatedDuration: 600,
        order: 0,
      );
      const task2 = TaskModel(
        id: '2',
        name: 'Task 2',
        estimatedDuration: 700,
        order: 1,
      );
      const event1 = UpdateTask(index: 0, task: task1);
      const event2 = UpdateTask(index: 0, task: task1);
      const event3 = UpdateTask(index: 1, task: task2);
      expect(event1.props, [0, task1]);
      expect(event1, event2);
      expect(event1, isNot(event3));
    });

    test('DuplicateTask props', () {
      const event1 = DuplicateTask(1);
      const event2 = DuplicateTask(1);
      const event3 = DuplicateTask(2);
      expect(event1.props, [1]);
      expect(event1, event2);
      expect(event1, isNot(event3));
    });

    test('DeleteTask props', () {
      const event1 = DeleteTask(1);
      const event2 = DeleteTask(1);
      const event3 = DeleteTask(2);
      expect(event1.props, [1]);
      expect(event1, event2);
      expect(event1, isNot(event3));
    });

    test('AddTask props', () {
      const event1 = AddTask(name: 'Task A', durationSeconds: 600);
      const event2 = AddTask(name: 'Task A', durationSeconds: 600);
      const event3 = AddTask(name: 'Task B', durationSeconds: 700);
      expect(event1.props, ['Task A', 600]);
      expect(event1, event2);
      expect(event1, isNot(event3));
    });
  });

  group('RoutineBloc', () {
    test('loads sample routine with 4 tasks', () async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());

      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      expect(loaded.model!.tasks.length, 4);
      expect(loaded.model!.currentTaskIndex, 0);
    });

    test('toggle break flips enabled state', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final initial = await bloc.stream.firstWhere((s) => s.model != null);

      final before = initial.model!.breaks![1].isEnabled;
      bloc.add(const ToggleBreakAtIndex(1));
      final after = await bloc.stream.firstWhere(
        (s) => s.model!.breaks![1].isEnabled != before,
      );
      expect(after.model!.breaks![1].isEnabled, !before);
    });

    test('mark task done completes and advances index', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final initial = await bloc.stream.firstWhere((s) => s.model != null);
      expect(initial.model!.currentTaskIndex, 0);

      bloc.add(const MarkTaskDone(actualDuration: 30));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.currentTaskIndex == 1,
      );
      expect(updated.model!.tasks.first.isCompleted, true);
      expect(updated.model!.tasks.first.actualDuration, 30);
    });

    test('select task updates currentTaskIndex', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);
      bloc.add(const SelectTask(2));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.currentTaskIndex == 2,
      );
      expect(updated.model!.currentTaskIndex, 2);
    });

    test('reorder tasks moves item and reindexes order', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final beforeFirst = loaded.model!.tasks.first.id;

      bloc.add(const ReorderTasks(oldIndex: 0, newIndex: 2));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks[2].id == beforeFirst,
      );

      expect(updated.model!.tasks[2].id, beforeFirst);
      // Ensure orders are 0..n-1
      final orders = updated.model!.tasks.map((t) => t.order).toList();
      expect(orders, [0, 1, 2, 3]);
    });

    test('previous task goes back safely', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);
      bloc.add(const SelectTask(1));
      await bloc.stream.firstWhere((s) => s.model!.currentTaskIndex == 1);

      bloc.add(const GoToPreviousTask());
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.currentTaskIndex == 0,
      );
      expect(updated.model!.currentTaskIndex, 0);
    });

    test('update settings replaces settings', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);
      final newSettings = RoutineSettingsModel(
        startTime: 42,
        breaksEnabledByDefault: false,
        defaultBreakDuration: 99,
      );
      bloc.add(UpdateSettings(newSettings));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.settings.startTime == 42,
      );
      expect(updated.model!.settings.defaultBreakDuration, 99);
      expect(updated.model!.settings.breaksEnabledByDefault, false);
    });

    test('reorder tasks handles edge cases correctly', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Test moving last item to first position
      final lastTaskId = loaded.model!.tasks.last.id;
      bloc.add(const ReorderTasks(oldIndex: 3, newIndex: 0));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.first.id == lastTaskId,
      );

      expect(updated.model!.tasks.first.id, lastTaskId);
      expect(updated.model!.tasks.first.order, 0);

      // Verify all orders are sequential
      final orders = updated.model!.tasks.map((t) => t.order).toList();
      expect(orders, [0, 1, 2, 3]);
    });

    test('reorder tasks handles same position (no-op)', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalTasks = loaded.model!.tasks;

      // Move item to same position
      bloc.add(const ReorderTasks(oldIndex: 1, newIndex: 1));
      await Future.delayed(
        const Duration(milliseconds: 10),
      ); // Allow state to update

      final updated = bloc.state.model!.tasks;

      // Tasks should remain in same order
      for (int i = 0; i < originalTasks.length; i++) {
        expect(updated[i].id, originalTasks[i].id);
        expect(updated[i].order, i);
      }
    });

    test('select task handles out of bounds index safely', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Try to select index beyond task list
      bloc.add(const SelectTask(10));
      await Future.delayed(const Duration(milliseconds: 10));

      // Should update to the invalid index (bloc doesn't validate bounds)
      expect(bloc.state.model!.currentTaskIndex, 10);
    });

    test('reorder preserves task properties except order', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalTask = loaded.model!.tasks[0];

      // Move first task to last position
      bloc.add(const ReorderTasks(oldIndex: 0, newIndex: 3));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.last.id == originalTask.id,
      );

      final movedTask = updated.model!.tasks.last;

      // All properties should be preserved except order
      expect(movedTask.id, originalTask.id);
      expect(movedTask.name, originalTask.name);
      expect(movedTask.estimatedDuration, originalTask.estimatedDuration);
      expect(movedTask.actualDuration, originalTask.actualDuration);
      expect(movedTask.isCompleted, originalTask.isCompleted);
      expect(movedTask.order, 3); // Only order should change
    });

    test('multiple reorders maintain consistency', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Perform multiple reorders
      bloc.add(const ReorderTasks(oldIndex: 0, newIndex: 2));
      await bloc.stream.firstWhere((s) => s.model!.tasks[2].order == 2);

      bloc.add(const ReorderTasks(oldIndex: 2, newIndex: 1));
      await bloc.stream.firstWhere((s) => s.model!.tasks[1].order == 1);

      bloc.add(const ReorderTasks(oldIndex: 1, newIndex: 3));
      final finalState = await bloc.stream.firstWhere(
        (s) => s.model!.tasks[3].order == 3,
      );

      // Verify final order values are still sequential
      final orders = finalState.model!.tasks.map((t) => t.order).toList();
      expect(orders, [0, 1, 2, 3]);

      // Verify no duplicate orders
      final uniqueOrders = orders.toSet();
      expect(uniqueOrders.length, orders.length);
    });

    test('update task modifies task at index', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalTask = loaded.model!.tasks[0];

      final updatedTask = originalTask.copyWith(
        name: 'Updated Task Name',
        estimatedDuration: 1800, // 30 minutes
      );

      bloc.add(UpdateTask(index: 0, task: updatedTask));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks[0].name == 'Updated Task Name',
      );

      expect(updated.model!.tasks[0].name, 'Updated Task Name');
      expect(updated.model!.tasks[0].estimatedDuration, 1800);
      expect(updated.model!.tasks[0].id, originalTask.id);
    });

    test('update task validates index bounds', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final tasksBefore = loaded.model!.tasks;

      // Try to update task at invalid index
      final invalidTask = TaskModel(
        id: 'invalid',
        name: 'Invalid',
        estimatedDuration: 600,
        order: 99,
      );

      bloc.add(UpdateTask(index: 10, task: invalidTask));
      await Future.delayed(const Duration(milliseconds: 10));

      // Tasks should remain unchanged
      expect(bloc.state.model!.tasks.length, tasksBefore.length);
      expect(bloc.state.model!.tasks[0].id, tasksBefore[0].id);
    });

    test('duplicate task creates copy at next index', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalTaskCount = loaded.model!.tasks.length;
      final taskToDuplicate = loaded.model!.tasks[1];

      bloc.add(const DuplicateTask(1));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == originalTaskCount + 1,
      );

      expect(updated.model!.tasks.length, originalTaskCount + 1);
      expect(updated.model!.tasks[2].name, taskToDuplicate.name);
      expect(
        updated.model!.tasks[2].estimatedDuration,
        taskToDuplicate.estimatedDuration,
      );
      expect(updated.model!.tasks[2].id, isNot(taskToDuplicate.id));
      expect(updated.model!.tasks[2].order, 2);
    });

    test('duplicate task also duplicates corresponding break', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalBreakCount = loaded.model!.breaks!.length;
      final breakToDuplicate = loaded.model!.breaks![1];

      bloc.add(const DuplicateTask(1));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.breaks!.length == originalBreakCount + 1,
      );

      expect(updated.model!.breaks!.length, originalBreakCount + 1);
      expect(updated.model!.breaks![2].duration, breakToDuplicate.duration);
      expect(updated.model!.breaks![2].isEnabled, breakToDuplicate.isEnabled);
    });

    test('duplicate task reindexes all tasks correctly', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      bloc.add(const DuplicateTask(1));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == 5,
      );

      // Verify all orders are sequential
      final orders = updated.model!.tasks.map((t) => t.order).toList();
      expect(orders, [0, 1, 2, 3, 4]);
    });

    test('delete task removes task at index', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalTaskCount = loaded.model!.tasks.length;
      final taskToDeleteId = loaded.model!.tasks[1].id;

      bloc.add(const DeleteTask(1));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == originalTaskCount - 1,
      );

      expect(updated.model!.tasks.length, originalTaskCount - 1);
      expect(
        updated.model!.tasks.where((t) => t.id == taskToDeleteId).isEmpty,
        true,
      );
    });

    test('delete task removes corresponding break', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalBreakCount = loaded.model!.breaks!.length;

      bloc.add(const DeleteTask(1));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.breaks!.length == originalBreakCount - 1,
      );

      expect(updated.model!.breaks!.length, originalBreakCount - 1);
    });

    test('delete task reindexes remaining tasks', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      bloc.add(const DeleteTask(1));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == 3,
      );

      // Verify all orders are sequential
      final orders = updated.model!.tasks.map((t) => t.order).toList();
      expect(orders, [0, 1, 2]);
    });

    test('delete task prevents deleting last task', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Delete tasks until only one remains
      bloc.add(const DeleteTask(3));
      await bloc.stream.firstWhere((s) => s.model!.tasks.length == 3);
      bloc.add(const DeleteTask(2));
      await bloc.stream.firstWhere((s) => s.model!.tasks.length == 2);
      bloc.add(const DeleteTask(1));
      final oneTaskLeft = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == 1,
      );

      // Try to delete the last task
      bloc.add(const DeleteTask(0));
      await Future.delayed(const Duration(milliseconds: 10));

      // Should still have 1 task
      expect(bloc.state.model!.tasks.length, 1);
      expect(bloc.state.model!.tasks[0].id, oneTaskLeft.model!.tasks[0].id);
    });

    test('delete task adjusts currentTaskIndex when needed', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Select last task
      bloc.add(const SelectTask(3));
      await bloc.stream.firstWhere((s) => s.model!.currentTaskIndex == 3);

      // Delete the last task
      bloc.add(const DeleteTask(3));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.currentTaskIndex == 2,
      );

      // Current index should adjust to remain valid
      expect(updated.model!.currentTaskIndex, 2);
      expect(updated.model!.tasks.length, 3);
    });

    test(
      'delete task adjusts currentTaskIndex when deleting before current',
      () async {
        final bloc = RoutineBloc()..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Select task at index 2
        bloc.add(const SelectTask(2));
        await bloc.stream.firstWhere((s) => s.model!.currentTaskIndex == 2);

        // Delete task at index 0 (before current)
        bloc.add(const DeleteTask(0));
        final updated = await bloc.stream.firstWhere(
          (s) => s.model!.currentTaskIndex == 1,
        );

        // Current index should decrement
        expect(updated.model!.currentTaskIndex, 1);
      },
    );

    test('delete task handles edge case of out of bounds index', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final taskCount = loaded.model!.tasks.length;

      // Try to delete at invalid index
      bloc.add(const DeleteTask(10));
      await Future.delayed(const Duration(milliseconds: 10));

      // Should remain unchanged
      expect(bloc.state.model!.tasks.length, taskCount);
    });

    test('add task appends new task to the end of the list', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final initialCount = loaded.model!.tasks.length;

      bloc.add(const AddTask(name: 'New Task', durationSeconds: 600));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length > initialCount,
      );

      expect(updated.model!.tasks.length, initialCount + 1);
      expect(updated.model!.tasks.last.name, 'New Task');
      expect(updated.model!.tasks.last.estimatedDuration, 600);
      expect(updated.model!.tasks.last.order, initialCount);
    });

    test('add task creates new break when breaks exist', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final initialBreaksCount = loaded.model!.breaks!.length;

      bloc.add(const AddTask(name: 'Another Task', durationSeconds: 300));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.breaks!.length > initialBreaksCount,
      );

      expect(updated.model!.breaks!.length, initialBreaksCount + 1);
      final newBreak = updated.model!.breaks!.last;
      expect(newBreak.duration, updated.model!.settings.defaultBreakDuration);
      expect(
        newBreak.isEnabled,
        updated.model!.settings.breaksEnabledByDefault,
      );
    });

    test('add task assigns unique id to new task', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      bloc.add(const AddTask(name: 'Task 1', durationSeconds: 100));
      final first = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.any((t) => t.name == 'Task 1'),
      );

      bloc.add(const AddTask(name: 'Task 2', durationSeconds: 200));
      final second = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.any((t) => t.name == 'Task 2'),
      );

      final task1 = first.model!.tasks.firstWhere((t) => t.name == 'Task 1');
      final task2 = second.model!.tasks.firstWhere((t) => t.name == 'Task 2');

      expect(task1.id != task2.id, true);
    });

    test('add multiple tasks in sequence', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final initialCount = loaded.model!.tasks.length;

      bloc.add(const AddTask(name: 'Task A', durationSeconds: 100));
      await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == initialCount + 1,
      );

      bloc.add(const AddTask(name: 'Task B', durationSeconds: 200));
      await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == initialCount + 2,
      );

      bloc.add(const AddTask(name: 'Task C', durationSeconds: 300));
      final finalState = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == initialCount + 3,
      );

      expect(finalState.model!.tasks.length, initialCount + 3);
      expect(finalState.model!.tasks[initialCount].name, 'Task A');
      expect(finalState.model!.tasks[initialCount + 1].name, 'Task B');
      expect(finalState.model!.tasks[initialCount + 2].name, 'Task C');

      // Verify all orders are sequential
      final orders = finalState.model!.tasks.map((t) => t.order).toList();
      expect(orders, List.generate(initialCount + 3, (i) => i));
    });

    test('add task initializes with correct defaults', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      bloc.add(const AddTask(name: 'Test Task', durationSeconds: 500));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.any((t) => t.name == 'Test Task'),
      );

      final newTask = updated.model!.tasks.firstWhere(
        (t) => t.name == 'Test Task',
      );

      expect(newTask.isCompleted, false);
      expect(newTask.actualDuration, null);
    });
  });
}
