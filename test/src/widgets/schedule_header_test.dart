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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
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
      // Task 1: 10 min estimated, 10 min 5 sec actual
      // Task 2: 5 min estimated
      // Current time: 6:10:05 (after Task 1 completed)
      // Scheduled completion: 6:00 + 10 min + 5 min = 6:15
      // Estimated completion: 6:10:05 + 5 min = 6:15:05 (5 sec behind, on track)

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
          isCompleted: true,
          actualDuration: 605, // Only 5 seconds over
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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(2025, 10, 14, 6, 10, 5),
              currentTaskElapsedSeconds: 0, // Just started task 2
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
      // Task 1: 10 min estimated, 5 min actual
      // Task 2: 5 min estimated
      // Current time: 6:05 (after Task 1 completed, 5 min ahead)
      // Scheduled completion: 6:00 + 10 min + 5 min = 6:15
      // Estimated completion: 6:05 + 5 min = 6:10 (5 min ahead)

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 minutes estimated
          order: 0,
          isCompleted: true,
          actualDuration: 300, // 5 minutes actual (5 min ahead)
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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(2025, 10, 14, 6, 5),
              currentTaskElapsedSeconds: 0, // Just started task 2
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
      // Task 1: 10 min estimated, 15 min actual
      // Task 2: 5 min estimated
      // Current time: 6:15 (after Task 1 completed, 5 min behind)
      // Scheduled completion: 6:00 + 10 min + 5 min = 6:15
      // Estimated completion: 6:15 + 5 min = 6:20 (5 min behind)

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 minutes estimated
          order: 0,
          isCompleted: true,
          actualDuration: 900, // 15 minutes actual (5 min behind)
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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(2025, 10, 14, 6, 15),
              currentTaskElapsedSeconds: 0, // Just started task 2
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
      // Task 1: 10 min estimated, 4 min 15 sec actual
      // Task 2: 5 min estimated
      // Current time: 6:04:15 (after Task 1 completed)
      // Scheduled completion: 6:00 + 10 min + 5 min = 6:15:00
      // Estimated completion: 6:04:15 + 5 min = 6:09:15 (5 min 45 sec ahead)

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 minutes estimated
          order: 0,
          isCompleted: true,
          actualDuration: 255, // 4 min 15 sec actual (5 min 45 sec ahead)
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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(2025, 10, 14, 6, 4, 15),
              currentTaskElapsedSeconds: 0, // Just started task 2
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ahead by 5 min 45 sec'), findsOneWidget);
    });

    testWidgets('includes break time in schedule calculation', (tester) async {
      // Scheduled start: 6:00 AM
      // Task 1: 10 min estimated, 10 min actual
      // Break: 2 min
      // Task 2: 5 min estimated
      // Current time: 6:12 (after Task 1 and break completed on time)
      // Scheduled completion: 6:00 + 10 min + 2 min + 5 min = 6:17
      // Estimated completion: 6:12 + 5 min = 6:17 (on track)

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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(
                2025,
                10,
                14,
                6,
                12,
              ), // After task 1 + break
              currentTaskElapsedSeconds: 0, // Just started task 2
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Should be on track since actual = estimated (including break)
      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('excludes disabled breaks from schedule calculation', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Task 1: 10 min estimated, 10 min actual
      // Break: disabled (not counted)
      // Task 2: 5 min estimated
      // Current time: 6:10 (after Task 1, no break)
      // Scheduled completion: 6:00 + 10 min + 5 min = 6:15 (break disabled)
      // Estimated completion: 6:10 + 5 min = 6:15 (on track)

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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(2025, 10, 14, 6, 10),
              currentTaskElapsedSeconds: 0, // Just started task 2
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
      // Task 1: 10 min estimated, 10 min actual
      // Task 2: 5 min estimated
      // Current time: 6:10 (after Task 1 completed on time)
      // Estimated completion: 6:10 + 5 min = 6:15

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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: now,
              currentTaskElapsedSeconds: 0, // Just started task 2
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // With current time at 6:10 AM and 5 min remaining, should complete at 6:15 AM
      expect(find.textContaining('Est. Completion: 6:15 AM'), findsOneWidget);
    });

    testWidgets('adjusts completion time when ahead of schedule', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Task 1: 10 min estimated, 5 min actual (5 min ahead)
      // Task 2: 10 min estimated
      // Current time: 6:05 (after Task 1 completed)
      // Estimated completion: 6:05 + 10 min = 6:15

      final now = DateTime(2025, 10, 14, 6, 5);

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 min estimated
          order: 0,
          isCompleted: true,
          actualDuration: 300, // 5 min actual (5 min ahead)
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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: now,
              currentTaskElapsedSeconds: 0, // Just started task 2
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Current time 6:05 + 10 min remaining = 6:15 AM
      expect(find.textContaining('Est. Completion: 6:15 AM'), findsOneWidget);
    });

    testWidgets('adjusts completion time when behind schedule', (tester) async {
      // Scheduled start: 6:00 AM
      // Task 1: 10 min estimated, 15 min actual (5 min behind)
      // Task 2: 10 min estimated
      // Current time: 6:15 (after Task 1 completed)
      // Estimated completion: 6:15 + 10 min = 6:25

      final now = DateTime(2025, 10, 14, 6, 15);

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 min estimated
          order: 0,
          isCompleted: true,
          actualDuration: 900, // 15 min actual (5 min behind)
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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: now,
              currentTaskElapsedSeconds: 0, // Just started task 2
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Current time 6:15 + 10 min remaining = 6:25 AM
      expect(find.textContaining('Est. Completion: 6:25 AM'), findsOneWidget);
    });

    testWidgets('handles PM times correctly', (tester) async {
      final now = DateTime(2025, 10, 14, 23, 30); // 11:30 PM

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
        settings: settings,
        selectedTaskId: tasks.first.id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              routineStartTime: now,
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
      // Task 1: 10 min estimated, 9 min 10 sec actual (50 sec ahead)
      // Task 2: 5 min estimated, 6 min 40 sec actual (100 sec behind)
      // Task 3: 6 min 40 sec estimated
      // Current time: 6:15:50 (after Task 1 and 2)
      // Scheduled completion: 6:00 + 10 min + 5 min + 6:40 = 6:21:40
      // Estimated completion: 6:15:50 + 6:40 = 6:22:30 (50 sec behind)

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
          isCompleted: true,
          actualDuration: 550, // 50 sec ahead
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
          isCompleted: true,
          actualDuration: 400, // 100 sec behind
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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(2025, 10, 14, 6, 15, 50),
              currentTaskElapsedSeconds: 0, // Just started task 3
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Net: 50 sec behind (100 - 50)
      expect(find.text('Behind by 50 sec'), findsOneWidget);
    });

    testWidgets('handles no tasks gracefully', (tester) async {
      // Scheduled start: 6:00 AM
      // No tasks
      // Current time: 6:00 AM
      // Scheduled completion: 6:00 AM
      // Estimated completion: 6:00 AM
      // Should be on track

      final state = RoutineStateModel(tasks: [], settings: settings);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleHeader(
              routineState: state,
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
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
      // Scheduled start: 6:00 AM
      // Task 1: 10 min estimated, just started
      // Current time: 6:00 AM
      // Scheduled completion: 6:00 + 10 min = 6:10
      // Estimated completion: 6:00 + 10 min = 6:10
      // Should be on track

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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(2025, 10, 14, 6, 0),
              currentTaskElapsedSeconds: 0, // Just started
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
      // Task 1: 10 min estimated, 10 min actual
      // Break 1: 2 min
      // Task 2: 5 min estimated
      // Break 2: 2 min
      // Task 3: 4 min estimated
      // Current time: 6:12 (after Task 1 and break 1)
      // Remaining: Task 2 (5 min) + Break 2 (2 min) + Task 3 (4 min) = 11 min
      // Estimated completion: 6:12 + 11 min = 6:23

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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: now,
              currentTaskElapsedSeconds: 0, // Just started task 2
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Task 2 (5 min) + break after task 2 (2 min) + task 3 (4 min) = 11 min from 6:12 = 6:23 AM
      expect(find.textContaining('Est. Completion: 6:23 AM'), findsOneWidget);
    });

    testWidgets('displays ahead status with only seconds when under 1 minute', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Task 1: 100 sec estimated, 55 sec actual (45 sec ahead)
      // Task 2: 300 sec estimated
      // Current time: 6:00:55 (after Task 1)
      // Scheduled completion: 6:00 + 100 sec + 300 sec = 6:06:40
      // Estimated completion: 6:00:55 + 300 sec = 6:05:55 (45 sec ahead)

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 100,
          order: 0,
          isCompleted: true,
          actualDuration: 55, // 45 seconds ahead
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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(2025, 10, 14, 6, 0, 55),
              currentTaskElapsedSeconds: 0, // Just started task 2
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
        // Task 1: 100 sec estimated, 145 sec actual (45 sec behind)
        // Task 2: 300 sec estimated
        // Current time: 6:02:25 (after Task 1)
        // Scheduled completion: 6:00 + 100 sec + 300 sec = 6:06:40
        // Estimated completion: 6:02:25 + 300 sec = 6:07:25 (45 sec behind)

        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 100,
            order: 0,
            isCompleted: true,
            actualDuration: 145, // 45 seconds behind
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
                routineStartTime: DateTime(2025, 10, 14, 6, 0),
                currentTime: DateTime(2025, 10, 14, 6, 2, 25),
                currentTaskElapsedSeconds: 0, // Just started task 2
                onSettingsTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('Behind by 45 sec'), findsOneWidget);
      },
    );

    testWidgets('handles current task going over time (negative remaining)', (
      tester,
    ) async {
      // Scheduled start: 6:00 AM
      // Task 1: 10 min estimated, completed on time
      // Task 2: 5 min estimated, currently at 7 min (2 min overtime)
      // Current time: 6:17 (10 min for task 1 + 7 min into task 2)
      // Scheduled completion: 6:00 + 10 min + 5 min = 6:15
      // Current task remaining: 5 min - 7 min = -2 min (overtime)
      // Estimated completion: 6:17 + 0 min = 6:17 (task already over)
      // Variance: 6:17 - 6:15 = 2 min behind

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
          estimatedDuration: 300, // 5 min estimated
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
              routineStartTime: DateTime(2025, 10, 14, 6, 0),
              currentTime: DateTime(2025, 10, 14, 6, 17),
              currentTaskElapsedSeconds:
                  420, // 7 min (2 min over the 5 min estimate)
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Behind by 2 min'), findsOneWidget);
      // Estimated completion should be current time (task is already over)
      expect(find.textContaining('Est. Completion: 6:17 AM'), findsOneWidget);
    });
  });
}
