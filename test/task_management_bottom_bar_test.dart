import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/screens/task_management_screen.dart';

void main() {
  group('TaskManagementScreen Bottom Bar', () {
    testWidgets('displays total time correctly', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total Time'), findsOneWidget);
      // The sample routine has 4 tasks: 20min, 10min, 15min, 5min = 50min
      // Plus breaks (2min each, 2 enabled): 54min total
      expect(find.textContaining('54m'), findsOneWidget);

      bloc.close();
    });

    testWidgets('displays estimated finish time correctly', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Est. Finish Time'), findsOneWidget);
      // Should display time in 12-hour format with AM/PM
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              (widget.data!.contains('AM') || widget.data!.contains('PM')),
        ),
        findsAtLeastNWidgets(1),
      );

      bloc.close();
    });

    testWidgets('displays Add New Task button', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add New Task'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      bloc.close();
    });

    testWidgets('opens add task dialog when button tapped', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

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

      // Dialog should be displayed
      expect(
        find.text('Add New Task'),
        findsNWidgets(2),
      ); // Button + dialog title
      expect(find.text('Task Name'), findsOneWidget);
      expect(find.text('Duration (minutes)'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);

      bloc.close();
    });

    testWidgets('adds task through dialog', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialTaskCount = bloc.state.model!.tasks.length;

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter task details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task Name'),
        'Test Task',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '25',
      );

      // Submit
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Verify task was added
      expect(bloc.state.model!.tasks.length, initialTaskCount + 1);
      expect(bloc.state.model!.tasks.last.name, 'Test Task');
      expect(bloc.state.model!.tasks.last.estimatedDuration, 25 * 60);

      bloc.close();
    });

    testWidgets('cancels add task dialog', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialTaskCount = bloc.state.model!.tasks.length;

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify no task was added
      expect(bloc.state.model!.tasks.length, initialTaskCount);

      bloc.close();
    });

    testWidgets('validates empty task name', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Leave task name empty and enter duration
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '25',
      );

      // Try to submit
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Please enter a task name'), findsOneWidget);

      bloc.close();
    });

    testWidgets('validates empty duration', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter task name but leave duration empty
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task Name'),
        'Test Task',
      );

      // Try to submit
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Please enter a duration'), findsOneWidget);

      bloc.close();
    });

    testWidgets('validates invalid duration (non-numeric)', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter task details with invalid duration
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task Name'),
        'Test Task',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        'abc',
      );

      // Try to submit
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Please enter a valid positive number'), findsOneWidget);

      bloc.close();
    });

    testWidgets('validates negative duration', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter task details with negative duration
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task Name'),
        'Test Task',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '-5',
      );

      // Try to submit
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Please enter a valid positive number'), findsOneWidget);

      bloc.close();
    });

    testWidgets('validates zero duration', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Enter task details with zero duration
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task Name'),
        'Test Task',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '0',
      );

      // Try to submit
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Please enter a valid positive number'), findsOneWidget);

      bloc.close();
    });

    testWidgets('total time updates after adding task', (tester) async {
      final bloc = RoutineBloc();
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial total time should be 54m (50m tasks + 4m breaks)
      expect(find.textContaining('54m'), findsOneWidget);

      // Add a new 10-minute task
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task Name'),
        'New Task',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '10',
      );

      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Total time should now be 66m (54m + 10m task + 2m break)
      expect(find.text('1h 6m'), findsOneWidget);

      bloc.close();
    });

    testWidgets('hides bottom bar when loading', (tester) async {
      final bloc = RoutineBloc();
      // Don't load sample routine, so state is loading

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pump();

      // Bottom bar should not be visible
      expect(find.text('Total Time'), findsNothing);
      expect(find.text('Est. Finish Time'), findsNothing);
      expect(find.text('Add New Task'), findsNothing);

      bloc.close();
    });
  });
}
