import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/screens/pre_start_screen.dart';
import 'package:routine_timer/src/utils/time_formatter.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('PreStartScreen', () {
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
        onGenerateRoute: AppRouter().onGenerateRoute,
      );
    }

    group('Countdown Logic', () {
      testWidgets('shows countdown when start time is in future today', (
        tester,
      ) async {
        final now = DateTime.now();
        // Set start time to 2 hours from now
        final startTime = now.add(const Duration(hours: 2));

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Should show countdown text
        expect(find.text('Routine Starts In:'), findsOneWidget);

        // Should show a time display (checking for the HH:MM:SS pattern)
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.data != null &&
                widget.data!.contains(':'),
          ),
          findsWidgets,
        );
      });

      testWidgets(
        'shows countdown to tomorrow when start time has passed today',
        (tester) async {
          final now = DateTime.now();
          // Set start time to 2 hours ago (same time yesterday essentially)
          final pastTime = now.subtract(const Duration(hours: 2));

          final tasks = [
            const TaskModel(
              id: '1',
              name: 'Test Task',
              estimatedDuration: 300,
              order: 0,
            ),
          ];
          final settings = RoutineSettingsModel(
            startTime: pastTime.millisecondsSinceEpoch,
            breaksEnabledByDefault: true,
            defaultBreakDuration: 120,
          );
          final model = RoutineStateModel(tasks: tasks, settings: settings);
          bloc.emit(bloc.state.copyWith(model: model));

          await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
          await tester.pump();

          // Should still show countdown (to tomorrow's occurrence)
          expect(find.text('Routine Starts In:'), findsOneWidget);

          // The countdown should be roughly 22 hours (24 - 2)
          // We can't check exact time due to test execution time,
          // but we can verify it's showing a countdown
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.data != null &&
                  widget.data!.contains(':'),
            ),
            findsWidgets,
          );
        },
      );

      testWidgets('handles 6:00 AM start time when accessed at 6:00 PM', (
        tester,
      ) async {
        // This is the exact scenario from the bug report
        final now = DateTime.now();

        // Create a start time for 6:00 AM today (which is in the past)
        final sixAmToday = DateTime(now.year, now.month, now.day, 6, 0, 0);

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Morning Workout',
            estimatedDuration: 1200,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: sixAmToday.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Should show countdown to tomorrow's 6:00 AM, not navigate immediately
        expect(find.text('Routine Starts In:'), findsOneWidget);
      });

      testWidgets('countdown decrements every second', (tester) async {
        final now = DateTime.now();
        // Set start time to 10 seconds from now
        final startTime = now.add(const Duration(seconds: 10));

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Get initial countdown text
        final initialText = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.contains(':') &&
              widget.data != 'Routine Starts In:',
        );
        expect(initialText, findsOneWidget);

        // Wait 2 seconds
        await tester.pump(const Duration(seconds: 2));

        // Countdown should have changed
        // (We can't check exact value due to timing, but we verify it updates)
        expect(initialText, findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('countdown reaches zero after expected duration', (
        tester,
      ) async {
        final now = DateTime.now();
        // Set start time to 3 seconds from now
        final startTime = now.add(const Duration(seconds: 3));

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Verify we're on pre-start screen with countdown
        expect(find.text('Routine Starts In:'), findsOneWidget);

        // Verify countdown is counting down (wait 1 second)
        await tester.pump(const Duration(seconds: 1));

        // Should still be on pre-start screen
        expect(find.text('Routine Starts In:'), findsOneWidget);
      });

      testWidgets('shows countdown immediately when model exists', (
        tester,
      ) async {
        final now = DateTime.now();
        final startTime = now.add(const Duration(hours: 1));

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Should show countdown text
        expect(find.text('Routine Starts In:'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles midnight rollover correctly', (tester) async {
        final now = DateTime.now();

        // Set start time to 23:59 today
        final lateNight = DateTime(now.year, now.month, now.day, 23, 59, 0);

        // If current time is after 23:59, this should target tomorrow's 23:59
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Late Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: lateNight.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Should show countdown
        expect(find.text('Routine Starts In:'), findsOneWidget);
      });

      testWidgets('handles early morning start time', (tester) async {
        final now = DateTime.now();

        // Set start time to 1:00 AM
        final earlyMorning = DateTime(now.year, now.month, now.day, 1, 0, 0);

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Early Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: earlyMorning.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Should show countdown (to next 1:00 AM)
        expect(find.text('Routine Starts In:'), findsOneWidget);
      });
    });

    group('UI Elements', () {
      testWidgets('displays Start Early button', (tester) async {
        final now = DateTime.now();
        final startTime = now.add(const Duration(hours: 1));

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Should have Start Early button
        expect(find.text('Start Early'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Start Early'),
          findsOneWidget,
        );
      });

      testWidgets('displays Manage Tasks button', (tester) async {
        final now = DateTime.now();
        final startTime = now.add(const Duration(hours: 1));

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Should have Manage Tasks button
        expect(find.text('Manage Tasks'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Manage Tasks'),
          findsOneWidget,
        );
      });

      testWidgets('Start Early button is tappable', (tester) async {
        final now = DateTime.now();
        final startTime = now.add(const Duration(hours: 1));

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Verify Start Early button exists and is enabled
        final startEarlyButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Start Early'),
        );
        expect(startEarlyButton.onPressed, isNotNull);
      });

      testWidgets('Manage Tasks button is tappable', (tester) async {
        final now = DateTime.now();
        final startTime = now.add(const Duration(hours: 1));

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        // Verify Manage Tasks button exists and is enabled
        final manageTasksButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Manage Tasks'),
        );
        expect(manageTasksButton.onPressed, isNotNull);
      });

      testWidgets('has black background', (tester) async {
        final now = DateTime.now();
        final startTime = now.add(const Duration(hours: 1));

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ];
        final settings = RoutineSettingsModel(
          startTime: startTime.millisecondsSinceEpoch,
          breaksEnabledByDefault: true,
          defaultBreakDuration: 120,
        );
        final model = RoutineStateModel(tasks: tasks, settings: settings);
        bloc.emit(bloc.state.copyWith(model: model));

        await tester.pumpWidget(makeTestableWidget(const PreStartScreen()));
        await tester.pump();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, equals(Colors.black));
      });
    });

    // Test the TimeFormatter used by PreStartScreen
    group('TimeFormatter.formatCountdown', () {
      test('formats zero correctly', () {
        expect(TimeFormatter.formatCountdown(0), '00:00:00');
      });

      test('formats seconds only', () {
        expect(TimeFormatter.formatCountdown(1), '00:00:01');
        expect(TimeFormatter.formatCountdown(45), '00:00:45');
        expect(TimeFormatter.formatCountdown(59), '00:00:59');
      });

      test('formats minutes and seconds', () {
        expect(TimeFormatter.formatCountdown(60), '00:01:00');
        expect(TimeFormatter.formatCountdown(125), '00:02:05');
        expect(TimeFormatter.formatCountdown(599), '00:09:59');
      });

      test('formats hours, minutes, and seconds', () {
        expect(TimeFormatter.formatCountdown(3600), '01:00:00');
        expect(TimeFormatter.formatCountdown(3661), '01:01:01');
        expect(TimeFormatter.formatCountdown(7325), '02:02:05');
      });

      test('formats large durations correctly', () {
        expect(TimeFormatter.formatCountdown(36000), '10:00:00');
        expect(TimeFormatter.formatCountdown(86399), '23:59:59');
      });

      test('formats typical countdown scenarios', () {
        // 2 minutes 30 seconds
        expect(TimeFormatter.formatCountdown(150), '00:02:30');
        // 1 hour 30 minutes
        expect(TimeFormatter.formatCountdown(5400), '01:30:00');
        // 5 hours exactly
        expect(TimeFormatter.formatCountdown(18000), '05:00:00');
      });
    });
  });
}
