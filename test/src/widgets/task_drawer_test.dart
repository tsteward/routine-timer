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

    group('Collapsed State Tests', () {
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

    group('Expanded State Tests', () {
      testWidgets('should show "Show Less" link when expanded', (
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
                    isExpanded: true,
                    onToggleExpanded: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Show Less'), findsOneWidget);
        expect(find.text('Show More'), findsNothing);
      });

      testWidgets('should show "Upcoming Tasks" section when expanded', (
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
                    isExpanded: true,
                    onToggleExpanded: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Upcoming Tasks'), findsOneWidget);
      });

      testWidgets('should show all upcoming tasks when expanded', (
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
                    isExpanded: true,
                    onToggleExpanded: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Should show all upcoming tasks (task-2, task-3, task-4)
        expect(find.text('Next Task'), findsOneWidget);
        expect(find.text('Third Task'), findsOneWidget);
        expect(find.text('Fourth Task'), findsOneWidget);
      });

      testWidgets('should call onToggleExpanded when "Show Less" is tapped', (
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
                    isExpanded: true,
                    onToggleExpanded: () {
                      wasToggled = true;
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Less'));
        expect(wasToggled, isTrue);
      });

      testWidgets('should call onToggleExpanded when tapping background', (
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
                    isExpanded: true,
                    onToggleExpanded: () {
                      wasToggled = true;
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        // Tap on the GestureDetector background
        await tester.tap(find.byType(GestureDetector).first);
        expect(wasToggled, isTrue);
      });
    });

    group('Completed Tasks Tests', () {
      late RoutineStateModel stateWithCompletedTasks;

      setUp(() {
        final completedTasks = [
          const TaskModel(
            id: 'completed-1',
            name: 'Completed Task 1',
            estimatedDuration: 300,
            actualDuration: 280,
            isCompleted: true,
            order: 1,
          ),
          const TaskModel(
            id: 'completed-2',
            name: 'Completed Task 2',
            estimatedDuration: 600,
            actualDuration: 650,
            isCompleted: true,
            order: 2,
          ),
          const TaskModel(
            id: 'current',
            name: 'Current Task',
            estimatedDuration: 450,
            order: 3,
          ),
          const TaskModel(
            id: 'upcoming',
            name: 'Upcoming Task',
            estimatedDuration: 300,
            order: 4,
          ),
        ];

        stateWithCompletedTasks = RoutineStateModel(
          tasks: completedTasks,
          settings: const RoutineSettingsModel(
            startTime: 480,
            defaultBreakDuration: 300,
          ),
          currentTaskIndex: 2,
          isRunning: true,
        );
      });

      testWidgets(
        'should show "Completed Tasks" section when expanded with completed tasks',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    const Center(child: Text('Main Content')),
                    TaskDrawer(
                      routineState: stateWithCompletedTasks,
                      isExpanded: true,
                      onToggleExpanded: () {},
                    ),
                  ],
                ),
              ),
            ),
          );

          expect(find.text('Completed Tasks'), findsOneWidget);
        },
      );

      testWidgets('should display completed tasks with checkmark icons', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Main Content')),
                  TaskDrawer(
                    routineState: stateWithCompletedTasks,
                    isExpanded: true,
                    onToggleExpanded: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Should show completed task names
        expect(find.text('Completed Task 1'), findsOneWidget);
        expect(find.text('Completed Task 2'), findsOneWidget);

        // Should show checkmark icons
        expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(2));
      });

      testWidgets('should display actual duration for completed tasks', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Main Content')),
                  TaskDrawer(
                    routineState: stateWithCompletedTasks,
                    isExpanded: true,
                    onToggleExpanded: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Should show actual durations
        expect(
          find.textContaining('Took: 4 min 40 sec'),
          findsOneWidget,
        ); // 280 seconds
        expect(
          find.textContaining('Took: 10 min 50 sec'),
          findsOneWidget,
        ); // 650 seconds
      });

      testWidgets(
        'should format actual duration correctly for different time ranges',
        (WidgetTester tester) async {
          final shortTaskState = RoutineStateModel(
            tasks: [
              const TaskModel(
                id: 'short',
                name: 'Short Task',
                estimatedDuration: 60,
                actualDuration: 45,
                isCompleted: true,
                order: 1,
              ),
              const TaskModel(
                id: 'exact-minute',
                name: 'Exact Minute',
                estimatedDuration: 120,
                actualDuration: 120,
                isCompleted: true,
                order: 2,
              ),
              const TaskModel(
                id: 'current',
                name: 'Current',
                estimatedDuration: 300,
                order: 3,
              ),
            ],
            settings: const RoutineSettingsModel(
              startTime: 480,
              defaultBreakDuration: 300,
            ),
            currentTaskIndex: 2,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    const Center(child: Text('Main Content')),
                    TaskDrawer(
                      routineState: shortTaskState,
                      isExpanded: true,
                      onToggleExpanded: () {},
                    ),
                  ],
                ),
              ),
            ),
          );

          // Check different formatting
          expect(
            find.textContaining('Took: 45 sec'),
            findsOneWidget,
          ); // Less than 1 minute
          expect(
            find.textContaining('Took: 2 min'),
            findsOneWidget,
          ); // Exact minutes
        },
      );

      testWidgets(
        'should not show completed tasks section when no completed tasks',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    const Center(child: Text('Main Content')),
                    TaskDrawer(
                      routineState: testRoutineState,
                      isExpanded: true,
                      onToggleExpanded: () {},
                    ),
                  ],
                ),
              ),
            ),
          );

          expect(find.text('Completed Tasks'), findsNothing);
        },
      );
    });

    group('Animation and Layout Tests', () {
      testWidgets('should have AnimatedContainer for smooth transitions', (
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

        expect(find.byType(AnimatedContainer), findsOneWidget);
      });
    });
  });
}
