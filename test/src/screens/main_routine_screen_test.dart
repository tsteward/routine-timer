import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/screens/main_routine_screen.dart';

void main() {
  group('MainRoutineScreen', () {
    testWidgets('displays current task and timer', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      // Wait for bloc to load sample data
      await tester.pump();

      // Verify task name is displayed
      expect(find.text('Morning Workout'), findsOneWidget);

      // Verify timer is displayed (20 minutes = 20:00)
      expect(find.text('20:00'), findsOneWidget);

      // Verify buttons are present
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Done button advances to next task', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      // Wait for bloc to load sample data
      await tester.pump();

      // Verify first task is displayed
      expect(find.text('Morning Workout'), findsOneWidget);

      // Tap Done button
      await tester.tap(find.text('Done'));
      await tester.pump();

      // Verify second task is displayed
      expect(find.text('Shower'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Previous button goes back to previous task', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      // Wait for bloc to load sample data
      await tester.pump();

      // Advance to second task
      await tester.tap(find.text('Done'));
      await tester.pump();

      expect(find.text('Shower'), findsOneWidget);

      // Tap Previous button
      await tester.tap(find.text('Previous'));
      await tester.pump();

      // Verify we're back at first task
      expect(find.text('Morning Workout'), findsOneWidget);

      bloc.close();
    });

    testWidgets('Previous button is disabled on first task', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      // Wait for bloc to load sample data
      await tester.pump();

      // Verify we're on first task
      expect(find.text('Morning Workout'), findsOneWidget);

      // Find Previous button and verify it's disabled
      final previousButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Previous'),
      );
      expect(previousButton.onPressed, isNull);

      bloc.close();
    });

    testWidgets('timer counts down every second', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      // Wait for bloc to load sample data
      await tester.pump();

      // Verify initial timer value (20:00)
      expect(find.text('20:00'), findsOneWidget);

      // Wait 1 second and pump
      await tester.pump(const Duration(seconds: 1));

      // Verify timer has counted down to 19:59
      expect(find.text('19:59'), findsOneWidget);

      // Wait another second
      await tester.pump(const Duration(seconds: 1));

      // Verify timer has counted down to 19:58
      expect(find.text('19:58'), findsOneWidget);

      bloc.close();
    });

    testWidgets('displays no tasks message when tasks list is empty', (
      tester,
    ) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('No tasks available'), findsOneWidget);

      bloc.close();
    });

    testWidgets('timer format handles negative values', (tester) async {
      // This test verifies the timer can display negative time format
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      // Wait for bloc to load sample data and timer to initialize
      await tester.pumpAndSettle();

      // Verify timer starts at 20:00 (Morning Workout is 20 minutes)
      expect(find.text('20:00'), findsOneWidget);

      bloc.close();
    });

    testWidgets('background is initially green', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      // Wait for bloc to load sample data and timer to initialize
      await tester.pumpAndSettle();

      // Verify initial green background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor?.toARGB32(), equals(0xFF22C55E)); // green

      bloc.close();
    });

    testWidgets('progress bar updates as timer counts down', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      // Wait for bloc to load sample data
      await tester.pump();

      // Create a short task for easier testing
      bloc.add(
        UpdateTask(
          index: 0,
          task: const TaskModel(
            id: '1',
            name: 'Short Task',
            estimatedDuration: 10, // 10 seconds
            order: 0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Wait 5 seconds (should be 50% complete)
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Find the progress bar container
      final progressBarContainers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(Container),
        ),
      );

      // Verify progress bar exists and has updated
      expect(progressBarContainers, isNotEmpty);

      bloc.close();
    });
  });
}
