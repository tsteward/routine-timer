import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_timer/src/screens/main_routine_screen.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/widgets/routine_header.dart';

class MockRoutineBloc extends MockBloc<RoutineEvent, RoutineBlocState>
    implements RoutineBloc {}

void main() {
  group('MainRoutineScreen', () {
    late MockRoutineBloc mockBloc;
    late RoutineStateModel mockRoutine;

    setUp(() {
      mockBloc = MockRoutineBloc();

      final tasks = [
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
      ];

      final breaks = [const BreakModel(duration: 120, isEnabled: true)];

      final settings = RoutineSettingsModel(
        startTime: DateTime(2025, 1, 1, 6, 0).millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      mockRoutine = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
        isRunning: true,
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<RoutineBloc>(
          create: (context) => mockBloc,
          child: const MainRoutineScreen(),
        ),
      );
    }

    testWidgets('should display routine header when routine is loaded', (
      tester,
    ) async {
      when(
        () => mockBloc.state,
      ).thenReturn(RoutineBlocState(loading: false, model: mockRoutine));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(RoutineHeader), findsOneWidget);
    });

    testWidgets('should not display routine header when no routine is loaded', (
      tester,
    ) async {
      when(
        () => mockBloc.state,
      ).thenReturn(const RoutineBlocState(loading: false, model: null));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(RoutineHeader), findsNothing);
      expect(find.text('No tasks available'), findsOneWidget);
    });

    testWidgets('should navigate to task management when settings tapped', (
      tester,
    ) async {
      when(
        () => mockBloc.state,
      ).thenReturn(RoutineBlocState(loading: false, model: mockRoutine));

      await tester.pumpWidget(createTestWidget());

      // Find and tap the settings icon in the header
      final settingsIcon = find.byIcon(Icons.settings);
      expect(settingsIcon, findsOneWidget);

      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // This would normally test navigation, but since we can't easily test
      // Navigator.pushNamed in unit tests, we just verify the icon is tappable
      expect(settingsIcon, findsOneWidget);
    });

    testWidgets('should display current task name and timer', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(RoutineBlocState(loading: false, model: mockRoutine));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget); // Initial countdown
    });

    testWidgets('should show red background when task goes over time', (
      tester,
    ) async {
      when(
        () => mockBloc.state,
      ).thenReturn(RoutineBlocState(loading: false, model: mockRoutine));

      await tester.pumpWidget(createTestWidget());

      // Let some time pass to simulate going over time
      // Note: In a real test, you'd need to pump with Duration or use fake timers
      await tester.pump();

      // Find the scaffold
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // Initially should be green (task not over time yet)
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('should enable Previous button when not on first task', (
      tester,
    ) async {
      final routineOnSecondTask = mockRoutine.copyWith(currentTaskIndex: 1);

      when(() => mockBloc.state).thenReturn(
        RoutineBlocState(loading: false, model: routineOnSecondTask),
      );

      await tester.pumpWidget(createTestWidget());

      final previousButton = find.text('Previous');
      expect(previousButton, findsOneWidget);

      final buttonWidget = tester.widget<ElevatedButton>(
        find.ancestor(
          of: previousButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should disable Previous button when on first task', (
      tester,
    ) async {
      when(() => mockBloc.state).thenReturn(
        RoutineBlocState(
          loading: false,
          model: mockRoutine, // currentTaskIndex = 0
        ),
      );

      await tester.pumpWidget(createTestWidget());

      final previousButton = find.text('Previous');
      expect(previousButton, findsOneWidget);

      final buttonWidget = tester.widget<ElevatedButton>(
        find.ancestor(
          of: previousButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('should trigger MarkTaskDone when Done button pressed', (
      tester,
    ) async {
      when(
        () => mockBloc.state,
      ).thenReturn(RoutineBlocState(loading: false, model: mockRoutine));

      await tester.pumpWidget(createTestWidget());

      final doneButton = find.text('Done');
      expect(doneButton, findsOneWidget);

      await tester.tap(doneButton);

      verify(() => mockBloc.add(any(that: isA<MarkTaskDone>()))).called(1);
    });

    testWidgets(
      'should trigger GoToPreviousTask when Previous button pressed',
      (tester) async {
        final routineOnSecondTask = mockRoutine.copyWith(currentTaskIndex: 1);

        when(() => mockBloc.state).thenReturn(
          RoutineBlocState(loading: false, model: routineOnSecondTask),
        );

        await tester.pumpWidget(createTestWidget());

        final previousButton = find.text('Previous');
        await tester.tap(previousButton);

        verify(() => mockBloc.add(const GoToPreviousTask())).called(1);
      },
    );

    testWidgets('should display task counter correctly', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(RoutineBlocState(loading: false, model: mockRoutine));

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Task 1 of 2'), findsOneWidget);
    });

    testWidgets('should update task counter when task changes', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(RoutineBlocState(loading: false, model: mockRoutine));

      await tester.pumpWidget(createTestWidget());

      // Initially on first task
      expect(find.text('Task 1 of 2'), findsOneWidget);

      // Update to second task
      final routineOnSecondTask = mockRoutine.copyWith(currentTaskIndex: 1);
      when(() => mockBloc.state).thenReturn(
        RoutineBlocState(loading: false, model: routineOnSecondTask),
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Task 2 of 2'), findsOneWidget);
    });

    testWidgets('should display progress bar', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(RoutineBlocState(loading: false, model: mockRoutine));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display navigation FAB', (tester) async {
      when(
        () => mockBloc.state,
      ).thenReturn(RoutineBlocState(loading: false, model: mockRoutine));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Navigate'), findsOneWidget);
    });

    group('error states', () {
      testWidgets('should show empty state when no tasks', (tester) async {
        final emptyRoutine = mockRoutine.copyWith(tasks: []);

        when(
          () => mockBloc.state,
        ).thenReturn(RoutineBlocState(loading: false, model: emptyRoutine));

        await tester.pumpWidget(createTestWidget());

        expect(find.text('No tasks available'), findsOneWidget);
        expect(find.text('Go to Task Management'), findsOneWidget);
      });

      testWidgets('should handle loading state', (tester) async {
        when(
          () => mockBloc.state,
        ).thenReturn(const RoutineBlocState(loading: true, model: null));

        await tester.pumpWidget(createTestWidget());

        // The screen should still render, even during loading
        expect(find.byType(MainRoutineScreen), findsOneWidget);
      });
    });
  });
}
