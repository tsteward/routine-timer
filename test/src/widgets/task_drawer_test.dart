import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/widgets/task_drawer.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
  group('TaskDrawer Widget Tests', () {
    late RoutineStateModel testRoutineState;
    late List<TaskModel> testTasks;

    setUp(() {
      testTasks = [
        const TaskModel(
          id: 'task-1',
          name: 'Current Task',
          estimatedDuration: 300,
          order: 1,
        ),
        const TaskModel(
          id: 'task-2',
          name: 'Next Task',
          estimatedDuration: 600,
          order: 2,
        ),
        const TaskModel(
          id: 'task-3',
          name: 'Third Task',
          estimatedDuration: 450,
          order: 3,
        ),
        const TaskModel(
          id: 'task-4',
          name: 'Fourth Task',
          estimatedDuration: 900,
          order: 4,
        ),
      ];

      testRoutineState = RoutineStateModel(
        tasks: testTasks,
        settings: const RoutineSettingsModel(
          startTime: 480, // 8:00 AM in minutes
          defaultBreakDuration: 300, // 5 minutes
        ),
        currentTaskIndex: 0,
        isRunning: true,
      );
    });

    testWidgets('should show "Up Next" label in a stack', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // Add some content first to provide context
                const Center(child: Text('Main Content')),
                // Task drawer as overlay
                TaskDrawer(
                  routineState: testRoutineState,
                  isExpanded: false,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Up Next'), findsOneWidget);
    });

    testWidgets('should show "Show More" link in a stack', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: testRoutineState,
                  isExpanded: false,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Show More'), findsOneWidget);
    });

    testWidgets('should display upcoming tasks horizontally in a stack', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: testRoutineState,
                  isExpanded: false,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Should show next 3 tasks (task-2, task-3, task-4)
      expect(find.text('Next Task'), findsOneWidget);
      expect(find.text('Third Task'), findsOneWidget);
      expect(find.text('Fourth Task'), findsOneWidget);

      // Current task should not be shown
      expect(find.text('Current Task'), findsNothing);
    });

    testWidgets('should call onToggleExpanded when "Show More" is tapped', (
      WidgetTester tester,
    ) async {
      bool wasToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: testRoutineState,
                  isExpanded: false,
                  onToggleExpanded: () {
                    wasToggled = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show More'));
      expect(wasToggled, isTrue);
    });

    testWidgets('should not show drawer when no upcoming tasks', (
      WidgetTester tester,
    ) async {
      // Create state with current task being the last task
      final lastTaskState = testRoutineState.copyWith(
        currentTaskIndex: testTasks.length - 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: lastTaskState,
                  isExpanded: false,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Should not show any drawer content
      expect(find.text('Up Next'), findsNothing);
      expect(find.text('Show More'), findsNothing);
    });

    testWidgets('should limit display to next 3 tasks in collapsed state', (
      WidgetTester tester,
    ) async {
      // Add more tasks to test limiting
      final manyTasks = List.generate(
        10,
        (index) => TaskModel(
          id: 'task-${index + 1}',
          name: 'Task ${index + 1}',
          estimatedDuration: 300,
          order: index + 1,
        ),
      );

      final stateWithManyTasks = RoutineStateModel(
        tasks: manyTasks,
        settings: const RoutineSettingsModel(
          startTime: 480,
          defaultBreakDuration: 300,
        ),
        currentTaskIndex: 0,
        isRunning: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: stateWithManyTasks,
                  isExpanded: false,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Should show only next 3 tasks (tasks 2, 3, 4)
      expect(find.text('Task 2'), findsOneWidget);
      expect(find.text('Task 3'), findsOneWidget);
      expect(find.text('Task 4'), findsOneWidget);

      // Should not show tasks beyond the 3rd upcoming
      expect(find.text('Task 5'), findsNothing);
      expect(find.text('Task 6'), findsNothing);
    });

    testWidgets('should support horizontal scrolling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: testRoutineState,
                  isExpanded: false,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Check that ListView has horizontal scroll direction
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, equals(Axis.horizontal));
    });
  });
}
