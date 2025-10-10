import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/widgets/task_drawer.dart';
import 'package:routine_timer/src/widgets/completed_task_card.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
  group('TaskDrawer Widget Tests', () {
    late RoutineStateModel testRoutineState;
    late List<TaskModel> testTasks;
    late List<TaskModel> testTasksWithCompleted;
    late RoutineStateModel stateWithCompletedTasks;

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

      testTasksWithCompleted = [
        const TaskModel(
          id: 'task-1',
          name: 'Completed Task 1',
          estimatedDuration: 300,
          actualDuration: 280,
          isCompleted: true,
          order: 1,
        ),
        const TaskModel(
          id: 'task-2',
          name: 'Completed Task 2',
          estimatedDuration: 600,
          actualDuration: 620,
          isCompleted: true,
          order: 2,
        ),
        const TaskModel(
          id: 'task-3',
          name: 'Current Task',
          estimatedDuration: 450,
          order: 3,
        ),
        const TaskModel(
          id: 'task-4',
          name: 'Next Task',
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

      stateWithCompletedTasks = RoutineStateModel(
        tasks: testTasksWithCompleted,
        settings: const RoutineSettingsModel(
          startTime: 480,
          defaultBreakDuration: 300,
        ),
        currentTaskIndex: 2, // On third task, so first two are completed
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

    testWidgets('should not show drawer when no upcoming and no completed tasks', (
      WidgetTester tester,
    ) async {
      // Create state with only one task that is current (no upcoming, no completed)
      final singleTaskState = RoutineStateModel(
        tasks: [testTasks.first],
        settings: testRoutineState.settings,
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
                  routineState: singleTaskState,
                  isExpanded: false,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Should not show any drawer content when no upcoming and no completed tasks
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

    group('Expanded State Tests', () {
      testWidgets('should show "Task Overview" and "Show Less" when expanded', (
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

        expect(find.text('Task Overview'), findsOneWidget);
        expect(find.text('Show Less'), findsOneWidget);
        expect(find.text('Up Next'), findsNothing);
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
        // All upcoming tasks should be shown in expanded state
        expect(find.text('Next Task'), findsOneWidget);
        expect(find.text('Third Task'), findsOneWidget);
        expect(find.text('Fourth Task'), findsOneWidget);
      });

      testWidgets(
        'should show "Completed Tasks" section when there are completed tasks',
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
          expect(find.text('Completed Task 1'), findsOneWidget);
          expect(find.text('Completed Task 2'), findsOneWidget);
        },
      );

      testWidgets('should use CompletedTaskCard for completed tasks', (
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

        expect(find.byType(CompletedTaskCard), findsAtLeastNWidgets(2));
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

      testWidgets(
        'should call onToggleExpanded when background is tapped in expanded state',
        (WidgetTester tester) async {
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

          // Tap on the background area (outside the drawer content)
          await tester.tapAt(const Offset(50, 50));
          expect(wasToggled, isTrue);
        },
      );

      testWidgets('should show higher drawer content when expanded', (
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

        // Check that AnimatedContainer exists (for the animation)
        expect(find.byType(AnimatedContainer), findsOneWidget);
      });

      testWidgets('should not show drawer when no tasks at all', (
        WidgetTester tester,
      ) async {
        final emptyState = testRoutineState.copyWith(
          tasks: [],
          currentTaskIndex: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Main Content')),
                  TaskDrawer(
                    routineState: emptyState,
                    isExpanded: true,
                    onToggleExpanded: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Task Overview'), findsNothing);
        expect(find.text('Upcoming Tasks'), findsNothing);
        expect(find.text('Completed Tasks'), findsNothing);
      });

      testWidgets('should show only completed tasks when all tasks are done', (
        WidgetTester tester,
      ) async {
        // Create a state where we've completed all tasks (current index beyond the last task)
        final allCompletedTasks = testTasksWithCompleted
            .map(
              (task) => task.copyWith(
                isCompleted: true,
                actualDuration: task.actualDuration ?? 300,
              ),
            )
            .toList();

        final allCompletedState = RoutineStateModel(
          tasks: allCompletedTasks,
          settings: stateWithCompletedTasks.settings,
          currentTaskIndex: allCompletedTasks
              .length, // Beyond last task to show all as completed
          isRunning: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Main Content')),
                  TaskDrawer(
                    routineState: allCompletedState,
                    isExpanded: true,
                    onToggleExpanded: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Completed Tasks'), findsOneWidget);
        expect(find.text('Upcoming Tasks'), findsNothing);
      });
    });
  });
}
