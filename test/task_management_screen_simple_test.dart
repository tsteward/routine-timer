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
      expect(
        find.byType(Column),
        findsAtLeastNWidgets(1),
      ); // Main column with content and bottom bar
      expect(find.byType(Row), findsAtLeastNWidgets(1)); // Two-column layout
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

    testWidgets('displays bottom bar with total time and estimated finish', (
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

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Should display Total Time and Estimated Finish labels
      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('Estimated Finish'), findsOneWidget);

      // Should display Add New Task button
      expect(find.text('Add New Task'), findsOneWidget);

      bloc.close();
    });

    testWidgets('calculates total time correctly', (tester) async {
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

      // Sample routine: 20 + 10 + 15 + 5 = 50 min for tasks
      // Breaks: 2 enabled breaks of 2 min each = 4 min
      // Total: 54 min
      expect(find.text('54m'), findsOneWidget);

      bloc.close();
    });

    testWidgets('updates total time after adding task', (tester) async {
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

      // Initial total: 54m
      expect(find.text('54m'), findsOneWidget);

      // Add a new task (10 minutes = 600 seconds)
      bloc.add(const AddTask(name: 'New Task', estimatedDuration: 600));
      await tester.pumpAndSettle();

      // New total: 54 + 10 + 2 (break) = 66m displayed as "1h 6m"
      expect(find.text('1h 6m'), findsOneWidget);
      expect(find.text('54m'), findsNothing);

      bloc.close();
    });

    testWidgets('add new task button opens dialog', (tester) async {
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

      // Tap the Add New Task button
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Dialog should be displayed
      expect(
        find.text('Add New Task'),
        findsNWidgets(2),
      ); // Button and dialog title
      expect(find.text('Task Name'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsAtLeastNWidgets(1));

      bloc.close();
    });

    testWidgets('add task dialog validates empty name', (tester) async {
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

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Set a duration but no name
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Try to submit without entering a name
      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a task name'), findsOneWidget);

      bloc.close();
    });

    testWidgets('add task dialog validates empty duration', (tester) async {
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

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter only name, not duration
      await tester.enterText(find.byType(TextFormField), 'Test Task');
      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please select a duration'), findsOneWidget);

      bloc.close();
    });

    testWidgets('add task dialog validates zero duration', (tester) async {
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

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter name but don't set duration
      await tester.enterText(find.byType(TextFormField), 'Test Task');

      // Try to submit without selecting duration
      final addButton = find.ancestor(
        of: find.text('Add'),
        matching: find.byType(ElevatedButton),
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Should show error for no duration selected
      expect(find.text('Please select a duration'), findsOneWidget);

      bloc.close();
    });

    testWidgets('add task dialog successfully adds task', (tester) async {
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

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter task name
      await tester.enterText(find.byType(TextFormField), 'New Exercise');

      // Open time picker and select duration (default is 0:20)
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();

      // Accept the default time (0:20 = 20 minutes)
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Submit the form
      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.text('Task Name'), findsNothing);

      // New task should appear in the list
      expect(find.text('New Exercise'), findsOneWidget);
      // Note: "20 min" appears twice - once in Morning Workout and once in New Exercise
      expect(find.text('20 min'), findsNWidgets(2));

      bloc.close();
    });

    testWidgets('cancel button closes dialog without adding task', (
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

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      final initialTaskCount = bloc.state.model!.tasks.length;

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter some data but cancel
      await tester.enterText(find.byType(TextFormField), 'Test');
      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.text('Task Name'), findsNothing);

      // Task count should not change
      expect(bloc.state.model!.tasks.length, initialTaskCount);

      bloc.close();
    });

    testWidgets('total time displays hours and minutes for long durations', (
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

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Add tasks to exceed 1 hour (3600 seconds = 1 hour)
      bloc.add(const AddTask(name: 'Long Task 1', estimatedDuration: 3600));
      await tester.pumpAndSettle();

      // Should display in h m format - total should be 1h 56m
      // (54m initial + 60m new task + 2m break = 116m = 1h 56m)
      expect(find.text('1h 56m'), findsOneWidget);

      bloc.close();
    });

    testWidgets('estimated finish time updates correctly', (tester) async {
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

      // Get initial finish time
      final initialFinishTimeFinder = find.textContaining(':').last;
      expect(initialFinishTimeFinder, findsOneWidget);

      // Store the initial finish time text
      final initialFinishTime = tester
          .widget<Text>(initialFinishTimeFinder)
          .data;

      // Add a new task
      bloc.add(const AddTask(name: 'Additional Task', estimatedDuration: 600));
      await tester.pumpAndSettle();

      // Get updated finish time
      final updatedFinishTimeFinder = find.textContaining(':').last;
      final updatedFinishTime = tester
          .widget<Text>(updatedFinishTimeFinder)
          .data;

      // Finish time should change (we can't test exact time due to dynamic start time)
      expect(updatedFinishTime, isNot(equals(initialFinishTime)));

      bloc.close();
    });
  });
}
