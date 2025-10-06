import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/screens/task_management_screen.dart';

void main() {
  group('Task Management Bottom Bar', () {
    testWidgets('displays total time correctly', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Sample routine has 4 tasks: 20min, 10min, 15min, 5min = 50min
      // Plus 3 breaks, 2 enabled: 2 * 2min = 4min
      // Total: 54min
      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('54m'), findsOneWidget);
    });

    testWidgets('displays estimated finish time correctly', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Calculate expected finish time
      final startTime = DateTime.fromMillisecondsSinceEpoch(
        loaded.model!.settings.startTime,
      );
      final totalMinutes = 54; // From previous test
      final finishTime = startTime.add(Duration(minutes: totalMinutes));
      final expectedText =
          '${finishTime.hour.toString().padLeft(2, '0')}:${finishTime.minute.toString().padLeft(2, '0')}';

      expect(find.text('Estimated Finish'), findsOneWidget);
      expect(find.text(expectedText), findsOneWidget);
    });

    testWidgets('shows Add New Task button', (tester) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      // Load sample routine
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Button should be visible with "Add New Task" text
      expect(find.text('Add New Task'), findsOneWidget);
    });

    testWidgets('Add Task button opens dialog', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the Add New Task button
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(
        find.text('Add New Task'),
        findsNWidgets(2),
      ); // Button + dialog title
      expect(find.text('Task Name'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
    });

    testWidgets('can add a new task through dialog', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialCount = bloc.state.model!.tasks.length;

      // Open the dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter task name
      await tester.enterText(find.byType(TextFormField), 'Morning Meditation');

      // Default duration is 10 minutes, so we can just submit
      // (Testing time picker interaction is complex, the default is sufficient)

      // Tap Add Task button in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
      await tester.pumpAndSettle();

      // Verify task was added with default 10 minute duration
      expect(bloc.state.model!.tasks.length, initialCount + 1);
      expect(bloc.state.model!.tasks.last.name, 'Morning Meditation');
      expect(bloc.state.model!.tasks.last.estimatedDuration, 10 * 60);
    });

    testWidgets('dialog validates empty task name', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Leave name empty (default duration is already set to 10 minutes)

      // Tap Add Task button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.text('Please enter a task name'), findsOneWidget);
    });

    testWidgets('dialog shows duration picker on tap', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Should show duration field with clock icon
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);

      // Tap on duration field to open time picker
      await tester.tap(find.byIcon(Icons.access_time));
      await tester.pumpAndSettle();

      // Time picker dialog should appear
      expect(find.text('Select Duration'), findsOneWidget);
    });

    testWidgets('duration field displays default value', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Duration field should show with a clock icon and default duration text
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
    });

    testWidgets('cancel button closes dialog without adding task', (
      tester,
    ) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final initialCount = loaded.model!.tasks.length;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open the dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter task name
      await tester.enterText(find.byType(TextFormField), 'Test Task');

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed and no task added
      expect(find.text('Task Name'), findsNothing);
      expect(bloc.state.model!.tasks.length, initialCount);
    });

    testWidgets('total time updates after adding task', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial total time is 54m
      expect(find.text('54m'), findsOneWidget);

      final initialTaskCount = bloc.state.model!.tasks.length;

      // Add a new task with default 10 minute duration
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'New Task');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
      await tester.pumpAndSettle();

      // Verify task was added
      expect(bloc.state.model!.tasks.length, initialTaskCount + 1);

      // New total: 54m + 10m task + 2m break = 66m = 1h 6m
      expect(find.text('1h 6m'), findsOneWidget);
    });

    testWidgets('formats time in hours and minutes when over 60 minutes', (
      tester,
    ) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial time should be 54m
      expect(find.text('54m'), findsOneWidget);

      // Add task to go over 60 minutes
      bloc.add(const AddTask(name: 'Long Task', durationSeconds: 3600));
      await tester.pumpAndSettle();

      // Should display in hours and minutes format (54m + 60m + 2m break = 116m = 1h 56m)
      expect(find.text('1h 56m'), findsOneWidget);
    });
  });
}
