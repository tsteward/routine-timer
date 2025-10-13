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
          name: 'Morning Workout',
          estimatedDuration: 1200, // 20 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Shower',
          estimatedDuration: 600, // 10 minutes
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Breakfast',
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

      expect(find.text('Current Task: Morning Workout'), findsOneWidget);
      expect(find.text('Task 1 of 3'), findsOneWidget);
      expect(find.text('Upcoming Tasks:'), findsOneWidget);
      expect(find.text('Shower'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
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
          name: 'Morning Workout',
          estimatedDuration: 1200,
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Shower',
          estimatedDuration: 600,
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Breakfast',
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

      expect(find.text('Current Task: Breakfast'), findsOneWidget);
      expect(find.text('Task 3 of 3'), findsOneWidget);
      // Should not show upcoming tasks when on last task
      expect(find.text('Upcoming Tasks:'), findsOneWidget);
    });

    testWidgets('updates display when task selection changes', (tester) async {
      final testTasks = [
        const TaskModel(
          id: '1',
          name: 'Morning Workout',
          estimatedDuration: 1200,
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Shower',
          estimatedDuration: 600,
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
      expect(find.text('Current Task: Morning Workout'), findsOneWidget);
      expect(find.text('Task 1 of 2'), findsOneWidget);

      // Change to second task
      bloc.emit(
        bloc.state.copyWith(
          model: model.copyWith(selectedTaskId: testTasks[1].id),
        ),
      );
      await tester.pumpAndSettle();

      // Should now show second task
      expect(find.text('Current Task: Shower'), findsOneWidget);
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

    testWidgets('should not show drawer when no upcoming or completed tasks', (
      WidgetTester tester,
    ) async {
      // Create state with only one task
      final singleTaskState = RoutineStateModel(
        tasks: [testTasks.first],
        settings: const RoutineSettingsModel(
          startTime: 480,
          defaultBreakDuration: 300,
        ),
        selectedTaskId: testTasks.first.id,
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
          name: 'Completed Task 1',
          estimatedDuration: 300,
          actualDuration: 320,
          isCompleted: true,
          order: 1,
        ),
        const TaskModel(
          id: 'task-2',
          name: 'Completed Task 2',
          estimatedDuration: 600,
          actualDuration: 580,
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
          name: 'Upcoming Task 1',
          estimatedDuration: 900,
          order: 4,
        ),
        const TaskModel(
          id: 'task-5',
          name: 'Upcoming Task 2',
          estimatedDuration: 720,
          order: 5,
        ),
      ];

      testRoutineState = RoutineStateModel(
        tasks: testTasks,
        settings: const RoutineSettingsModel(
          startTime: 480,
          defaultBreakDuration: 300,
        ),
        selectedTaskId: testTasks[2].id, // Current Task
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

      // Find the GestureDetector for the overlay
      final overlayFinder = find.descendant(
        of: find.byType(TaskDrawer),
        matching: find.byType(GestureDetector),
      );

      expect(overlayFinder, findsWidgets);
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

      // Tap on the overlay background (not the drawer content)
      await tester.tapAt(const Offset(50, 50));
      expect(wasToggled, isTrue);
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

      expect(find.text('Upcoming Task 1'), findsOneWidget);
      expect(find.text('Upcoming Task 2'), findsOneWidget);
    });

    testWidgets('should show all completed tasks when expanded', (
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

      expect(find.text('Completed Task 1'), findsOneWidget);
      expect(find.text('Completed Task 2'), findsOneWidget);
    });

    testWidgets('completed tasks should show actual time taken', (
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

      // 320 seconds = 5 min 20 sec
      expect(find.text('Took: 5 min 20 sec'), findsOneWidget);
      // 580 seconds = 9 min 40 sec
      expect(find.text('Took: 9 min 40 sec'), findsOneWidget);
    });

    testWidgets('completed tasks should show checkmark icon', (
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

      // Should find checkmark icons for completed tasks
      expect(find.byIcon(Icons.check_circle), findsAtLeastNWidgets(2));
    });

    testWidgets('should not show completed section when no completed tasks', (
      WidgetTester tester,
    ) async {
      final stateWithNoCompleted = RoutineStateModel(
        tasks: testTasks.sublist(2), // Only current and upcoming tasks
        settings: const RoutineSettingsModel(
          startTime: 480,
          defaultBreakDuration: 300,
        ),
        selectedTaskId: testTasks[2].id,
        isRunning: true,
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
      expect(find.text('Upcoming Tasks'), findsOneWidget);
    });

    testWidgets('should format actual time correctly - minutes only', (
      WidgetTester tester,
    ) async {
      final taskWithMinutesOnly = [
        const TaskModel(
          id: 'task-1',
          name: 'Task With Minutes',
          estimatedDuration: 300,
          actualDuration: 120, // 2 minutes exactly
          isCompleted: true,
          order: 1,
        ),
        const TaskModel(
          id: 'task-2',
          name: 'Current',
          estimatedDuration: 300,
          order: 2,
        ),
      ];

      final state = RoutineStateModel(
        tasks: taskWithMinutesOnly,
        settings: const RoutineSettingsModel(
          startTime: 480,
          defaultBreakDuration: 300,
        ),
        selectedTaskId: taskWithMinutesOnly[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: state,
                  isExpanded: true,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Took: 2 min'), findsOneWidget);
    });

    testWidgets('should format actual time correctly - seconds only', (
      WidgetTester tester,
    ) async {
      final taskWithSecondsOnly = [
        const TaskModel(
          id: 'task-1',
          name: 'Task With Seconds',
          estimatedDuration: 300,
          actualDuration: 45, // 45 seconds
          isCompleted: true,
          order: 1,
        ),
        const TaskModel(
          id: 'task-2',
          name: 'Current',
          estimatedDuration: 300,
          order: 2,
        ),
      ];

      final state = RoutineStateModel(
        tasks: taskWithSecondsOnly,
        settings: const RoutineSettingsModel(
          startTime: 480,
          defaultBreakDuration: 300,
        ),
        selectedTaskId: taskWithSecondsOnly[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: state,
                  isExpanded: true,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Took: 45 sec'), findsOneWidget);
    });

    testWidgets('should handle missing actualDuration gracefully', (
      WidgetTester tester,
    ) async {
      final taskWithoutActualDuration = [
        const TaskModel(
          id: 'task-1',
          name: 'Task Without Actual',
          estimatedDuration: 300,
          actualDuration: null, // No actual duration
          isCompleted: true,
          order: 1,
        ),
        const TaskModel(
          id: 'task-2',
          name: 'Current',
          estimatedDuration: 300,
          order: 2,
        ),
      ];

      final state = RoutineStateModel(
        tasks: taskWithoutActualDuration,
        settings: const RoutineSettingsModel(
          startTime: 480,
          defaultBreakDuration: 300,
        ),
        selectedTaskId: taskWithoutActualDuration[1].id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                TaskDrawer(
                  routineState: state,
                  isExpanded: true,
                  onToggleExpanded: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Should fallback to estimatedDuration (300 seconds = 5 min)
      expect(find.text('Took: 5 min'), findsOneWidget);
    });

    testWidgets('should animate height change when expanding', (
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

      // Get initial height
      final collapsedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(collapsedContainer.constraints?.maxHeight, 160);

      // Now test expanded state
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

      await tester.pump(); // Start animation
      await tester.pumpAndSettle(); // Complete animation

      final expandedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      // Expanded height should be 60% of screen height
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(expandedContainer.constraints?.maxHeight, screenHeight * 0.6);
    });
  });
}
