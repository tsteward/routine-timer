import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/screens/task_management_screen.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/app_theme.dart';

void main() {
  group('TaskManagementScreen Right Panel', () {
    testWidgets('populates task details on selection and saves changes', (
      tester,
    ) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      // Load data
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Select second task by key
      await tester.tap(find.byKey(const ValueKey('task-2')));
      await tester.pumpAndSettle();

      // Edit task name and duration
      await tester.enterText(
        find.byKey(const ValueKey('task-name')),
        'Quick Shower',
      );
      await tester.enterText(
        find.byKey(const ValueKey('task-duration-minutes')),
        '7',
      );

      // Save (ensure visible)
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify bloc state updated
      final idx = bloc.state.model!.currentTaskIndex;
      expect(bloc.state.model!.tasks[idx].name, 'Quick Shower');
      expect(bloc.state.model!.tasks[idx].estimatedDuration, 7 * 60);

      bloc.close();
    });

    testWidgets('duplicate and delete task actions work', (tester) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Select first task by key to avoid ambiguity
      await tester.tap(find.byKey(const ValueKey('task-1')));
      await tester.pumpAndSettle();

      expect(bloc.state.model!.tasks.length, 4);

      // Duplicate
      await tester.ensureVisible(find.byKey(const ValueKey('duplicate-task')));
      await tester.tap(find.byKey(const ValueKey('duplicate-task')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, 5);

      // Delete selected (which should be the duplicate at index 1)
      await tester.ensureVisible(find.byKey(const ValueKey('delete-task')));
      await tester.tap(find.byKey(const ValueKey('delete-task')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, 4);

      bloc.close();
    });
  });
}
