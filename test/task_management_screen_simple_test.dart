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

      // Both columns show "No routine loaded" when no data is present
      expect(find.text('No routine loaded'), findsNWidgets(2));

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
      // Tasks appear in both the list and the settings panel, so we check for at least one
      expect(find.text('Morning Workout'), findsAtLeastNWidgets(1));
      expect(find.text('Shower'), findsAtLeastNWidgets(1));
      expect(find.text('Breakfast'), findsAtLeastNWidgets(1));
      expect(find.text('Review Plan'), findsAtLeastNWidgets(1));

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

    testWidgets('displays right column with settings panel', (tester) async {
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

      // Should show "No routine loaded" in both columns initially
      expect(find.text('No routine loaded'), findsNWidgets(2));

      bloc.close();
    });
  });
}
