import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
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

    test('update task modifies task properties', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalTask = loaded.model!.tasks[0];

      final updatedTask = originalTask.copyWith(
        name: 'Updated Task Name',
        estimatedDuration: 1800,
      );

      bloc.add(UpdateTask(index: 0, task: updatedTask));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks[0].name == 'Updated Task Name',
      );

      expect(updated.model!.tasks[0].name, 'Updated Task Name');
      expect(updated.model!.tasks[0].estimatedDuration, 1800);
      expect(updated.model!.tasks[0].id, originalTask.id);
    });

    test('duplicate task creates copy with new ID', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalTaskCount = loaded.model!.tasks.length;
      final taskToDuplicate = loaded.model!.tasks[1];

      bloc.add(const DuplicateTask(1));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == originalTaskCount + 1,
      );

      expect(updated.model!.tasks.length, originalTaskCount + 1);
      final duplicatedTask = updated.model!.tasks[2];
      expect(duplicatedTask.name, '${taskToDuplicate.name} (Copy)');
      expect(duplicatedTask.estimatedDuration, taskToDuplicate.estimatedDuration);
      expect(duplicatedTask.id, isNot(taskToDuplicate.id));
    });

    test('delete task removes task and adjusts indices', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final originalTaskCount = loaded.model!.tasks.length;
      final taskToDelete = loaded.model!.tasks[1];

      bloc.add(const DeleteTask(1));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == originalTaskCount - 1,
      );

      expect(updated.model!.tasks.length, originalTaskCount - 1);
      expect(
        updated.model!.tasks.every((task) => task.id != taskToDelete.id),
        true,
      );
      // Verify orders are still sequential
      final orders = updated.model!.tasks.map((t) => t.order).toList();
      expect(orders, [0, 1, 2]);
    });

    test('delete task adjusts currentTaskIndex when needed', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Select last task
      bloc.add(const SelectTask(3));
      await bloc.stream.firstWhere((s) => s.model!.currentTaskIndex == 3);

      // Delete it
      bloc.add(const DeleteTask(3));
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == 3,
      );

      // Index should be adjusted to the new last task
      expect(updated.model!.currentTaskIndex, 2);
    });

    test('delete task does not delete last remaining task', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Delete tasks until only one remains
      bloc.add(const DeleteTask(0));
      await bloc.stream.firstWhere((s) => s.model!.tasks.length == 3);
      bloc.add(const DeleteTask(0));
      await bloc.stream.firstWhere((s) => s.model!.tasks.length == 2);
      bloc.add(const DeleteTask(0));
      await bloc.stream.firstWhere((s) => s.model!.tasks.length == 1);

      // Try to delete the last task - should be ignored
      bloc.add(const DeleteTask(0));
      await Future.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.model!.tasks.length, 1);
    });
  });
}
