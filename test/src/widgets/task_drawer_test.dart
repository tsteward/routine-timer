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

    group('Expanded State Tests', () {
      testWidgets(
        'should show "Show Less" and "Tasks Overview" when expanded',
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

          expect(find.text('Tasks Overview'), findsOneWidget);
          expect(find.text('Show Less'), findsOneWidget);
          expect(find.text('Up Next'), findsNothing);
          expect(find.text('Show More'), findsNothing);
        },
      );

      testWidgets('should show "Upcoming Tasks" section in expanded state', (
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
        // Should show all upcoming tasks, not just limited set
        expect(find.text('Next Task'), findsOneWidget);
        expect(find.text('Third Task'), findsOneWidget);
        expect(find.text('Fourth Task'), findsOneWidget);
      });

      testWidgets(
        'should show completed tasks section when tasks are completed',
        (WidgetTester tester) async {
          final completedTasks = [
            testTasks[0].copyWith(isCompleted: true, actualDuration: 320),
            testTasks[1].copyWith(isCompleted: true, actualDuration: 580),
          ];
          final remainingTasks = testTasks.sublist(2);

          final stateWithCompletedTasks = testRoutineState.copyWith(
            tasks: [...completedTasks, ...remainingTasks],
            currentTaskIndex: 2,
          );

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
          expect(find.byType(CompletedTaskCard), findsAtLeastNWidgets(2));
        },
      );

      testWidgets(
        'should show "No completed tasks yet" when no tasks completed',
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

          expect(find.text('No completed tasks yet'), findsOneWidget);
          expect(find.text('Completed Tasks'), findsNothing);
        },
      );

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

          // Tap on the drawer background (GestureDetector)
          await tester.tap(find.byType(GestureDetector).first);
          expect(wasToggled, isTrue);
        },
      );

      testWidgets(
        'should not call onToggleExpanded when background is tapped in collapsed state',
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

          // Tap on the drawer background - should not trigger in collapsed state
          await tester.tap(find.byType(GestureDetector).first);
          expect(wasToggled, isFalse);
        },
      );

      testWidgets(
        'should show all upcoming tasks in expanded state vs limited in collapsed',
        (WidgetTester tester) async {
          // Add more tasks to test the difference
          final manyTasks = List.generate(
            8,
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

          // Test expanded state - should show all upcoming tasks
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    const Center(child: Text('Main Content')),
                    TaskDrawer(
                      routineState: stateWithManyTasks,
                      isExpanded: true,
                      onToggleExpanded: () {},
                    ),
                  ],
                ),
              ),
            ),
          );

          // In expanded state, should show all remaining tasks (2-8)
          expect(find.text('Task 2'), findsOneWidget);
          expect(find.text('Task 5'), findsOneWidget);
          expect(
            find.text('Task 7'),
            findsOneWidget,
          ); // There are only 8 tasks total, so Task 7 exists
        },
      );

      testWidgets('should update in real-time when tasks are completed', (
        WidgetTester tester,
      ) async {
        // Start with no completed tasks
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

        // Should show "No completed tasks yet"
        expect(find.text('No completed tasks yet'), findsOneWidget);
        expect(find.text('Completed Tasks'), findsNothing);

        // Update with completed task
        final updatedTasks = [
          testTasks[0].copyWith(isCompleted: true, actualDuration: 350),
          ...testTasks.sublist(1),
        ];
        final updatedState = testRoutineState.copyWith(
          tasks: updatedTasks,
          currentTaskIndex: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Main Content')),
                  TaskDrawer(
                    routineState: updatedState,
                    isExpanded: true,
                    onToggleExpanded: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Should now show completed tasks section
        expect(find.text('Completed Tasks'), findsOneWidget);
        expect(find.text('No completed tasks yet'), findsNothing);
        expect(find.byType(CompletedTaskCard), findsOneWidget);
      });

      testWidgets(
        'should not show drawer when no upcoming and no completed tasks',
        (WidgetTester tester) async {
          // Create state with current task being the last task AND no completed tasks
          final lastTaskState = testRoutineState.copyWith(
            currentTaskIndex: testTasks.length - 1,
            tasks: [testTasks.last], // Only one task that's current
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    const Center(child: Text('Main Content')),
                    TaskDrawer(
                      routineState: lastTaskState,
                      isExpanded: true,
                      onToggleExpanded: () {},
                    ),
                  ],
                ),
              ),
            ),
          );

          // Should not show any drawer content
          expect(find.text('Tasks Overview'), findsNothing);
          expect(find.text('Show Less'), findsNothing);
          expect(find.text('Upcoming Tasks'), findsNothing);
          expect(find.text('Completed Tasks'), findsNothing);
        },
      );

      testWidgets('should animate between collapsed and expanded states', (
        WidgetTester tester,
      ) async {
        bool isExpanded = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: Scaffold(
                  body: Stack(
                    children: [
                      const Center(child: Text('Main Content')),
                      TaskDrawer(
                        routineState: testRoutineState,
                        isExpanded: isExpanded,
                        onToggleExpanded: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        // Start in collapsed state
        expect(find.text('Up Next'), findsOneWidget);
        expect(find.text('Show More'), findsOneWidget);

        // Tap to expand
        await tester.tap(find.text('Show More'));
        await tester.pump(); // Start animation
        await tester.pump(const Duration(milliseconds: 150)); // Mid animation
        await tester.pump(
          const Duration(milliseconds: 300),
        ); // Complete animation

        // Should now be expanded
        expect(find.text('Tasks Overview'), findsOneWidget);
        expect(find.text('Show Less'), findsOneWidget);

        // Tap to collapse
        await tester.tap(find.text('Show Less'));
        await tester.pump(); // Start animation
        await tester.pump(
          const Duration(milliseconds: 300),
        ); // Complete animation

        // Should be back to collapsed
        expect(find.text('Up Next'), findsOneWidget);
        expect(find.text('Show More'), findsOneWidget);
      });
    });
  });
}
