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
  });
}
