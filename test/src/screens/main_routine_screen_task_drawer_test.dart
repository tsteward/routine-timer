import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/screens/main_routine_screen.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
  group('MainRoutineScreen with TaskDrawer', () {
    late RoutineBloc mockRoutineBloc;
    late RoutineStateModel mockRoutineState;

    setUp(() {
      final mockTasks = [
        const TaskModel(
          id: '1',
          name: 'Current Task',
          estimatedDuration: 300, // 5 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Next Task',
          estimatedDuration: 600, // 10 minutes
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Later Task',
          estimatedDuration: 240, // 4 minutes
          order: 2,
        ),
      ];

      mockRoutineState = RoutineStateModel(
        tasks: mockTasks,
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          defaultBreakDuration: 300, // 5 minutes
        ),
        currentTaskIndex: 0,
        isRunning: true,
      );

      mockRoutineBloc = RoutineBloc();
      // Emit the initial state
      mockRoutineBloc.emit(RoutineBlocState(
        loading: false,
        model: mockRoutineState,
      ));
    });

    testWidgets(
        'should show task drawer with upcoming tasks when routine has multiple tasks',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: mockRoutineBloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show current task name
      expect(find.text('Current Task'), findsOneWidget);

      // Should show task drawer with "Up Next" label
      expect(find.text('Up Next'), findsOneWidget);

      // Should show upcoming tasks in the drawer
      expect(find.text('Next Task'), findsOneWidget);
      expect(find.text('Later Task'), findsOneWidget);

      // Should show "Show More" initially
      expect(find.text('Show More'), findsOneWidget);
    });

    testWidgets('should not show task drawer when on last task', (tester) async {
      final lastTaskState = mockRoutineState.copyWith(
        currentTaskIndex: 2, // Last task
      );

      mockRoutineBloc.emit(RoutineBlocState(
        loading: false,
        model: lastTaskState,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: mockRoutineBloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show current task name
      expect(find.text('Later Task'), findsOneWidget);

      // Should NOT show task drawer since no upcoming tasks
      expect(find.text('Up Next'), findsNothing);
    });

    testWidgets('should expand drawer when Show More is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: mockRoutineBloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Show More" initially
      expect(find.text('Show More'), findsOneWidget);
      expect(find.text('Show Less'), findsNothing);

      // Tap the Show More area
      await tester.tap(find.text('Show More'));
      await tester.pumpAndSettle();

      // Should now show "Show Less"
      expect(find.text('Show Less'), findsOneWidget);
      expect(find.text('Show More'), findsNothing);
    });
  });
}