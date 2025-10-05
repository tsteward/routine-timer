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

      expect(find.text('No routine loaded'), findsOneWidget);

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

    testWidgets('populates task details when a task is selected', (tester) async {
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

      // The task details fields should reflect selection
      final nameField = find.byKey(const Key('task-name-field'));
      final durationField = find.byKey(const Key('task-duration-field'));
      expect(nameField, findsOneWidget);
      expect(durationField, findsOneWidget);

      final nameText = tester.widget<TextField>(nameField).controller?.text;
      final durationText = tester.widget<TextField>(durationField).controller?.text;
      expect(nameText, 'Shower');
      expect(durationText, '10');

      bloc.close();
    });

    testWidgets('save updates settings and task', (tester) async {
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

      // Change task name and duration
      await tester.enterText(find.byKey(const Key('task-name-field')), 'New Name');
      await tester.enterText(find.byKey(const Key('task-duration-field')), '7');

      // Change default break duration
      await tester.enterText(
        find.byKey(const Key('settings-break-duration-field')),
        '3',
      );

      // Save
      await tester.tap(find.byKey(const Key('settings-save-button')));
      await tester.pumpAndSettle();

      // Verify bloc updated
      expect(bloc.state.model!.tasks[0].name, 'New Name');
      expect(bloc.state.model!.tasks[0].estimatedDuration, 7 * 60);
      expect(bloc.state.model!.settings.defaultBreakDuration, 3 * 60);

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

      // Duplicate current (index 0)
      await tester.tap(find.byKey(const Key('task-duplicate-button')));
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, 5);

      // Delete selected (which becomes the duplicate at index 1)
      await tester.tap(find.byKey(const Key('task-delete-button')));
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, 4);

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

    testWidgets('displays right column settings and task details', (tester) async {
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

      expect(find.text('Routine Settings'), findsOneWidget);
      expect(find.text('Task Details'), findsOneWidget);

      bloc.close();
    });
  });
}
