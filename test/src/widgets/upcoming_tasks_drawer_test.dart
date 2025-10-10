import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/widgets/upcoming_tasks_drawer.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
  group('UpcomingTasksDrawer', () {
    late RoutineBloc routineBloc;

    setUp(() {
      routineBloc = RoutineBloc();
    });

    tearDown(() {
      routineBloc.close();
    });

    testWidgets('displays empty state when no tasks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>(
            create: (context) => routineBloc,
            child: const Scaffold(
              endDrawer: UpcomingTasksDrawer(),
              body: SizedBox(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Up Next'), findsOneWidget);
      expect(find.text('No tasks available'), findsOneWidget);
    });

    testWidgets('displays upcoming tasks and breaks', (tester) async {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 900,
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 1200,
          order: 2,
        ),
      ];

      final breaks = [
        const BreakModel(duration: 120, isEnabled: true),
        const BreakModel(duration: 180, isEnabled: true),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
      );

      routineBloc.emit(RoutineBlocState(loading: false, model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>(
            create: (context) => routineBloc,
            child: const Scaffold(
              endDrawer: UpcomingTasksDrawer(),
              body: SizedBox(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Up Next'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
      expect(find.text('Task 3'), findsOneWidget);
      expect(find.text('Break'), findsWidgets);
    });

    testWidgets('shows all tasks completed when at end', (tester) async {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        currentTaskIndex: 0,
      );

      routineBloc.emit(RoutineBlocState(loading: false, model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>(
            create: (context) => routineBloc,
            child: const Scaffold(
              endDrawer: UpcomingTasksDrawer(),
              body: SizedBox(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Up Next'), findsOneWidget);
      expect(find.text('All tasks completed!'), findsOneWidget);
    });

    testWidgets('displays breaks with correct icons', (tester) async {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 900,
          order: 1,
        ),
      ];

      final breaks = [const BreakModel(duration: 120, isEnabled: true)];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      final model = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
      );

      routineBloc.emit(RoutineBlocState(loading: false, model: model));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>(
            create: (context) => routineBloc,
            child: const Scaffold(
              endDrawer: UpcomingTasksDrawer(),
              body: SizedBox(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.coffee), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
    });
  });
}
