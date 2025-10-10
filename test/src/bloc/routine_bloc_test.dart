import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
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
      expect(
        loaded.model!.selectedTaskId,
        loaded.model!.tasks[0].id,
      ); // Should select first task
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

    test('mark task done completes and advances index', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final initial = await bloc.stream.firstWhere((s) => s.model != null);
      expect(initial.model!.selectedTaskId, initial.model!.tasks[0].id);

      bloc.add(const MarkTaskDone(actualDuration: 30));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.selectedTaskId == initial.model!.tasks[1].id,
      );
      expect(updated.model!.tasks.first.isCompleted, true);
      expect(updated.model!.tasks.first.actualDuration, 30);
    });

    test('select task updates selectedTaskId', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final initial = await bloc.stream.firstWhere((s) => s.model != null);
      final thirdTaskId = initial.model!.tasks[2].id;
      bloc.add(SelectTask(thirdTaskId));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.selectedTaskId == thirdTaskId,
      );
      expect(updated.model!.selectedTaskId, thirdTaskId);
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
      final initial = await bloc.stream.firstWhere((s) => s.model != null);
      final secondTaskId = initial.model!.tasks[1].id;
      bloc.add(SelectTask(secondTaskId));
      await bloc.stream.firstWhere(
        (s) => s.model!.selectedTaskId == secondTaskId,
      );

      bloc.add(const GoToPreviousTask());
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.selectedTaskId == initial.model!.tasks[0].id,
      );
      expect(updated.model!.selectedTaskId, initial.model!.tasks[0].id);
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

    test('select task handles invalid task ID safely', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Try to select non-existent task ID
      bloc.add(const SelectTask('invalid-task-id'));
      await Future.delayed(const Duration(milliseconds: 10));

      // Should update to the invalid task ID (bloc doesn't validate existence)
      expect(bloc.state.model!.selectedTaskId, 'invalid-task-id');
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

    test('delete task adjusts selectedTaskId when needed', () async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final initial = await bloc.stream.firstWhere((s) => s.model != null);

      // Select last task
      final lastTaskId = initial.model!.tasks[3].id;
      bloc.add(SelectTask(lastTaskId));
      await bloc.stream.firstWhere(
        (s) => s.model!.selectedTaskId == lastTaskId,
      );

      // Delete the last task
      bloc.add(const DeleteTask(3));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == 3,
      );

      // Selection should adjust to last remaining task (at index 2)
      expect(updated.model!.selectedTaskId, updated.model!.tasks[2].id);
      expect(updated.model!.tasks.length, 3);
    });

    test(
      'delete task adjusts currentTaskIndex when deleting before current',
      () async {
        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final initial = await bloc.stream.firstWhere((s) => s.model != null);

        // Select task at index 2 (third task)
        final selectedTaskId = initial.model!.tasks[2].id;
        bloc.add(SelectTask(selectedTaskId));
        await bloc.stream.firstWhere(
          (s) => s.model!.selectedTaskId == selectedTaskId,
        );

        // Delete task at index 0 (before selected task)
        bloc.add(const DeleteTask(0));
        final updated = await bloc.stream.firstWhere(
          (s) => s.model!.tasks.length == 3,
        );

        // Same task should still be selected (selection by ID persists)
        expect(updated.model!.selectedTaskId, selectedTaskId);
        expect(updated.model!.tasks.length, 3);
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

    group('selection persistence after reorder (regression tests for bug)', () {
      test('selected task remains selected after reordering (moving up)', () async {
        // Bug: Selected task loses selection after reordering in Task Management screen
        // Expected: The originally selected task remains selected after reordering, regardless of its new index

        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final initial = await bloc.stream.firstWhere((s) => s.model != null);

        // Select the third task (index 2, which should be "Breakfast")
        final taskToSelect = initial.model!.tasks[2];
        bloc.add(SelectTask(taskToSelect.id));

        final afterSelection = await bloc.stream.firstWhere(
          (s) => s.model!.selectedTaskId == taskToSelect.id,
        );

        // Verify the correct task is selected
        expect(afterSelection.model!.selectedTaskId, taskToSelect.id);
        expect(taskToSelect.name, 'Breakfast'); // Sanity check

        // Reorder: move selected task from index 2 to index 0 (moving up)
        bloc.add(const ReorderTasks(oldIndex: 2, newIndex: 0));

        final afterReorder = await bloc.stream.firstWhere(
          (s) =>
              s.model!.tasks[0].id ==
              taskToSelect.id, // Task has moved to index 0
        );

        // CRITICAL: The same task should still be selected after reordering
        expect(afterReorder.model!.selectedTaskId, taskToSelect.id);
        expect(
          afterReorder.model!.tasks[0].id,
          taskToSelect.id,
        ); // Task is now at index 0
        expect(
          afterReorder.model!.tasks[0].name,
          'Breakfast',
        ); // Still the same task
      });

      test(
        'selected task remains selected after reordering (moving down)',
        () async {
          // Test moving selected task down in the list

          final bloc = FirebaseTestHelper.routineBloc
            ..add(const LoadSampleRoutine());
          final initial = await bloc.stream.firstWhere((s) => s.model != null);

          // Select the first task (index 0, which should be "Morning Workout")
          final taskToSelect = initial.model!.tasks[0];
          bloc.add(SelectTask(taskToSelect.id));

          final afterSelection = await bloc.stream.firstWhere(
            (s) => s.model!.selectedTaskId == taskToSelect.id,
          );

          // Verify the correct task is selected
          expect(afterSelection.model!.selectedTaskId, taskToSelect.id);
          expect(taskToSelect.name, 'Morning Workout'); // Sanity check

          // Reorder: move selected task from index 0 to index 3 (moving down)
          bloc.add(const ReorderTasks(oldIndex: 0, newIndex: 3));

          final afterReorder = await bloc.stream.firstWhere(
            (s) =>
                s.model!.tasks[3].id ==
                taskToSelect.id, // Task has moved to index 3
          );

          // CRITICAL: The same task should still be selected after reordering
          expect(afterReorder.model!.selectedTaskId, taskToSelect.id);
          expect(
            afterReorder.model!.tasks[3].id,
            taskToSelect.id,
          ); // Task is now at index 3
          expect(
            afterReorder.model!.tasks[3].name,
            'Morning Workout',
          ); // Still the same task
        },
      );

      test('non-selected task reordering does not affect selection', () async {
        // Test that reordering other tasks doesn't affect the selected task

        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final initial = await bloc.stream.firstWhere((s) => s.model != null);

        // Select the second task (index 1, which should be "Shower")
        final selectedTask = initial.model!.tasks[1];
        bloc.add(SelectTask(selectedTask.id));

        final afterSelection = await bloc.stream.firstWhere(
          (s) => s.model!.selectedTaskId == selectedTask.id,
        );

        // Verify the correct task is selected
        expect(afterSelection.model!.selectedTaskId, selectedTask.id);
        expect(selectedTask.name, 'Shower'); // Sanity check

        // Reorder: move a different task (index 0 to index 3) - not the selected one
        bloc.add(const ReorderTasks(oldIndex: 0, newIndex: 3));

        final afterReorder = await bloc.stream.firstWhere(
          (s) => s.model!.tasks.any(
            (t) => t.name == 'Morning Workout' && t.order == 3,
          ),
        );

        // CRITICAL: The same task should still be selected
        expect(afterReorder.model!.selectedTaskId, selectedTask.id);

        // The selected task may have changed position due to other task moving
        final selectedTaskNewIndex = afterReorder.model!.tasks.indexWhere(
          (t) => t.id == selectedTask.id,
        );
        expect(
          selectedTaskNewIndex,
          0,
        ); // "Shower" should now be at index 0 (moved up)
        expect(afterReorder.model!.tasks[selectedTaskNewIndex].name, 'Shower');
      });

      test('selected task persists through multiple reorders', () async {
        // Test that selection persists through a series of reorder operations

        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final initial = await bloc.stream.firstWhere((s) => s.model != null);

        // Select the "Review Plan" task (should be at index 3)
        final taskToSelect = initial.model!.tasks.firstWhere(
          (t) => t.name == 'Review Plan',
        );
        bloc.add(SelectTask(taskToSelect.id));

        final afterSelection = await bloc.stream.firstWhere(
          (s) => s.model!.selectedTaskId == taskToSelect.id,
        );

        expect(afterSelection.model!.selectedTaskId, taskToSelect.id);

        // First reorder: move selected task to index 1
        bloc.add(const ReorderTasks(oldIndex: 3, newIndex: 1));

        final afterFirstReorder = await bloc.stream.firstWhere(
          (s) => s.model!.tasks[1].id == taskToSelect.id,
        );

        expect(afterFirstReorder.model!.selectedTaskId, taskToSelect.id);
        expect(afterFirstReorder.model!.tasks[1].name, 'Review Plan');

        // Second reorder: move selected task to index 0
        bloc.add(const ReorderTasks(oldIndex: 1, newIndex: 0));

        final afterSecondReorder = await bloc.stream.firstWhere(
          (s) => s.model!.tasks[0].id == taskToSelect.id,
        );

        // CRITICAL: Selection should persist through multiple reorders
        expect(afterSecondReorder.model!.selectedTaskId, taskToSelect.id);
        expect(afterSecondReorder.model!.tasks[0].name, 'Review Plan');
      });

      test('selection works correctly with newly added tasks', () async {
        // Test that selection works correctly when new tasks are added and then reordered

        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        // Add a new task
        bloc.add(const AddTask(name: 'New Task', durationSeconds: 300));

        final afterAdd = await bloc.stream.firstWhere(
          (s) => s.model!.tasks.length == 5,
        );

        // Select the newly added task (should be at the end)
        final newTask = afterAdd.model!.tasks.last;
        expect(newTask.name, 'New Task');

        bloc.add(SelectTask(newTask.id));

        final afterSelection = await bloc.stream.firstWhere(
          (s) => s.model!.selectedTaskId == newTask.id,
        );

        expect(afterSelection.model!.selectedTaskId, newTask.id);

        // Reorder: move the new task to the beginning
        bloc.add(const ReorderTasks(oldIndex: 4, newIndex: 0));

        final afterReorder = await bloc.stream.firstWhere(
          (s) => s.model!.tasks[0].id == newTask.id,
        );

        // CRITICAL: Selection should persist for newly added tasks too
        expect(afterReorder.model!.selectedTaskId, newTask.id);
        expect(afterReorder.model!.tasks[0].name, 'New Task');
      });

      test('selection handles task deletion correctly', () async {
        // Test that selection is handled properly when selected task is deleted

        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        final initial = await bloc.stream.firstWhere((s) => s.model != null);

        // Select the second task (index 1, "Shower")
        final taskToSelect = initial.model!.tasks[1];
        bloc.add(SelectTask(taskToSelect.id));

        final afterSelection = await bloc.stream.firstWhere(
          (s) => s.model!.selectedTaskId == taskToSelect.id,
        );

        expect(afterSelection.model!.selectedTaskId, taskToSelect.id);
        expect(taskToSelect.name, 'Shower');

        // Delete the selected task
        bloc.add(const DeleteTask(1));

        final afterDelete = await bloc.stream.firstWhere(
          (s) => s.model!.tasks.length == 3, // One less task
        );

        // Selection should be updated to a nearby task when selected task is deleted
        expect(
          afterDelete.model!.selectedTaskId,
          isNot(taskToSelect.id),
        ); // Old task is gone
        expect(
          afterDelete.model!.selectedTaskId,
          isNotNull,
        ); // Should select something

        // Should select the task that took its place (at index 1)
        expect(
          afterDelete.model!.selectedTaskId,
          afterDelete.model!.tasks[1].id,
        );
      });

      test(
        'backward compatibility: migrates from currentTaskIndex to selectedTaskId',
        () async {
          // Test that old saved data with currentTaskIndex is migrated correctly

          // Create old-format data with currentTaskIndex
          final oldFormatData = {
            'tasks': [
              {
                'id': 'task1',
                'name': 'Task 1',
                'estimatedDuration': 600,
                'isCompleted': false,
                'order': 0,
              },
              {
                'id': 'task2',
                'name': 'Task 2',
                'estimatedDuration': 900,
                'isCompleted': false,
                'order': 1,
              },
            ],
            'settings': {
              'startTime': DateTime.now().millisecondsSinceEpoch,
              'breaksEnabledByDefault': true,
              'defaultBreakDuration': 120,
            },
            'currentTaskIndex': 1, // Old format field
            'isRunning': false,
          };

          // Import using fromMap (which should handle migration)
          final routineState = RoutineStateModel.fromMap(oldFormatData);

          // Should migrate currentTaskIndex to selectedTaskId
          expect(
            routineState.selectedTaskId,
            'task2',
          ); // Should select task at index 1

          // Verify the task data is correct
          expect(routineState.tasks.length, 2);
          expect(routineState.tasks[1].id, 'task2');
          expect(routineState.tasks[1].name, 'Task 2');
        },
      );
    });
  });
}
