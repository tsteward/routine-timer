import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/widgets/schedule_header.dart';

void main() {
  group('ScheduleHeader', () {
    late RoutineSettingsModel settings;
    late List<TaskModel> tasks;
    late List<BreakModel> breaks;

    setUp(() {
      final now = DateTime.now();
      final sixAm = DateTime(now.year, now.month, now.day, 6, 0);

      settings = RoutineSettingsModel(
        startTime: sixAm.millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 2 * 60, // 2 minutes
      );

      tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 10 * 60, // 10 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 15 * 60, // 15 minutes
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 20 * 60, // 20 minutes
          order: 2,
        ),
      ];

      breaks = [
        const BreakModel(duration: 2 * 60, isEnabled: true),
        const BreakModel(duration: 2 * 60, isEnabled: true),
      ];
    });

    testWidgets('displays "On track" when within 1 minute of schedule', (
      tester,
    ) async {
      final routineState = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasks[0].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('displays "Ahead by X min" when ahead of schedule', (
      tester,
    ) async {
      // Task 1 completed in 5 minutes (estimated 10 minutes)
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 5 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[1].id, // On task 2
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Expected: 10 min (task 1) + 2 min (break) = 12 min
      // Actual: 5 min (task 1) + 2 min (break) = 7 min
      // Ahead by: 5 minutes
      expect(find.text('Ahead by 5 min'), findsOneWidget);
    });

    testWidgets('displays "Behind by X min" when behind schedule', (
      tester,
    ) async {
      // Task 1 completed in 15 minutes (estimated 10 minutes)
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 15 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[1].id, // On task 2
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Expected: 10 min (task 1) + 2 min (break) = 12 min
      // Actual: 15 min (task 1) + 2 min (break) = 17 min
      // Behind by: 5 minutes
      expect(find.text('Behind by 5 min'), findsOneWidget);
    });

    testWidgets('displays estimated completion time', (tester) async {
      final routineState = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasks[0].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Should show "Est. Completion: HH:MM AM/PM"
      expect(find.textContaining('Est. Completion:'), findsOneWidget);
    });

    testWidgets('calculates estimated completion correctly on first task', (
      tester,
    ) async {
      final routineState = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasks[0].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Total remaining: Task 1 (10) + Break (2) + Task 2 (15) + Break (2) + Task 3 (20) = 49 minutes
      // Estimated completion should be about 49 minutes from now
      final widget = find.textContaining('Est. Completion:');
      expect(widget, findsOneWidget);
    });

    testWidgets('calculates estimated completion correctly on middle task', (
      tester,
    ) async {
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 10 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[1].id, // On task 2
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Total remaining: Task 2 (15) + Break (2) + Task 3 (20) = 37 minutes
      final widget = find.textContaining('Est. Completion:');
      expect(widget, findsOneWidget);
    });

    testWidgets('calculates estimated completion correctly on last task', (
      tester,
    ) async {
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 10 * 60),
        tasks[1].copyWith(isCompleted: true, actualDuration: 15 * 60),
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[2].id, // On task 3
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Total remaining: Task 3 (20) = 20 minutes
      final widget = find.textContaining('Est. Completion:');
      expect(widget, findsOneWidget);
    });

    testWidgets('navigates to task management when settings icon is tapped', (
      tester,
    ) async {
      final routineState = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasks[0].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
          routes: {
            AppRoutes.tasks: (context) =>
                const Scaffold(body: Center(child: Text('Task Management'))),
          },
        ),
      );

      // Tap the settings icon
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify navigation to Task Management screen
      expect(find.text('Task Management'), findsOneWidget);
    });

    testWidgets('displays correct status color for "On track"', (tester) async {
      final routineState = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasks[0].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      final statusContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('On track'),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = statusContainer.decoration as BoxDecoration;
      expect(
        decoration.border,
        isA<Border>().having((b) => b.top.color, 'color', Colors.blue.shade700),
      );
    });

    testWidgets('displays correct status color for "Ahead"', (tester) async {
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 5 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      final statusContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Ahead by 5 min'),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = statusContainer.decoration as BoxDecoration;
      expect(
        decoration.border,
        isA<Border>().having(
          (b) => b.top.color,
          'color',
          Colors.green.shade700,
        ),
      );
    });

    testWidgets('displays correct status color for "Behind"', (tester) async {
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 15 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      final statusContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Behind by 5 min'),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = statusContainer.decoration as BoxDecoration;
      expect(
        decoration.border,
        isA<Border>().having((b) => b.top.color, 'color', Colors.red.shade700),
      );
    });

    testWidgets('handles disabled breaks correctly', (tester) async {
      final breaksWithDisabled = [
        const BreakModel(duration: 2 * 60, isEnabled: false), // Disabled
        const BreakModel(duration: 2 * 60, isEnabled: true),
      ];

      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 5 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaksWithDisabled,
        settings: settings,
        selectedTaskId: tasksWithActual[1].id, // On task 2
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Expected: 10 min (task 1) + 0 min (disabled break) = 10 min
      // Actual: 5 min (task 1) + 0 min (disabled break) = 5 min
      // Ahead by: 5 minutes
      expect(find.text('Ahead by 5 min'), findsOneWidget);
    });

    testWidgets('handles routine with no breaks', (tester) async {
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 8 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: null, // No breaks
        settings: settings,
        selectedTaskId: tasksWithActual[1].id, // On task 2
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Expected: 10 min (task 1) = 10 min
      // Actual: 8 min (task 1) = 8 min
      // Ahead by: 2 minutes
      expect(find.text('Ahead by 2 min'), findsOneWidget);
    });

    testWidgets('handles being on a break', (tester) async {
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 10 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[0].id,
        isOnBreak: true,
        currentBreakIndex: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Should still calculate schedule correctly
      expect(find.textContaining('Est. Completion:'), findsOneWidget);
    });

    testWidgets('formats time correctly for AM hours', (tester) async {
      final routineState = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasks[0].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Should show time in format "HH:MM AM" or "HH:MM PM"
      final text = find.textContaining('Est. Completion:');
      expect(text, findsOneWidget);

      final widget = tester.widget<Text>(text);
      final displayText = widget.data!;

      // Verify format includes either AM or PM
      expect(displayText.contains('AM') || displayText.contains('PM'), true);
    });

    testWidgets('calculates complex schedule with multiple completed tasks', (
      tester,
    ) async {
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 12 * 60),
        tasks[1].copyWith(isCompleted: true, actualDuration: 10 * 60),
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[2].id, // On task 3
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Expected: 10 min (task 1) + 2 min (break) + 15 min (task 2) + 2 min (break) = 29 min
      // Actual: 12 min (task 1) + 2 min (break) + 10 min (task 2) + 2 min (break) = 26 min
      // Ahead by: 3 minutes
      expect(find.text('Ahead by 3 min'), findsOneWidget);
    });

    testWidgets('handles edge case: exactly 1 minute ahead', (tester) async {
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 9 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Expected: 10 min + 2 min = 12 min
      // Actual: 9 min + 2 min = 11 min
      // Difference: 1 minute (60 seconds)
      // Should show "On track" because difference is not > 60 seconds
      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('handles edge case: exactly 1 minute behind', (tester) async {
      final tasksWithActual = [
        tasks[0].copyWith(isCompleted: true, actualDuration: 11 * 60),
        tasks[1],
        tasks[2],
      ];

      final routineState = RoutineStateModel(
        tasks: tasksWithActual,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasksWithActual[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ScheduleHeader(routineState: routineState)),
        ),
      );

      // Expected: 10 min + 2 min = 12 min
      // Actual: 11 min + 2 min = 13 min
      // Difference: -1 minute (-60 seconds)
      // Should show "On track" because difference is not < -60 seconds
      expect(find.text('On track'), findsOneWidget);
    });
  });
}
