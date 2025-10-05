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

    testWidgets('displays task list and bottom bar after loading data', (tester) async {
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

      // Bottom bar content exists
      expect(find.textContaining('Estimated finish:'), findsOneWidget);
      expect(find.textContaining('Total time:'), findsOneWidget);

      bloc.close();
    });

    testWidgets('can add a new task via dialog', (tester) async {
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

      // Tap Add New Task button in the bottom bar
      await tester.tap(find.widgetWithText(FilledButton, 'Add New Task'));
      await tester.pumpAndSettle();

      // Enter name and duration
      await tester.enterText(find.byType(TextFormField).at(0), 'New Item');
      await tester.enterText(find.byType(TextFormField).at(1), '3');

      // Submit
      await tester.tap(find.widgetWithText(FilledButton, 'Add Task'));
      await tester.pumpAndSettle();

      // Verify appears in list
      expect(find.text('New Item'), findsOneWidget);
      expect(find.text('3 min'), findsOneWidget);

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

    testWidgets('displays right column placeholder', (tester) async {
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

      expect(
        find.text('Right Column: Settings & Details Placeholder'),
        findsOneWidget,
      );

      bloc.close();
    });
  });
}
