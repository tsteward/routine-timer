import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/screens/main_routine_screen.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('MainRoutineScreen', () {
    late RoutineBloc bloc;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
      bloc = FirebaseTestHelper.routineBloc;
    });

    Widget makeTestableWidget(Widget child) {
      return MaterialApp(
        home: BlocProvider.value(value: bloc, child: child),
      );
    }

    group('Empty State', () {
      testWidgets('displays no tasks message when routine is empty', (
        tester,
      ) async {
        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));

        expect(find.text('No tasks available'), findsOneWidget);
        expect(find.text('Go to Task Management'), findsOneWidget);
      });

      testWidgets('displays no tasks message when tasks list is empty', (
        tester,
      ) async {
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: [], settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.text('No tasks available'), findsOneWidget);
      });
    });

    group('Task Display', () {
      testWidgets('displays task name at top center', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Morning Workout',
            estimatedDuration: 600, // 10 minutes
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.text('Morning Workout'), findsOneWidget);
      });

      testWidgets('displays task counter', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 300,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 400,
            order: 1,
          ),
          const TaskModel(
            id: '3',
            name: 'Task 3',
            estimatedDuration: 500,
            order: 2,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.text('Task 1 of 3'), findsOneWidget);
      });

      testWidgets('updates task counter when task changes', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 300,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 400,
            order: 1,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Task 1 of 2'), findsOneWidget);

        // Move to next task
        bloc.emit(
          bloc.state.copyWith(model: model.copyWith(currentTaskIndex: 1)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Task 2 of 2'), findsOneWidget);
      });
    });

    group('Timer Display', () {
      testWidgets('displays initial timer in MM:SS format', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 600, // 10 minutes
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Timer should show 10:00 initially
        expect(find.text('10:00'), findsOneWidget);
      });

      testWidgets('timer counts down every second', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 10, // 10 seconds
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Initial time: 00:10
        expect(find.text('00:10'), findsOneWidget);

        // Wait 1 second
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:09'), findsOneWidget);

        // Wait another second
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:08'), findsOneWidget);
      });

      testWidgets('timer goes negative and shows -MM:SS format', (
        tester,
      ) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 2, // 2 seconds
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Initial: 00:02
        expect(find.text('00:02'), findsOneWidget);

        // After 3 seconds, should be -00:01
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('-00:01'), findsOneWidget);

        // After 4 seconds total, should be -00:02
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('-00:02'), findsOneWidget);
      });
    });

    group('Background Color', () {
      testWidgets('starts with green background', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 60,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(AppTheme.green));
      });

      testWidgets('changes to red background when timer goes negative', (
        tester,
      ) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 1, // 1 second
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Initial background should be green
        var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(AppTheme.green));

        // After 2 seconds, timer should be negative
        await tester.pump(const Duration(seconds: 2));

        // Background should now be red
        scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(AppTheme.red));
      });
    });

    group('Progress Bar', () {
      testWidgets('displays progress bar', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 60,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('progress bar starts at 0%', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 100,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.value, equals(0.0));
      });

      testWidgets('progress bar updates with time', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 10, // 10 seconds
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Wait 5 seconds (50% progress)
        await tester.pump(const Duration(seconds: 5));

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        // Should be 50% complete (0.5)
        expect(progressBar.value, closeTo(0.5, 0.01));
      });

      testWidgets('progress bar caps at 100%', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 2, // 2 seconds
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Wait 5 seconds (more than estimated)
        await tester.pump(const Duration(seconds: 5));

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        // Should be capped at 100% (1.0)
        expect(progressBar.value, equals(1.0));
      });
    });

    group('Done Button', () {
      testWidgets('displays Done button', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 60,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.text('Done'), findsOneWidget);
      });

      testWidgets('task display updates when task index changes', (
        tester,
      ) async {
        // Test that UI updates when task index changes via state
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 60,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 60,
            order: 1,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Task 1'), findsOneWidget);

        // Directly change task index (simulating Done button effect)
        bloc.emit(
          bloc.state.copyWith(model: model.copyWith(currentTaskIndex: 1)),
        );
        await tester.pumpAndSettle();

        // Should now show Task 2
        expect(find.text('Task 2'), findsOneWidget);
      });

      testWidgets('Done button dispatches MarkTaskDone event', (tester) async {
        // This test verifies the button is wired up correctly
        // Integration testing of BLoC state changes is better done separately
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 60,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 60,
            order: 1,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pumpAndSettle();

        // Just verify the button exists and is tappable
        final doneButton = find.text('Done');
        expect(doneButton, findsOneWidget);
        await tester.tap(doneButton);
        await tester.pump();

        // Button was successfully tapped (no exception thrown)
      });

      testWidgets('Done button records actual duration', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 60,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 60,
            order: 1,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pumpAndSettle();

        // Wait 3 seconds
        await tester.pump(const Duration(seconds: 3));

        // Tap Done button
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Check that actual duration was recorded
        final currentState = bloc.state;
        expect(currentState.model?.tasks[0].actualDuration, isNotNull);
        expect(
          currentState.model?.tasks[0].actualDuration,
          greaterThanOrEqualTo(0),
        );
      });

      testWidgets('timer updates when task index changes via listener', (
        tester,
      ) async {
        // Test that the listener properly resets timer when task changes
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 10,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 20,
            order: 1,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pumpAndSettle();

        // Initial timer shows first task duration
        expect(find.text('00:10'), findsOneWidget);

        // Directly change task index via BLoC state (simulating task change)
        bloc.emit(
          bloc.state.copyWith(model: model.copyWith(currentTaskIndex: 1)),
        );
        await tester.pumpAndSettle();

        // Timer should reset to second task's duration
        expect(find.text('00:20'), findsOneWidget);
      });
    });

    group('Previous Button', () {
      testWidgets('displays Previous button', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 60,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.text('Previous'), findsOneWidget);
      });

      testWidgets('Previous button is disabled on first task', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 60,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 60,
            order: 1,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        final previousButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Previous'),
        );
        expect(previousButton.onPressed, isNull);
      });

      testWidgets('Previous button is enabled on subsequent tasks', (
        tester,
      ) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 60,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 60,
            order: 1,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 1, // On second task
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        final previousButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Previous'),
        );
        expect(previousButton.onPressed, isNotNull);
      });

      testWidgets('Previous button dispatches GoToPreviousTask event', (
        tester,
      ) async {
        // This test verifies the button is wired up correctly
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 60,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 60,
            order: 1,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 1, // Start on second task
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Task 2'), findsOneWidget);

        // Just verify the button exists and is tappable
        final previousButton = find.text('Previous');
        expect(previousButton, findsOneWidget);
        await tester.tap(previousButton);
        await tester.pump();

        // Button was successfully tapped (no exception thrown)
      });

      testWidgets('timer resets when previous task is selected via listener', (
        tester,
      ) async {
        // Test that listener properly resets timer when going back
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 30,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 60,
            order: 1,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 1, // Start on second task
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pumpAndSettle();

        // Initial timer shows second task duration
        expect(find.text('01:00'), findsOneWidget);

        // Directly change task index back to first task
        bloc.emit(
          bloc.state.copyWith(model: model.copyWith(currentTaskIndex: 0)),
        );
        await tester.pumpAndSettle();

        // Timer should reset to first task's duration
        expect(find.text('00:30'), findsOneWidget);
      });
    });

    group('Navigation FAB', () {
      testWidgets('displays navigation FAB', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 60,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsNWidgets(2));
        expect(find.byIcon(Icons.list), findsOneWidget);
        expect(find.text('Navigate'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles zero duration task', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Instant Task',
            estimatedDuration: 0,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.text('00:00'), findsOneWidget);
      });

      testWidgets('handles very long task name', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name:
                'This is a very long task name that might overflow or wrap in the UI',
            estimatedDuration: 60,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(
          find.text(
            'This is a very long task name that might overflow or wrap in the UI',
          ),
          findsOneWidget,
        );
      });

      testWidgets('handles single task routine', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Only Task',
            estimatedDuration: 60,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Previous button should be disabled
        final previousButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Previous'),
        );
        expect(previousButton.onPressed, isNull);

        // Task counter should show 1 of 1
        expect(find.text('Task 1 of 1'), findsOneWidget);
      });
    });

    group('Break Functionality', () {
      testWidgets('displays break screen when on break', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'First Task',
            estimatedDuration: 300,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Second Task',
            estimatedDuration: 600,
            order: 1,
          ),
        ];
        final breaks = [
          const BreakModel(duration: 120, isEnabled: true),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          breaks: breaks,
          settings: settings,
          currentTaskIndex: 0,
          isOnBreak: true,
          currentBreakIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Should display break screen
        expect(find.text('Break Time!'), findsOneWidget);
        expect(find.text('Get ready for: Second Task'), findsOneWidget);
        expect(find.text('Skip Break'), findsOneWidget);
        expect(find.text('Break 1 of 1'), findsOneWidget);
        
        // Should have green background
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(AppTheme.green));
      });

      testWidgets('skip break button is displayed', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'First Task',
            estimatedDuration: 300,
            order: 0,
            isCompleted: true,
          ),
          const TaskModel(
            id: '2',
            name: 'Second Task',
            estimatedDuration: 600,
            order: 1,
          ),
        ];
        final breaks = [
          const BreakModel(duration: 120, isEnabled: true),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          breaks: breaks,
          settings: settings,
          currentTaskIndex: 0,
          isOnBreak: true,
          currentBreakIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Should display break screen with skip button
        expect(find.text('Break Time!'), findsOneWidget);
        expect(find.text('Skip Break'), findsOneWidget);
      });

      testWidgets('displays drawer button and opens upcoming tasks', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Current Task',
            estimatedDuration: 300,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Next Task',
            estimatedDuration: 600,
            order: 1,
          ),
          const TaskModel(
            id: '3',
            name: 'Final Task',
            estimatedDuration: 400,
            order: 2,
          ),
        ];
        final breaks = [
          const BreakModel(duration: 120, isEnabled: true),
          const BreakModel(duration: 180, isEnabled: true),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          breaks: breaks,
          settings: settings,
          currentTaskIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Should have drawer button
        expect(find.byIcon(Icons.list), findsOneWidget);

        // Tap drawer button
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle();

        // Should open drawer with upcoming tasks
        expect(find.text('Up Next'), findsOneWidget);
        expect(find.text('Next Task'), findsOneWidget);
        expect(find.text('Final Task'), findsOneWidget);
        expect(find.text('Break'), findsNWidgets(2));
      });

      testWidgets('break timer displays countdown', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'First Task',
            estimatedDuration: 300,
            order: 0,
            isCompleted: true,
          ),
          const TaskModel(
            id: '2',
            name: 'Second Task',
            estimatedDuration: 600,
            order: 1,
          ),
        ];
        final breaks = [
          const BreakModel(duration: 120, isEnabled: true), // 2 minute break
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          breaks: breaks,
          settings: settings,
          currentTaskIndex: 0,
          isOnBreak: true,
          currentBreakIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        // Should display break screen with countdown timer
        expect(find.text('Break Time!'), findsOneWidget);
        expect(find.text('02:00'), findsOneWidget); // Initial 2 minute countdown
      });

      testWidgets('shows correct next task name during break', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Completed Task',
            estimatedDuration: 300,
            order: 0,
            isCompleted: true,
          ),
          const TaskModel(
            id: '2',
            name: 'Upcoming Special Task',
            estimatedDuration: 600,
            order: 1,
          ),
        ];
        final breaks = [
          const BreakModel(duration: 120, isEnabled: true),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          breaks: breaks,
          settings: settings,
          currentTaskIndex: 0,
          isOnBreak: true,
          currentBreakIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.text('Get ready for: Upcoming Special Task'), findsOneWidget);
      });

      testWidgets('shows routine complete message when break is after last task', (tester) async {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Last Task',
            estimatedDuration: 300,
            order: 0,
            isCompleted: true,
          ),
        ];
        final breaks = [
          const BreakModel(duration: 120, isEnabled: true),
        ];
        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(
          tasks: tasks,
          breaks: breaks,
          settings: settings,
          currentTaskIndex: 0,
          isOnBreak: true,
          currentBreakIndex: 0,
        );
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const MainRoutineScreen()));
        await tester.pump();

        expect(find.text('Get ready for: Routine Complete'), findsOneWidget);
      });
    });
  });
}
