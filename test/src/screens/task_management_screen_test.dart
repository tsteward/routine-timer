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
      expect(
        find.byType(Expanded),
        findsNWidgets(3),
      ); // Main content + left and right columns
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

      // Shows "No routine loaded" in both left and right columns
      expect(find.text('No routine loaded'), findsAtLeastNWidgets(1));

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
      // Tasks will appear in both left column and right column (in text field)
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

    testWidgets('displays right column settings and details', (tester) async {
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

      // Check for routine settings section
      expect(find.text('Routine Settings'), findsOneWidget);
      expect(find.text('Routine Start Time'), findsOneWidget);
      expect(find.text('Break Duration'), findsOneWidget);

      // Check for task details section
      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Task Name'), findsOneWidget);
      expect(find.text('Estimated Duration'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      bloc.close();
    });
  });
}
