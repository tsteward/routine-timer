import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';

void main() {
  group('RoutineBloc task mutations', () {
    test('updates selected task fields', () async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Select second task (index 1)
      bloc.add(const SelectTask(1));
      await bloc.stream.firstWhere((s) => s.model!.currentTaskIndex == 1);

      bloc.add(const UpdateSelectedTask(name: 'Quick Shower', estimatedDurationSeconds: 7 * 60));
      final updated = await bloc.stream.firstWhere((s) => s.model!.tasks[1].name == 'Quick Shower');

      expect(updated.model!.tasks[1].name, 'Quick Shower');
      expect(updated.model!.tasks[1].estimatedDuration, 7 * 60);
    });

    test('duplicates selected task after it', () async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      final initialTasks = loaded.model!.tasks;
      final initialLength = initialTasks.length;

      bloc.add(const DuplicateSelectedTask());
      final duplicated = await bloc.stream.firstWhere((s) => s.model!.tasks.length == initialLength + 1);

      expect(duplicated.model!.tasks.length, initialLength + 1);
      expect(duplicated.model!.tasks[1].name, initialTasks[0].name);
      expect(duplicated.model!.tasks[1].id != initialTasks[0].id, true);

      bloc.close();
    });

    test('deletes selected task and adjusts index', () async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      final initialLength = loaded.model!.tasks.length;
      expect(loaded.model!.currentTaskIndex, 0);

      bloc.add(const DeleteSelectedTask());
      final afterDelete = await bloc.stream.firstWhere((s) => s.model!.tasks.length == initialLength - 1);

      expect(afterDelete.model!.tasks.length, initialLength - 1);
      expect(afterDelete.model!.currentTaskIndex, 0);

      bloc.close();
    });
  });
}
