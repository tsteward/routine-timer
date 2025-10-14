import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('RoutineBloc', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });
    test('loads sample routine with 4 tasks', () async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.add(const LoadSampleRoutine());

      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      expect(loaded.model!.tasks.length, 4);
      expect(loaded.model!.currentTaskIndex, 0); // Should still work via getter
      expect(
        loaded.model!.selectedTaskId,
        loaded.model!.tasks.first.id,
      ); // First task selected by default
    });

    test('loads sample routine with default start time at 6am', () async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.add(const LoadSampleRoutine());

      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Verify start time is set to 6am today
      final startTime = DateTime.fromMillisecondsSinceEpoch(
        loaded.model!.settings.startTime,
      );
      final now = DateTime.now();
      final expectedSixAm = DateTime(now.year, now.month, now.day, 6, 0);

      expect(startTime.year, expectedSixAm.year);
      expect(startTime.month, expectedSixAm.month);
      expect(startTime.day, expectedSixAm.day);
      expect(startTime.hour, 6);
      expect(startTime.minute, 0);
    });

    test('toggle break flips enabled state', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final initial = await bloc.stream.firstWhere((s) => s.model != null);

      final before = initial.model!.breaks![1].isEnabled;
      bloc.add(const ToggleBreakAtIndex(1));
      final after = await bloc.stream.firstWhere(
        (s) => s.model!.breaks![1].isEnabled != before,
      );
      expect(after.model!.breaks![1].isEnabled, !before);
    });

    test('mark task done advances when first break is disabled', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final initial = await bloc.stream.firstWhere((s) => s.model != null);
      expect(initial.model!.currentTaskIndex, 0);

      // Disable the first break so completion advances to the next task
      bloc.add(const ToggleBreakAtIndex(0));
      await bloc.stream.firstWhere(
        (s) => s.model!.breaks![0].isEnabled == false,
      );

      bloc.add(const MarkTaskDone(actualDuration: 30));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.currentTaskIndex == 1,
      );
      expect(updated.model!.tasks.first.isCompleted, true);
      expect(updated.model!.tasks.first.actualDuration, 30);
    });

    test('select task updates selection by ID', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final taskToSelect = loaded.model!.tasks[2];

      bloc.add(SelectTask(taskToSelect.id));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.selectedTaskId == taskToSelect.id,
      );
      expect(updated.model!.currentTaskIndex, 2);
      expect(updated.model!.selectedTask?.id, taskToSelect.id);
    });

    test('reorder tasks moves item and reindexes order', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final taskAtIndex1 = loaded.model!.tasks[1];

      bloc.add(SelectTask(taskAtIndex1.id));
      await bloc.stream.firstWhere((s) => s.model!.currentTaskIndex == 1);

      bloc.add(const GoToPreviousTask());
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.currentTaskIndex == 0,
      );
      expect(updated.model!.currentTaskIndex, 0);
    });

    test('update settings replaces settings', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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

    test('select task handles non-existent task ID safely', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalSelectedId = loaded.model!.selectedTaskId;

      // Try to select task with non-existent ID
      bloc.add(const SelectTask('non-existent-task-id'));
      await Future.delayed(const Duration(milliseconds: 10));

      // Selection should remain unchanged since task doesn't exist
      expect(bloc.state.model!.selectedTaskId, originalSelectedId);
    });

    test('reorder preserves task properties except order', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalBreakCount = loaded.model!.breaks!.length;

      bloc.add(const DeleteTask(1));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.breaks!.length == originalBreakCount - 1,
      );

      expect(updated.model!.breaks!.length, originalBreakCount - 1);
    });

    test('delete task reindexes remaining tasks', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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

    test('delete task adjusts selection when selected task is deleted', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Select last task
      final lastTask = loaded.model!.tasks[3];
      bloc.add(SelectTask(lastTask.id));
      await bloc.stream.firstWhere((s) => s.model!.currentTaskIndex == 3);

      // Delete the last task
      bloc.add(const DeleteTask(3));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.currentTaskIndex == 2,
      );

      // Current index should adjust to remain valid, and a different task should be selected
      expect(updated.model!.currentTaskIndex, 2);
      expect(updated.model!.tasks.length, 3);
      expect(
        updated.model!.selectedTaskId,
        isNot(lastTask.id),
      ); // Different task selected
    });

    test(
      'delete task adjusts currentTaskIndex when deleting before current',
      () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final loaded = await bloc.stream.firstWhere((s) => s.model != null);

        // Select task at index 2
        final taskAtIndex2 = loaded.model!.tasks[2];
        bloc.add(SelectTask(taskAtIndex2.id));
        await bloc.stream.firstWhere((s) => s.model!.currentTaskIndex == 2);

        // Delete task at index 0 (before current)
        bloc.add(const DeleteTask(0));
        final updated = await bloc.stream.firstWhere(
          (s) => s.model!.currentTaskIndex == 1,
        );

        // Current index should decrement (same task, but now at index 1)
        expect(updated.model!.currentTaskIndex, 1);
        expect(updated.model!.selectedTaskId, taskAtIndex2.id);
      },
    );

    test('delete task handles edge case of out of bounds index', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final taskCount = loaded.model!.tasks.length;

      // Try to delete at invalid index
      bloc.add(const DeleteTask(10));
      await Future.delayed(const Duration(milliseconds: 10));

      // Should remain unchanged
      expect(bloc.state.model!.tasks.length, taskCount);
    });

    test('add task appends new task to the end of the list', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
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

    test('update break duration changes duration at index', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalDuration = loaded.model!.breaks![0].duration;

      bloc.add(const UpdateBreakDuration(index: 0, duration: 300));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.breaks![0].duration == 300,
      );

      expect(updated.model!.breaks![0].duration, 300);
      expect(updated.model!.breaks![0].duration, isNot(originalDuration));
    });

    test('update break duration validates index bounds', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalBreaks = loaded.model!.breaks!;

      // Try to update break at invalid index
      bloc.add(const UpdateBreakDuration(index: 10, duration: 300));
      await Future.delayed(const Duration(milliseconds: 10));

      // Breaks should remain unchanged
      expect(bloc.state.model!.breaks!.length, originalBreaks.length);
      for (var i = 0; i < originalBreaks.length; i++) {
        expect(
          bloc.state.model!.breaks![i].duration,
          originalBreaks[i].duration,
        );
      }
    });

    test('update break duration preserves enabled state', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalEnabledState = loaded.model!.breaks![1].isEnabled;

      bloc.add(const UpdateBreakDuration(index: 1, duration: 420));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.breaks![1].duration == 420,
      );

      expect(updated.model!.breaks![1].isEnabled, originalEnabledState);
    });

    test(
      'update break duration updates multiple breaks independently',
      () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Update first break
        bloc.add(const UpdateBreakDuration(index: 0, duration: 180));
        await bloc.stream.firstWhere(
          (s) => s.model!.breaks![0].duration == 180,
        );

        // Update second break
        bloc.add(const UpdateBreakDuration(index: 1, duration: 240));
        final updated = await bloc.stream.firstWhere(
          (s) => s.model!.breaks![1].duration == 240,
        );

        expect(updated.model!.breaks![0].duration, 180);
        expect(updated.model!.breaks![1].duration, 240);
      },
    );

    test('update break duration marks break as customized', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Initially should not be customized
      expect(loaded.model!.breaks![0].isCustomized, false);

      bloc.add(const UpdateBreakDuration(index: 0, duration: 300));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.breaks![0].duration == 300,
      );

      // Should now be marked as customized
      expect(updated.model!.breaks![0].isCustomized, true);
    });

    test(
      'updating default break duration updates non-customized breaks',
      () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Customize one break
        bloc.add(const UpdateBreakDuration(index: 1, duration: 300));
        await bloc.stream.firstWhere(
          (s) => s.model!.breaks![1].isCustomized == true,
        );

        // Update default break duration
        final newSettings = RoutineSettingsModel(
          startTime: bloc.state.model!.settings.startTime,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 180, // 3 minutes
        );

        bloc.add(UpdateSettings(newSettings));
        final updated = await bloc.stream.firstWhere(
          (s) => s.model!.settings.defaultBreakDuration == 180,
        );

        // Non-customized breaks should update to new default
        expect(updated.model!.breaks![0].duration, 180);
        expect(updated.model!.breaks![0].isCustomized, false);
        expect(updated.model!.breaks![2].duration, 180);
        expect(updated.model!.breaks![2].isCustomized, false);

        // Customized break should remain unchanged
        expect(updated.model!.breaks![1].duration, 300);
        expect(updated.model!.breaks![1].isCustomized, true);
      },
    );

    test('updating default break duration preserves customized flag', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Update default break duration
      final newSettings = RoutineSettingsModel(
        startTime: bloc.state.model!.settings.startTime,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 240,
      );

      bloc.add(UpdateSettings(newSettings));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.settings.defaultBreakDuration == 240,
      );

      // All non-customized breaks should still be marked as non-customized
      for (final breakModel in updated.model!.breaks!) {
        if (!breakModel.isCustomized) {
          expect(breakModel.duration, 240);
        }
      }
    });

    test(
      'updating settings without changing break duration preserves breaks',
      () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final loaded = await bloc.stream.firstWhere((s) => s.model != null);
        final originalBreaks = loaded.model!.breaks!;

        // Update start time only (not break duration)
        final newSettings = RoutineSettingsModel(
          startTime: 999999,
          breaksEnabledByDefault: true,
          defaultBreakDuration: loaded.model!.settings.defaultBreakDuration,
        );

        bloc.add(UpdateSettings(newSettings));
        final updated = await bloc.stream.firstWhere(
          (s) => s.model!.settings.startTime == 999999,
        );

        // Breaks should remain unchanged
        for (var i = 0; i < originalBreaks.length; i++) {
          expect(
            updated.model!.breaks![i].duration,
            originalBreaks[i].duration,
          );
          expect(
            updated.model!.breaks![i].isCustomized,
            originalBreaks[i].isCustomized,
          );
        }
      },
    );

    test(
      'reset break to default resets duration and customized flag',
      () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Customize a break
        bloc.add(const UpdateBreakDuration(index: 0, duration: 300));
        final customized = await bloc.stream.firstWhere(
          (s) => s.model!.breaks![0].isCustomized == true,
        );

        expect(customized.model!.breaks![0].duration, 300);
        expect(customized.model!.breaks![0].isCustomized, true);

        // Reset to default
        bloc.add(const ResetBreakToDefault(index: 0));
        final reset = await bloc.stream.firstWhere(
          (s) => s.model!.breaks![0].isCustomized == false,
        );

        expect(
          reset.model!.breaks![0].duration,
          reset.model!.settings.defaultBreakDuration,
        );
        expect(reset.model!.breaks![0].isCustomized, false);
      },
    );

    test('reset break to default validates index bounds', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Try to reset invalid indices
      bloc.add(const ResetBreakToDefault(index: -1));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.model!.breaks, loaded.model!.breaks);

      bloc.add(const ResetBreakToDefault(index: 999));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.model!.breaks, loaded.model!.breaks);
    });

    test('reset break to default uses current default duration', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Customize a break
      bloc.add(const UpdateBreakDuration(index: 1, duration: 500));
      await bloc.stream.firstWhere((s) => s.model!.breaks![1].duration == 500);

      // Update default duration
      final newSettings = RoutineSettingsModel(
        startTime: bloc.state.model!.settings.startTime,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 200,
      );
      bloc.add(UpdateSettings(newSettings));
      await bloc.stream.firstWhere(
        (s) => s.model!.settings.defaultBreakDuration == 200,
      );

      // Reset customized break - should use new default (200)
      bloc.add(const ResetBreakToDefault(index: 1));
      final reset = await bloc.stream.firstWhere(
        (s) => s.model!.breaks![1].isCustomized == false,
      );

      expect(reset.model!.breaks![1].duration, 200);
      expect(reset.model!.breaks![1].isCustomized, false);
    });

    // REGRESSION TEST FOR BUG FIX: Selected task loses selection after reorder
    test(
      'selected task persists after reordering (fixes selection bug)',
      () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final loaded = await bloc.stream.firstWhere((s) => s.model != null);

        // Get the task we want to select and reorder
        final taskToSelect = loaded.model!.tasks[1]; // Select second task
        final selectedTaskId = taskToSelect.id;
        final selectedTaskName = taskToSelect.name;

        // Select task at index 1
        bloc.add(SelectTask(selectedTaskId));
        final selected = await bloc.stream.firstWhere(
          (s) => s.model!.selectedTaskId == selectedTaskId,
        );

        // Verify task is selected
        expect(selected.model!.selectedTask?.id, selectedTaskId);
        expect(selected.model!.selectedTask?.name, selectedTaskName);
        expect(selected.model!.currentTaskIndex, 1);

        // Reorder: move selected task from index 1 to index 3 (last position)
        bloc.add(const ReorderTasks(oldIndex: 1, newIndex: 3));
        final reordered = await bloc.stream.firstWhere(
          (s) => s.model!.tasks[3].id == selectedTaskId,
        );

        // CRITICAL: The same task should still be selected even though it moved
        expect(reordered.model!.selectedTask?.id, selectedTaskId);
        expect(reordered.model!.selectedTask?.name, selectedTaskName);
        expect(reordered.model!.currentTaskIndex, 3); // New index after reorder
        expect(
          reordered.model!.selectedTaskId,
          selectedTaskId,
        ); // Selection by ID persists
      },
    );

    test('selected task persists through multiple reorders', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Select task at index 0
      final selectedTaskId = loaded.model!.tasks[0].id;
      bloc.add(SelectTask(selectedTaskId));
      await bloc.stream.firstWhere(
        (s) => s.model!.selectedTaskId == selectedTaskId,
      );

      // First reorder: move from index 0 to index 2
      bloc.add(const ReorderTasks(oldIndex: 0, newIndex: 2));
      final firstReorder = await bloc.stream.firstWhere(
        (s) => s.model!.tasks[2].id == selectedTaskId,
      );
      expect(firstReorder.model!.selectedTask?.id, selectedTaskId);
      expect(firstReorder.model!.currentTaskIndex, 2);

      // Second reorder: move from index 2 to index 1
      bloc.add(const ReorderTasks(oldIndex: 2, newIndex: 1));
      final secondReorder = await bloc.stream.firstWhere(
        (s) => s.model!.tasks[1].id == selectedTaskId,
      );
      expect(secondReorder.model!.selectedTask?.id, selectedTaskId);
      expect(secondReorder.model!.currentTaskIndex, 1);

      // Third reorder: move from index 1 back to index 0
      bloc.add(const ReorderTasks(oldIndex: 1, newIndex: 0));
      final thirdReorder = await bloc.stream.firstWhere(
        (s) => s.model!.tasks[0].id == selectedTaskId,
      );
      expect(thirdReorder.model!.selectedTask?.id, selectedTaskId);
      expect(thirdReorder.model!.currentTaskIndex, 0);
    });

    test('selection by task ID works correctly', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Select task by ID (not index)
      final taskAtIndex2 = loaded.model!.tasks[2];
      bloc.add(SelectTask(taskAtIndex2.id));
      final selected = await bloc.stream.firstWhere(
        (s) => s.model!.selectedTaskId == taskAtIndex2.id,
      );

      expect(selected.model!.selectedTask?.id, taskAtIndex2.id);
      expect(selected.model!.currentTaskIndex, 2);

      // Select different task by ID
      final taskAtIndex0 = loaded.model!.tasks[0];
      bloc.add(SelectTask(taskAtIndex0.id));
      final reselected = await bloc.stream.firstWhere(
        (s) => s.model!.selectedTaskId == taskAtIndex0.id,
      );

      expect(reselected.model!.selectedTask?.id, taskAtIndex0.id);
      expect(reselected.model!.currentTaskIndex, 0);
    });

    test('selection handles non-existent task ID gracefully', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      final originalSelectedId = loaded.model!.selectedTaskId;

      // Try to select a task with non-existent ID
      bloc.add(const SelectTask('non-existent-id'));
      await Future.delayed(const Duration(milliseconds: 10));

      // Selection should remain unchanged
      expect(bloc.state.model!.selectedTaskId, originalSelectedId);
    });

    group('Break handling during execution', () {
      test('mark task done triggers break when break is enabled', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final loaded = await bloc.stream.firstWhere((s) => s.model != null);

        // Ensure first break is enabled
        expect(loaded.model!.breaks![0].isEnabled, true);

        // Mark first task as done
        bloc.add(const MarkTaskDone(actualDuration: 100));
        final updated = await bloc.stream.firstWhere(
          (s) => s.model!.tasks[0].isCompleted,
        );

        // Should be on break, not advanced to next task
        expect(updated.model!.isOnBreak, true);
        expect(updated.model!.currentBreakIndex, 0);
        expect(updated.model!.currentTaskIndex, 0); // Still on same task index
        expect(updated.model!.tasks[0].isCompleted, true);
      });

      test('mark task done skips break when break is disabled', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Disable first break
        bloc.add(const ToggleBreakAtIndex(0));
        await bloc.stream.firstWhere(
          (s) => s.model!.breaks![0].isEnabled == false,
        );

        // Mark first task as done
        bloc.add(const MarkTaskDone(actualDuration: 100));
        final updated = await bloc.stream.firstWhere(
          (s) => s.model!.currentTaskIndex == 1,
        );

        // Should advance directly to next task without break
        expect(updated.model!.isOnBreak, false);
        expect(updated.model!.currentBreakIndex, null);
        expect(updated.model!.currentTaskIndex, 1);
      });

      test('mark last task done does not trigger break', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final loaded = await bloc.stream.firstWhere((s) => s.model != null);

        // Select last task
        final lastTaskId = loaded.model!.tasks.last.id;
        bloc.add(SelectTask(lastTaskId));
        await bloc.stream.firstWhere(
          (s) => s.model!.selectedTaskId == lastTaskId,
        );

        // Mark last task as done
        bloc.add(const MarkTaskDone(actualDuration: 100));
        final updated = await bloc.stream.firstWhere(
          (s) => s.model!.tasks.last.isCompleted,
        );

        // Should not be on break
        expect(updated.model!.isOnBreak, false);
        expect(updated.model!.currentBreakIndex, null);
      });

      test('complete break advances to next task', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Mark first task as done to start break
        bloc.add(const MarkTaskDone(actualDuration: 100));
        await bloc.stream.firstWhere((s) => s.model!.isOnBreak);

        // Complete break
        bloc.add(const CompleteBreak());
        final updated = await bloc.stream.firstWhere(
          (s) => !s.model!.isOnBreak,
        );

        // Should advance to next task
        expect(updated.model!.isOnBreak, false);
        expect(updated.model!.currentBreakIndex, null);
        expect(updated.model!.currentTaskIndex, 1);
      });

      test('skip break advances to next task', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Mark first task as done to start break
        bloc.add(const MarkTaskDone(actualDuration: 100));
        await bloc.stream.firstWhere((s) => s.model!.isOnBreak);

        // Skip break
        bloc.add(const SkipBreak());
        final updated = await bloc.stream.firstWhere(
          (s) => !s.model!.isOnBreak,
        );

        // Should advance to next task
        expect(updated.model!.isOnBreak, false);
        expect(updated.model!.currentBreakIndex, null);
        expect(updated.model!.currentTaskIndex, 1);
      });

      test('current break getter returns correct break', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Initially no break
        expect(bloc.state.model!.currentBreak, null);

        // Mark first task as done to start break
        bloc.add(const MarkTaskDone(actualDuration: 100));
        final updated = await bloc.stream.firstWhere((s) => s.model!.isOnBreak);

        // Should return the first break
        final currentBreak = updated.model!.currentBreak;
        expect(currentBreak, isNotNull);
        expect(currentBreak!.duration, updated.model!.breaks![0].duration);
        expect(currentBreak.isEnabled, true);
      });

      test('multiple task completions with breaks', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Complete first task -> break
        bloc.add(const MarkTaskDone(actualDuration: 100));
        await bloc.stream.firstWhere((s) => s.model!.isOnBreak);

        // Complete break -> second task
        bloc.add(const CompleteBreak());
        await bloc.stream.firstWhere(
          (s) => !s.model!.isOnBreak && s.model!.currentTaskIndex == 1,
        );

        // Complete second task -> should skip break (second break is disabled)
        bloc.add(const MarkTaskDone(actualDuration: 150));
        final afterSecond = await bloc.stream.firstWhere(
          (s) => s.model!.currentTaskIndex == 2,
        );

        expect(afterSecond.model!.isOnBreak, false);
        expect(afterSecond.model!.tasks[1].isCompleted, true);

        // Complete third task -> break (third break is enabled)
        bloc.add(const MarkTaskDone(actualDuration: 200));
        final afterThird = await bloc.stream.firstWhere(
          (s) => s.model!.isOnBreak && s.model!.currentBreakIndex == 2,
        );

        expect(afterThird.model!.isOnBreak, true);
        expect(afterThird.model!.currentBreakIndex, 2);
        expect(afterThird.model!.tasks[2].isCompleted, true);
      });

      test('complete break does nothing when not on break', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Try to complete break when not on break
        bloc.add(const CompleteBreak());
        await Future.delayed(const Duration(milliseconds: 10));

        // State should remain unchanged
        expect(bloc.state.model!.isOnBreak, false);
        expect(bloc.state.model!.currentTaskIndex, 0);
      });

      test('skip break does nothing when not on break', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Try to skip break when not on break
        bloc.add(const SkipBreak());
        await Future.delayed(const Duration(milliseconds: 10));

        // State should remain unchanged
        expect(bloc.state.model!.isOnBreak, false);
        expect(bloc.state.model!.currentTaskIndex, 0);
      });

      // REGRESSION TEST: Ensure break state persists across operations
      test('break state persists through serialization (toMap/fromMap)', () {
        final state = RoutineStateModel(
          tasks: const [
            TaskModel(id: '1', name: 'Task1', estimatedDuration: 60, order: 0),
            TaskModel(id: '2', name: 'Task2', estimatedDuration: 120, order: 1),
          ],
          breaks: const [BreakModel(duration: 30, isEnabled: true)],
          settings: RoutineSettingsModel(
            startTime: 0,
            breaksEnabledByDefault: true,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '1',
          isOnBreak: true,
          currentBreakIndex: 0,
        );

        final map = state.toMap();
        final decoded = RoutineStateModel.fromMap(map);

        expect(decoded.isOnBreak, true);
        expect(decoded.currentBreakIndex, 0);
        expect(decoded.currentBreak, isNotNull);
        expect(decoded.currentBreak!.duration, 30);
      });
    });

    group('Routine Completion', () {
      test('should trigger completion when last task is marked done', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Complete all tasks except the last one
        for (int i = 0; i < 3; i++) {
          // Disable breaks to move directly to next task
          bloc.add(ToggleBreakAtIndex(i));
          await bloc.stream.firstWhere(
            (s) => s.model!.breaks![i].isEnabled == false,
          );
          bloc.add(MarkTaskDone(actualDuration: 100 * (i + 1)));
          await bloc.stream.firstWhere((s) => s.model!.tasks[i].isCompleted);
        }

        // Verify we're on the last task
        expect(bloc.state.model!.currentTaskIndex, 3);

        // Complete the last task
        bloc.add(const MarkTaskDone(actualDuration: 400));

        // Wait for completion state
        final completed = await bloc.stream.firstWhere(
          (s) => s.isCompleted == true,
        );

        expect(completed.isCompleted, true);
        expect(completed.completionData, isNotNull);
        expect(completed.completionData!.totalTasksCompleted, 4);
      });

      test('should calculate completion statistics correctly', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Complete all tasks with known durations
        final actualDurations = [100, 200, 300, 400];

        for (int i = 0; i < 4; i++) {
          if (i < 3) {
            // Disable breaks for non-last tasks
            bloc.add(ToggleBreakAtIndex(i));
            await bloc.stream.firstWhere(
              (s) => s.model!.breaks![i].isEnabled == false,
            );
          }
          bloc.add(MarkTaskDone(actualDuration: actualDurations[i]));
          if (i < 3) {
            await bloc.stream.firstWhere((s) => s.model!.tasks[i].isCompleted);
          }
        }

        final completed = await bloc.stream.firstWhere(
          (s) => s.isCompleted == true,
        );

        expect(
          completed.completionData!.totalTimeSpent,
          1000,
        ); // Sum of durations
        expect(completed.completionData!.totalTasksCompleted, 4);
        expect(completed.completionData!.routineName, 'Morning Routine');
        expect(completed.completionData!.tasksDetails?.length, 4);
      });

      test('should include task details in completion data', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Complete all tasks
        for (int i = 0; i < 4; i++) {
          if (i < 3) {
            bloc.add(ToggleBreakAtIndex(i));
            await bloc.stream.firstWhere(
              (s) => s.model!.breaks![i].isEnabled == false,
            );
          }
          bloc.add(MarkTaskDone(actualDuration: 100 * (i + 1)));
          // Wait for completion only on last task
          if (i == 3) {
            break;
          }
          if (i < 3) {
            await bloc.stream.firstWhere((s) => s.model!.tasks[i].isCompleted);
          }
        }

        final completed = await bloc.stream
            .firstWhere((s) => s.isCompleted == true, orElse: () => bloc.state)
            .timeout(const Duration(seconds: 5));

        final details = completed.completionData!.tasksDetails!;
        expect(details[0].taskName, 'Morning Workout');
        expect(details[0].actualDuration, 100);
        expect(details[1].taskName, 'Shower');
        expect(details[1].actualDuration, 200);
      });

      test('should reset routine to initial state', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Complete first task
        bloc.add(const ToggleBreakAtIndex(0));
        await bloc.stream.firstWhere(
          (s) => s.model!.breaks![0].isEnabled == false,
        );
        bloc.add(const MarkTaskDone(actualDuration: 100));
        await bloc.stream.firstWhere((s) => s.model!.tasks[0].isCompleted);

        // Verify task is completed
        expect(bloc.state.model!.tasks[0].isCompleted, true);
        expect(bloc.state.model!.tasks[0].actualDuration, 100);

        // Reset routine
        bloc.add(const ResetRoutine());
        // Wait a bit for the reset to process
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify all tasks are reset
        expect(bloc.state.model!.tasks[0].isCompleted, false);
        expect(bloc.state.model!.tasks[0].actualDuration, isNull);
        expect(bloc.state.model!.currentTaskIndex, 0);
        expect(bloc.state.completionData, isNull);
        expect(bloc.state.isCompleted, false);
      });

      test('should reset all tasks when resetting routine', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Complete first two tasks only (less complex)
        for (int i = 0; i < 2; i++) {
          bloc.add(ToggleBreakAtIndex(i));
          await bloc.stream.firstWhere(
            (s) => s.model!.breaks![i].isEnabled == false,
          );
          bloc.add(MarkTaskDone(actualDuration: 100 * (i + 1)));
          await bloc.stream.firstWhere((s) => s.model!.tasks[i].isCompleted);
        }

        // Verify at least one task is completed
        expect(bloc.state.model!.tasks[0].isCompleted, true);

        // Reset routine
        bloc.add(const ResetRoutine());
        // Wait a bit for the reset to process
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify all tasks are reset (check just the first few)
        expect(bloc.state.model!.tasks[0].isCompleted, false);
        expect(bloc.state.model!.tasks[0].actualDuration, isNull);
        expect(bloc.state.model!.tasks[1].isCompleted, false);
        expect(bloc.state.model!.tasks[1].actualDuration, isNull);
      });

      test('should not trigger completion for non-last task', () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Complete first task
        bloc.add(const ToggleBreakAtIndex(0));
        await bloc.stream.firstWhere(
          (s) => s.model!.breaks![0].isEnabled == false,
        );
        bloc.add(const MarkTaskDone(actualDuration: 100));
        await bloc.stream.firstWhere((s) => s.model!.tasks[0].isCompleted);

        // Verify routine is NOT completed
        expect(bloc.state.isCompleted, false);
        expect(bloc.state.completionData, isNull);
      });
    });
  });
}
