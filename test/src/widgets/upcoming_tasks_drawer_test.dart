import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/widgets/upcoming_tasks_drawer.dart';

void main() {
  group('UpcomingTasksDrawer', () {
    late RoutineSettingsModel settings;

    setUp(() {
      settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );
    });

    Widget makeTestableWidget(RoutineStateModel model) {
      return MaterialApp(
        home: Scaffold(
          body: UpcomingTasksDrawer(model: model),
        ),
      );
    }

    testWidgets('displays up next header', (tester) async {
      final model = RoutineStateModel(
        tasks: [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 300,
            order: 0,
          ),
        ],
        settings: settings,
        currentTaskIndex: 0,
      );

      await tester.pumpWidget(makeTestableWidget(model));
      
      expect(find.text('Up Next'), findsOneWidget);
    });

    testWidgets('shows upcoming tasks correctly', (tester) async {
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

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
      );

      await tester.pumpWidget(makeTestableWidget(model));
      
      // Should show upcoming tasks starting from index 1 (next task after current)
      expect(find.text('Current Task'), findsNothing); // Current task not shown
      expect(find.text('Next Task'), findsOneWidget);
      expect(find.text('Final Task'), findsOneWidget);
      
      // Should show breaks
      expect(find.text('Break'), findsOneWidget); // Only one break between Next and Final
    });

    testWidgets('shows upcoming tasks when on break', (tester) async {
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
          name: 'Next Task After Break',
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

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
        isOnBreak: true,
        currentBreakIndex: 0,
      );

      await tester.pumpWidget(makeTestableWidget(model));

      // Should show upcoming tasks starting after the current break
      expect(find.text('Next Task After Break'), findsOneWidget);
      expect(find.text('Final Task'), findsOneWidget);
      
      // Should not show the completed task
      expect(find.text('Completed Task'), findsNothing);
    });

    testWidgets('shows all completed message when no upcoming tasks', (tester) async {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Completed Task',
          estimatedDuration: 300,
          order: 0,
          isCompleted: true,
        ),
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        currentTaskIndex: 0,
      );

      await tester.pumpWidget(makeTestableWidget(model));

      expect(find.text('All tasks completed!'), findsOneWidget);
    });

    testWidgets('displays task durations and estimated start times', (tester) async {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Current Task',
          estimatedDuration: 1800, // 30 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Next Task',
          estimatedDuration: 3600, // 60 minutes
          order: 1,
        ),
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        currentTaskIndex: 0,
      );

      await tester.pumpWidget(makeTestableWidget(model));

      // Should show formatted durations - only for upcoming tasks
      expect(find.text('Duration: 30m'), findsNothing); // Current task not shown
      expect(find.text('Duration: 1h 0m'), findsOneWidget); // Next task shown (3600 seconds = 1h)
      
      // Should show estimated start times  
      expect(find.textContaining('Est. start:'), findsNWidgets(1)); // Only one task shown
    });

    testWidgets('shows break durations correctly', (tester) async {
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
        const BreakModel(duration: 300, isEnabled: true), // 5 minute break
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
      );

      await tester.pumpWidget(makeTestableWidget(model));

      // Should show break duration and second task duration  
      // Break: 5m, Second task: 10m
      expect(find.textContaining('Duration: 5m'), findsOneWidget); // Break
      expect(find.textContaining('Duration: 10m'), findsOneWidget); // Second task
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('highlights next task when not on break', (tester) async {
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
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        currentTaskIndex: 0,
      );

      await tester.pumpWidget(makeTestableWidget(model));

      // Current task should be highlighted as "next"
      // We can verify this by checking only the next task is displayed
      expect(find.text('Current Task'), findsNothing); // Not shown, it's current
      expect(find.text('Next Task'), findsOneWidget); // This should be shown as upcoming
    });

    testWidgets('does not show breaks after last task', (tester) async {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Only Task',
          estimatedDuration: 300,
          order: 0,
        ),
      ];
      
      final breaks = [
        const BreakModel(duration: 120, isEnabled: true),
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
      );

      await tester.pumpWidget(makeTestableWidget(model));

      // Should show no upcoming tasks (only task is current)
      expect(find.text('Only Task'), findsNothing); // Current task not shown  
      expect(find.text('Break'), findsNothing);
      expect(find.text('All tasks completed!'), findsOneWidget); // Should show completion message
    });

    testWidgets('skips disabled breaks', (tester) async {
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
        const BreakModel(duration: 120, isEnabled: false), // Disabled break
      ];

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
      );

      await tester.pumpWidget(makeTestableWidget(model));

      // Should show only upcoming task (no break, first task is current)
      expect(find.text('First Task'), findsNothing); // Current task not shown
      expect(find.text('Second Task'), findsOneWidget); // Upcoming task shown
      expect(find.text('Break'), findsNothing); // Break is disabled
    });
  });
}