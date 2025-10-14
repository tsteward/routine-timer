import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/widgets/task_drawer.dart';
import '../test_helpers/firebase_test_helper.dart';

// Test-only drawer used to validate selection/index behavior via the Bloc
class TestTaskDrawer extends StatelessWidget {
  const TestTaskDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null || model.tasks.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No tasks available')),
          );
        }

        final currentTask = model.selectedTask;
        final currentIndex = model.currentTaskIndex;

        return Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Task: ${currentTask?.name ?? 'None'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Task ${currentIndex + 1} of ${model.tasks.length}'),
              const SizedBox(height: 16),
              const Text(
                'Upcoming Tasks:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: model.tasks.length - currentIndex - 1,
                  itemBuilder: (context, index) {
                    final taskIndex = currentIndex + 1 + index;
                    if (taskIndex >= model.tasks.length) {
                      return const SizedBox.shrink();
                    }
                    final task = model.tasks[taskIndex];
                    return ListTile(
                      title: Text(task.name),
                      subtitle: Text('${task.estimatedDuration ~/ 60} min'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void main() {
  group('TaskDrawer (test-only)', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    testWidgets('displays current task when routine is loaded', (tester) async {
      final testTasks = [
        const TaskModel(
          id: '1',
          name: 'Wake up',
          estimatedDuration: 120, // 2 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Prayer',
          estimatedDuration: 300, // 5 minutes
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Cook',
          estimatedDuration: 900, // 15 minutes
          order: 2,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: testTasks,
        settings: settings,
        selectedTaskId: testTasks.first.id,
      );

      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(bloc.state.copyWith(model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TestTaskDrawer(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Current Task: Wake up'), findsOneWidget);
      expect(find.text('Task 1 of 3'), findsOneWidget);
      expect(find.text('Upcoming Tasks:'), findsOneWidget);
      expect(find.text('Prayer'), findsOneWidget);
      expect(find.text('Cook'), findsOneWidget);
    });

    testWidgets('shows no tasks message when routine is empty', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TestTaskDrawer(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No tasks available'), findsOneWidget);
    });

    testWidgets('displays correct task when last task is selected', (
      tester,
    ) async {
      final testTasks = [
        const TaskModel(
          id: '1',
          name: 'Wake up',
          estimatedDuration: 120,
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Prayer',
          estimatedDuration: 300,
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Cook',
          estimatedDuration: 900,
          order: 2,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: testTasks,
        settings: settings,
        selectedTaskId: testTasks.last.id,
      );

      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(bloc.state.copyWith(model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TestTaskDrawer(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Current Task: Cook'), findsOneWidget);
      expect(find.text('Task 3 of 3'), findsOneWidget);
      // Should not show upcoming tasks when on last task
      expect(find.text('Upcoming Tasks:'), findsOneWidget);
    });

    testWidgets('updates display when task selection changes', (tester) async {
      final testTasks = [
        const TaskModel(
          id: '1',
          name: 'Wake up',
          estimatedDuration: 120,
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Prayer',
          estimatedDuration: 300,
          order: 1,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: testTasks,
        settings: settings,
        selectedTaskId: testTasks.first.id,
      );

      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(bloc.state.copyWith(model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TestTaskDrawer(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially shows first task
      expect(find.text('Current Task: Wake up'), findsOneWidget);
      expect(find.text('Task 1 of 2'), findsOneWidget);

      // Change to second task
      bloc.emit(
        bloc.state.copyWith(
          model: model.copyWith(selectedTaskId: testTasks[1].id),
        ),
      );
      await tester.pumpAndSettle();

      // Should now show second task
      expect(find.text('Current Task: Prayer'), findsOneWidget);
      expect(find.text('Task 2 of 2'), findsOneWidget);
    });

    testWidgets('handles tasks with different durations', (tester) async {
      final testTasks = [
        const TaskModel(
          id: '1',
          name: 'Quick Task',
          estimatedDuration: 300, // 5 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Long Task',
          estimatedDuration: 3600, // 60 minutes
          order: 1,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: testTasks,
        settings: settings,
        selectedTaskId: testTasks.first.id,
      );

      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(bloc.state.copyWith(model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TestTaskDrawer(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When first task is selected, only the second task appears in upcoming tasks
      expect(find.text('Current Task: Quick Task'), findsOneWidget);
      expect(find.text('Long Task'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
    });
  });

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
        selectedTaskId: testTasks.first.id,
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
        selectedTaskId: testTasks.last.id,
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
        selectedTaskId: manyTasks.first.id,
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

  group('TaskDrawer Expanded State Tests', () {
    late RoutineStateModel testRoutineState;
    late List<TaskModel> testTasks;

    setUp(() {
      testTasks = [
        const TaskModel(
          id: 'task-1',
          name: 'Current Task',
          estimatedDuration: 300,
          actualDuration: 280,
          isCompleted: true,
          order: 1,
        ),
        const TaskModel(
          id: 'task-2',
          name: 'Second Task',
          estimatedDuration: 600,
          actualDuration: 620,
          isCompleted: true,
          order: 2,
        ),
        const TaskModel(
          id: 'task-3',
          name: 'Active Task',
          estimatedDuration: 450,
          order: 3,
        ),
        const TaskModel(
          id: 'task-4',
          name: 'Fourth Task',
          estimatedDuration: 900,
          order: 4,
        ),
        const TaskModel(
          id: 'task-5',
          name: 'Fifth Task',
          estimatedDuration: 500,
          order: 5,
        ),
        const TaskModel(
          id: 'task-6',
          name: 'Sixth Task',
          estimatedDuration: 400,
          order: 6,
        ),
      ];

      testRoutineState = RoutineStateModel(
        tasks: testTasks,
        settings: const RoutineSettingsModel(
          startTime: 480,
          defaultBreakDuration: 300,
        ),
        selectedTaskId: testTasks[2].id, // Active Task (index 2)
        isRunning: true,
      );
    });

    testWidgets('should show "Show Less" when expanded', (
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

      // Should show all 3 upcoming tasks (task-4, task-5, task-6)
      expect(find.text('Fourth Task'), findsOneWidget);
      expect(find.text('Fifth Task'), findsOneWidget);
      expect(find.text('Sixth Task'), findsOneWidget);
    });

    testWidgets('should show "Upcoming Tasks" section header when expanded', (
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

    testWidgets('should show "Completed Tasks" section when expanded', (
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

      expect(find.text('Completed Tasks'), findsOneWidget);
    });

    testWidgets('should display completed tasks with actual duration', (
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

      // Should show completed tasks
      expect(find.text('Current Task'), findsOneWidget);
      expect(find.text('Second Task'), findsOneWidget);

      // Should show actual durations
      expect(find.text('Took: 4 min 40 sec'), findsOneWidget); // 280 seconds
      expect(find.text('Took: 10 min 20 sec'), findsOneWidget); // 620 seconds
    });

    testWidgets('should not show completed section if no completed tasks', (
      WidgetTester tester,
    ) async {
      final stateWithNoCompleted = testRoutineState.copyWith(
        tasks: testTasks
            .map((task) => task.copyWith(isCompleted: false))
            .toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: stateWithNoCompleted,
                  isExpanded: true,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Completed Tasks'), findsNothing);
    });

    testWidgets('should show background overlay when expanded', (
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

      // Find GestureDetector with semi-transparent black background
      final gestureDetectors = tester.widgetList<GestureDetector>(
        find.byType(GestureDetector),
      );

      // Should have at least 3 GestureDetectors (background, header, drawer content)
      expect(gestureDetectors.length, greaterThanOrEqualTo(3));
    });

    testWidgets('should use AnimatedContainer for smooth transitions', (
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

      expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(1));
    });

    testWidgets('should have different heights for collapsed vs expanded', (
      WidgetTester tester,
    ) async {
      // Test collapsed state
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

      await tester.pumpAndSettle();

      final collapsedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final collapsedConstraints =
          collapsedContainer.constraints as BoxConstraints;

      // Test expanded state
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

      await tester.pumpAndSettle();

      final expandedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final expandedConstraints =
          expandedContainer.constraints as BoxConstraints;

      // Expanded should have greater max height than collapsed
      expect(
        expandedConstraints.maxHeight,
        greaterThan(collapsedConstraints.maxHeight),
      );
    });

    testWidgets('should call onToggleExpanded when background is tapped', (
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

      // Tap on the background overlay (outside the drawer content)
      await tester.tapAt(const Offset(50, 50));
      expect(wasToggled, isTrue);
    });

    testWidgets(
      'should show only first 3 tasks in collapsed state even with many tasks',
      (WidgetTester tester) async {
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

        // In collapsed state, should only show next 3 tasks
        expect(find.text('Fourth Task'), findsOneWidget);
        expect(find.text('Fifth Task'), findsOneWidget);
        expect(find.text('Sixth Task'), findsOneWidget);

        // Verify it's using the collapsed view (no section headers)
        expect(find.text('Upcoming Tasks'), findsNothing);
        expect(find.text('Completed Tasks'), findsNothing);
      },
    );

    testWidgets('should update display when tasks are completed in real-time', (
      WidgetTester tester,
    ) async {
      // Start with no completed tasks
      final initialState = testRoutineState.copyWith(
        tasks: testTasks
            .map((task) => task.copyWith(isCompleted: false))
            .toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Stack(
                  children: [
                    const Center(child: Text('Main Content')),
                    TaskDrawer(
                      routineState: initialState,
                      isExpanded: true,
                      onToggleExpanded: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Initially no completed tasks section
      expect(find.text('Completed Tasks'), findsNothing);

      // Update state to have completed tasks
      final updatedState = initialState.copyWith(
        tasks: testTasks.sublist(0, 2).map((task) {
          return task.copyWith(
            isCompleted: true,
            actualDuration: task.estimatedDuration,
          );
        }).toList()..addAll(testTasks.sublist(2)),
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

      await tester.pumpAndSettle();

      // Now should show completed tasks section
      expect(find.text('Completed Tasks'), findsOneWidget);
    });
  });
}
