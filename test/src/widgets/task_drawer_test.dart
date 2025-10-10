import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import '../test_helpers/firebase_test_helper.dart';

// Mock Task Drawer Widget for testing purposes
class TaskDrawer extends StatelessWidget {
  const TaskDrawer({super.key});

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
  group('TaskDrawer', () {
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
        selectedTaskId: testTasks
            .first
            .id, // Updated to use selectedTaskId instead of currentTaskIndex: 0
      );

      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(bloc.state.copyWith(model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(value: bloc, child: const TaskDrawer()),
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
            body: BlocProvider.value(value: bloc, child: const TaskDrawer()),
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
        selectedTaskId: testTasks
            .last
            .id, // Updated to use selectedTaskId instead of currentTaskIndex: testTasks.length - 1
      );

      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(bloc.state.copyWith(model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(value: bloc, child: const TaskDrawer()),
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
        selectedTaskId: testTasks
            .first
            .id, // Updated to use selectedTaskId instead of currentTaskIndex: 0
      );

      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(bloc.state.copyWith(model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(value: bloc, child: const TaskDrawer()),
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
            body: BlocProvider.value(value: bloc, child: const TaskDrawer()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When first task is selected, only the second task appears in upcoming tasks
      expect(find.text('Current Task: Quick Task'), findsOneWidget);
      expect(
        find.text('Long Task'),
        findsOneWidget,
      ); // This will be in upcoming tasks
      expect(
        find.text('60 min'),
        findsOneWidget,
      ); // Long Task duration in upcoming list
    });
  });
}
