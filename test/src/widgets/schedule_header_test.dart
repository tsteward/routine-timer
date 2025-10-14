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
              currentTime: DateTime(2025, 10, 14, 6, 0),
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
              currentTime: DateTime(2025, 10, 14, 6, 0),
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
              currentTime: DateTime(2025, 10, 14, 6, 0),
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
              currentTime: DateTime(2025, 10, 14, 6, 0),
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Ahead by 5 min 45 sec'), findsOneWidget);
    });

    testWidgets('includes break time in schedule calculation', (tester) async {
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
              currentTime: DateTime(2025, 10, 14, 6, 0),
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
              currentTime: DateTime(2025, 10, 14, 6, 0),
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
      final now = DateTime(2025, 10, 14, 6, 0);

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
              routineStartTime: now,
              currentTime: now,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // With current time at 6:00 AM and 5 min remaining, should complete at 6:05 AM
      expect(find.textContaining('Est. Completion: 6:05 AM'), findsOneWidget);
    });

    testWidgets('adjusts completion time when ahead of schedule', (
      tester,
    ) async {
      final now = DateTime(2025, 10, 14, 6, 0);

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
              routineStartTime: now,
              currentTime: now,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // 10 min remaining - 5 min ahead = 5 min from now = 6:05 AM
      expect(find.textContaining('Est. Completion: 6:05 AM'), findsOneWidget);
    });

    testWidgets('adjusts completion time when behind schedule', (tester) async {
      final now = DateTime(2025, 10, 14, 6, 0);

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
              routineStartTime: now,
              currentTime: now,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // 10 min remaining + 5 min behind = 15 min from now = 6:15 AM
      expect(find.textContaining('Est. Completion: 6:15 AM'), findsOneWidget);
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
              currentTime: DateTime(2025, 10, 14, 6, 0),
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Net: 50 sec behind (100 - 50)
      expect(find.text('Behind by 50 sec'), findsOneWidget);
    });

    testWidgets('handles no tasks gracefully', (tester) async {
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
      final now = DateTime(2025, 10, 14, 6, 0);

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
              routineStartTime: now,
              currentTime: now,
              onSettingsTap: () {},
            ),
          ),
        ),
      );

      // Task 2 (5 min) + break after task 2 (2 min) + task 3 (4 min) = 11 min from now = 6:11 AM
      expect(find.textContaining('Est. Completion: 6:11 AM'), findsOneWidget);
    });

    testWidgets('displays ahead status with only seconds when under 1 minute', (
      tester,
    ) async {
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
              currentTime: DateTime(2025, 10, 14, 6, 0),
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
                currentTime: DateTime(2025, 10, 14, 6, 0),
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
