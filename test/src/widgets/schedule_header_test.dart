import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/widgets/schedule_header.dart';

void main() {
  group('ScheduleHeader', () {
    late RoutineSettingsModel settings;

    setUp(() {
      // Default settings for tests
      settings = RoutineSettingsModel(
        startTime: DateTime(2025, 10, 14, 6, 0).millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120, // 2 minutes
      );
    });

    testWidgets('displays header with schedule status and settings button', (
      tester,
    ) async {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks.first.id,
      );

      bool settingsTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              onSettingsTap: () => settingsTapped = true,
            ),
          ),
        ),
      );

      // Should display settings button
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Tap settings button
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(settingsTapped, isTrue);
    });

    testWidgets('displays "On track" when variance is minimal', (tester) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:10 AM (10 min elapsed)
      // Task 1 completed in 605 seconds (10 min 5 sec)
      // Variance: 605 - 600 = 5 seconds (within 30 sec threshold = on track)
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
          isCompleted: true,
          actualDuration: 605, // 10 min 5 sec
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(
                2025,
                10,
                14,
                6,
                10,
              ), // 10 min after scheduled start
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('displays "Ahead by X min" when ahead of schedule', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:05 AM (5 min = 300 sec elapsed)
      // Task 1 completed in 600 seconds (10 min)
      // Variance: 600 - 300 = 300 seconds = 5 min ahead
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 minutes estimated
          order: 0,
          isCompleted: true,
          actualDuration: 600, // 10 minutes actual
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(
                2025,
                10,
                14,
                6,
                5,
              ), // 5 min after scheduled start
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ahead by 5 min'), findsOneWidget);
    });

    testWidgets('displays "Behind by X min" when behind schedule', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:15 AM (15 min = 900 sec elapsed)
      // Task 1 completed in 600 seconds (10 min)
      // Variance: 600 - 900 = -300 seconds = 5 min behind
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 minutes estimated
          order: 0,
          isCompleted: true,
          actualDuration: 600, // 10 minutes actual
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(
                2025,
                10,
                14,
                6,
                15,
              ), // 15 min after scheduled start
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Behind by 5 min'), findsOneWidget);
    });

    testWidgets('displays "Ahead by X min Y sec" with seconds precision', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:04:15 (4 min 15 sec = 255 sec elapsed)
      // Task 1 completed in 600 seconds (10 min)
      // Variance: 600 - 255 = 345 seconds = 5 min 45 sec ahead
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 minutes estimated
          order: 0,
          isCompleted: true,
          actualDuration: 600, // 10 min actual
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(
                2025,
                10,
                14,
                6,
                4,
                15,
              ), // 4 min 15 sec after scheduled start
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ahead by 5 min 45 sec'), findsOneWidget);
    });

    testWidgets('includes break time in schedule calculation', (tester) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:12 AM (12 min = 720 sec elapsed)
      // Task 1: 600 sec + Break: 120 sec = 720 sec completed
      // Variance: 720 - 720 = 0 (on track)
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 minutes
          order: 0,
          isCompleted: true,
          actualDuration: 600,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
        ),
      ];

      final breaks = [
        const BreakModel(duration: 120, isEnabled: true), // 2 min break
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(
                2025,
                10,
                14,
                6,
                12,
              ), // 12 min after scheduled start
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Should be on track since actual = expected (including break)
      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('excludes disabled breaks from schedule calculation', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:10 AM (10 min = 600 sec elapsed)
      // Task 1: 600 sec (disabled break not counted)
      // Variance: 600 - 600 = 0 (on track)
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
          isCompleted: true,
          actualDuration: 600,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
        ),
      ];

      final breaks = [
        const BreakModel(duration: 120, isEnabled: false), // Disabled break
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(
                2025,
                10,
                14,
                6,
                10,
              ), // 10 min after scheduled start
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Should be on track (no break time counted)
      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('calculates completion time correctly when on track', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:10 AM (10 min elapsed since scheduled start)
      // Task 1 completed in 600 seconds (10 min) - exactly on schedule
      // Variance: 600 - 600 = 0 (on track)
      // Remaining: Task 2 (5 min = 300 sec)
      // Adjusted remaining: 300 - 0 = 300 sec
      // Completion: 6:10 AM + 5 min = 6:15 AM
      final now = DateTime(2025, 10, 14, 6, 10);

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 min
          order: 0,
          isCompleted: true,
          actualDuration: 600,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300, // 5 min
          order: 1,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: now,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Est. Completion: 6:15 AM'), findsOneWidget);
    });

    testWidgets('adjusts completion time when ahead of schedule', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:05 AM (5 min elapsed)
      // Task 1 completed in 600 seconds (10 min)
      // Variance: 600 - 300 = 300 seconds = 5 min ahead
      // Remaining: Task 2 (10 min = 600 sec)
      // Adjusted remaining: 600 - 300 = 300 sec = 5 min
      // Completion: 6:05 AM + 5 min = 6:10 AM
      final now = DateTime(2025, 10, 14, 6, 5);

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 min estimated
          order: 0,
          isCompleted: true,
          actualDuration: 600, // 10 min actual
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 600, // 10 min
          order: 1,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: now,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Est. Completion: 6:10 AM'), findsOneWidget);
    });

    testWidgets('adjusts completion time when behind schedule', (tester) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:15 AM (15 min = 900 sec elapsed)
      // Task 1 completed in 600 seconds (10 min)
      // Variance: 600 - 900 = -300 seconds = 5 min behind
      // Remaining: Task 2 (10 min = 600 sec)
      // Adjusted remaining: 600 - (-300) = 900 sec = 15 min
      // Completion: 6:15 AM + 15 min = 6:30 AM
      final now = DateTime(2025, 10, 14, 6, 15);

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 min estimated
          order: 0,
          isCompleted: true,
          actualDuration: 600, // 10 min actual
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 600, // 10 min
          order: 1,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: now,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Est. Completion: 6:30 AM'), findsOneWidget);
    });

    testWidgets('handles PM times correctly', (tester) async {
      // Scheduled start: 11:30 PM
      // Current time: 11:30 PM (0 sec elapsed - exactly on schedule start)
      // No tasks completed yet
      // Variance: 0 - 0 = 0 (on track)
      // Remaining: 1800 sec (30 min)
      // Adjusted: 1800 - 0 = 1800 sec = 30 min
      // Completion: 11:30 PM + 30 min = 12:00 AM (midnight)
      final scheduledStart = DateTime(2025, 10, 14, 23, 30); // 11:30 PM
      final now = DateTime(2025, 10, 14, 23, 30); // 11:30 PM

      final settingsWithLateStart = RoutineSettingsModel(
        startTime: scheduledStart.millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 1800, // 30 min
          order: 0,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settingsWithLateStart,
        selectedTaskId: tasks.first.id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: now,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Should complete at midnight (12:00 AM)
      expect(find.textContaining('Est. Completion: 12:00 AM'), findsOneWidget);
    });

    testWidgets('handles multiple completed tasks correctly', (tester) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:16:40 (16 min 40 sec = 1000 sec elapsed)
      // Task 1: 550 sec + Task 2: 400 sec = 950 sec completed
      // Variance: 950 - 1000 = -50 sec = 50 sec behind
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
          isCompleted: true,
          actualDuration: 550,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
          isCompleted: true,
          actualDuration: 400,
        ),
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 400,
          order: 2,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[2].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(
                2025,
                10,
                14,
                6,
                16,
                40,
              ), // 1000 sec after scheduled start
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Behind by 50 sec'), findsOneWidget);
    });

    testWidgets('handles no tasks gracefully', (tester) async {
      final state = RoutineStateModel(tasks: [], settings: settings);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(2025, 10, 14, 6, 0),
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Should display on track when no tasks
      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('handles first task (no completed tasks) by showing on track', (
      tester,
    ) async {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks.first.id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(2025, 10, 14, 6, 0),
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Should show on track for first task
      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('includes remaining break time in completion calculation', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:12 AM (12 min = 720 sec elapsed)
      // Task 1 completed: 600 sec + Break 1: 120 sec = 720 sec total
      // Variance: 720 - 720 = 0 (on track)
      // Remaining: Task 2 (300 sec) + Break 2 (120 sec) + Task 3 (240 sec) = 660 sec = 11 min
      // Adjusted: 660 - 0 = 660 sec = 11 min
      // Completion: 6:12 AM + 11 min = 6:23 AM
      final now = DateTime(2025, 10, 14, 6, 12);

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
          isCompleted: true,
          actualDuration: 600,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300, // 5 min
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 240, // 4 min
          order: 2,
        ),
      ];

      final breaks = [
        const BreakModel(
          duration: 120,
          isEnabled: true,
        ), // 2 min break after task 1
        const BreakModel(
          duration: 120,
          isEnabled: true,
        ), // 2 min break after task 2
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: now,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Est. Completion: 6:23 AM'), findsOneWidget);
    });

    testWidgets('displays ahead status with only seconds when under 1 minute', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Current time: 6:00:55 (55 sec elapsed)
      // Task 1 completed in 100 seconds
      // Variance: 100 - 55 = 45 seconds ahead
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 100,
          order: 0,
          isCompleted: true,
          actualDuration: 100,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
        ),
      ];

      final state = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              currentTime: DateTime(
                2025,
                10,
                14,
                6,
                0,
                55,
              ), // 55 sec after scheduled start
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ahead by 45 sec'), findsOneWidget);
    });

    testWidgets(
      'displays behind status with only seconds when under 1 minute',
      (tester) async {
        // Scheduled start: 6:00 AM
        // Current time: 6:02:25 (145 sec elapsed)
        // Task 1 completed in 100 seconds
        // Variance: 100 - 145 = -45 seconds (45 sec behind)
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 100,
            order: 0,
            isCompleted: true,
            actualDuration: 100,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 300,
            order: 1,
          ),
        ];

        final state = RoutineStateModel(
          tasks: tasks,
          settings: settings,
          selectedTaskId: tasks[1].id,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScheduleHeader(
                routineState: state,
                currentTime: DateTime(
                  2025,
                  10,
                  14,
                  6,
                  2,
                  25,
                ), // 145 sec after scheduled start
                onSettingsTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Behind by 45 sec'), findsOneWidget);
      },
    );
  });
}
