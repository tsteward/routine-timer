import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/screens/task_management_screen.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/app_theme.dart';

void main() {
  group('TaskManagementScreen Integration Tests', () {
    testWidgets('displays screen structure correctly', (tester) async {
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

      // Should have basic screen structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Task Management'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget); // Two-column layout
      expect(find.byType(Expanded), findsNWidgets(2)); // Left and right columns
      expect(find.byType(FloatingActionButton), findsOneWidget);

      bloc.close();
    });

    testWidgets('shows no routine loaded initially', (tester) async {
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

      // Appears in both left and right columns
      expect(find.text('No routine loaded'), findsWidgets);

      bloc.close();
    });

    testWidgets('displays task list after loading data', (tester) async {
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

      // Load sample data
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Should show task list
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('Shower'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Review Plan'), findsOneWidget);

      bloc.close();
    });

    testWidgets('displays task durations correctly', (tester) async {
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

      // Check durations are displayed
      expect(find.text('20 min'), findsOneWidget); // Morning Workout
      expect(find.text('10 min'), findsOneWidget); // Shower
      expect(find.text('15 min'), findsOneWidget); // Breakfast
      expect(find.text('5 min'), findsOneWidget); // Review Plan

      bloc.close();
    });

    testWidgets('displays drag handles', (tester) async {
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

      // Should have drag handles
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(4));

      bloc.close();
    });

    testWidgets('handles task selection', (tester) async {
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

      // Tap on second task
      await tester.tap(find.text('Shower'));
      await tester.pumpAndSettle();

      // Verify selection changed
      expect(bloc.state.model?.currentTaskIndex, 1);

      bloc.close();
    });

    testWidgets('shows settings and task details UI on the right', (
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

      // Load sample data so right panel populates
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      expect(find.text('Routine Settings'), findsOneWidget);
      expect(find.text('Task Details'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn-pick-time')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('toggle-breaks-default')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('input-break-duration-minutes')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('btn-save-settings')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn-cancel-settings')), findsOneWidget);
      expect(find.byKey(const ValueKey('input-task-name')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('input-task-duration-minutes')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('btn-duplicate-task')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn-delete-task')), findsOneWidget);

      bloc.close();
    });

    testWidgets('task selection populates right panel fields', (tester) async {
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

      // Select the second task
      await tester.tap(find.text('Shower'));
      await tester.pumpAndSettle();

      // Right panel should contain selected task details
      final nameField = find.byKey(const ValueKey('input-task-name'));
      final durationField = find.byKey(
        const ValueKey('input-task-duration-minutes'),
      );
      expect(nameField, findsOneWidget);
      expect(durationField, findsOneWidget);
      expect(tester.widget<TextField>(nameField).controller?.text, 'Shower');
      expect(tester.widget<TextField>(durationField).controller?.text, '10');

      bloc.close();
    });

    testWidgets('save updates task and settings', (tester) async {
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

      // Change task fields
      await tester.enterText(
        find.byKey(const ValueKey('input-task-name')),
        'Edited Task',
      );
      await tester.enterText(
        find.byKey(const ValueKey('input-task-duration-minutes')),
        '25',
      );

      // Change settings fields
      await tester.enterText(
        find.byKey(const ValueKey('input-break-duration-minutes')),
        '3',
      );

      // Toggle breaks default
      await tester.tap(find.byKey(const ValueKey('toggle-breaks-default')));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byKey(const ValueKey('btn-save-settings')));
      await tester.pumpAndSettle();

      final model = bloc.state.model!;
      expect(model.tasks[model.currentTaskIndex].name, 'Edited Task');
      expect(model.tasks[model.currentTaskIndex].estimatedDuration, 25 * 60);
      expect(model.settings.defaultBreakDuration, 3 * 60);
      // Breaks enabled toggled from initial true to false or vice versa; we assert value changed
      // Since initial sample was true, after toggle it should be false
      expect(model.settings.breaksEnabledByDefault, isFalse);

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

      final initialLength = bloc.state.model!.tasks.length;

      // Duplicate
      await tester.tap(find.byKey(const ValueKey('btn-duplicate-task')));
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, initialLength + 1);

      // Delete
      await tester.tap(find.byKey(const ValueKey('btn-delete-task')));
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, initialLength);

      bloc.close();
    });
  });
}
