import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/screens/task_management_screen.dart';

void main() {
  group('TaskManagementScreen Right Panel', () {
    testWidgets('populates details when selecting a task', (tester) async {
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

      // Select second task
      await tester.tap(find.text('Shower'));
      await tester.pumpAndSettle();

      // Right panel should show selected task values
      final nameFieldFinder = find.byKey(const Key('task_name_field'));
      expect(nameFieldFinder, findsOneWidget);
      final nameField = tester.widget<TextField>(nameFieldFinder);
      expect((nameField.controller?.text ?? ''), isNotEmpty);

      bloc.close();
    });

    testWidgets('save changes updates bloc settings and task', (tester) async {
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

      // Edit fields
      await tester.enterText(
        find.byKey(const Key('task_name_field')),
        'Renamed Task',
      );
      await tester.enterText(find.byKey(const Key('task_duration_field')), '7');
      await tester.enterText(
        find.byKey(const Key('settings_break_duration_field')),
        '3',
      );

      // Save (ensure button is visible before tapping)
      final saveFinder = find.byKey(const Key('settings_save_button'));
      await tester.ensureVisible(saveFinder);
      await tester.pumpAndSettle();
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();

      // Verify updates landed in bloc state
      final s = bloc.state.model!;
      expect(s.settings.defaultBreakDuration, 3 * 60);
      expect(s.tasks[s.currentTaskIndex].name, 'Renamed Task');
      expect(s.tasks[s.currentTaskIndex].estimatedDuration, 7 * 60);

      bloc.close();
    });

    testWidgets('duplicate and delete work', (tester) async {
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
      final originalCount = bloc.state.model!.tasks.length;

      // Duplicate (ensure button is visible before tapping)
      final duplicateFinder = find.byKey(const Key('task_duplicate_button'));
      await tester.ensureVisible(duplicateFinder);
      await tester.pumpAndSettle();
      await tester.tap(duplicateFinder);
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, originalCount + 1);

      // Delete (ensure button is visible before tapping)
      final deleteFinder = find.byKey(const Key('task_delete_button'));
      await tester.ensureVisible(deleteFinder);
      await tester.pumpAndSettle();
      await tester.tap(deleteFinder);
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, originalCount);

      bloc.close();
    });
  });
}
