import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/screens/routine_completion_screen.dart';

class MockRoutineBloc extends Mock implements RoutineBloc {}

void main() {
  late MockRoutineBloc mockBloc;

  setUp(() {
    mockBloc = MockRoutineBloc();
    registerFallbackValue(const ResetRoutine());
  });

  Widget buildTestWidget(RoutineBlocState state) {
    return MaterialApp(
      home: BlocProvider<RoutineBloc>.value(
        value: mockBloc,
        child: const RoutineCompletionScreen(),
      ),
      onGenerateRoute: AppRouter().onGenerateRoute,
    );
  }

  final settings = RoutineSettingsModel(
    startTime: DateTime(2025, 1, 1, 6, 0).millisecondsSinceEpoch,
    breaksEnabledByDefault: false,
    defaultBreakDuration: 120,
  );

  group('RoutineCompletionScreen', () {
    testWidgets('displays loading indicator when model is null', (
      tester,
    ) async {
      when(() => mockBloc.state).thenReturn(RoutineBlocState.initial());
      when(
        () => mockBloc.stream,
      ).thenAnswer((_) => Stream.value(RoutineBlocState.initial()));

      await tester.pumpWidget(buildTestWidget(RoutineBlocState.initial()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays "Morning Accomplished!" message', (tester) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.text('Morning Accomplished!'), findsOneWidget);
    });

    testWidgets('displays celebration icon', (tester) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.byIcon(Icons.celebration), findsOneWidget);
    });

    testWidgets('displays total time spent', (tester) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
            TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 620,
              order: 1,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('20m 0s'), findsOneWidget); // 1200 seconds = 20 minutes
    });

    testWidgets('displays tasks completed count', (tester) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
            TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 620,
              order: 1,
            ),
            TaskModel(
              id: '3',
              name: 'Task 3',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 600,
              order: 2,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.text('Tasks Completed'), findsOneWidget);
      expect(find.text('3 of 3'), findsOneWidget);
    });

    testWidgets('displays "Right on schedule!" when variance is 0', (
      tester,
    ) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 600,
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.text('Right on schedule!'), findsOneWidget);
    });

    testWidgets('displays "Ahead of schedule" when ahead', (tester) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 550,
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.text('Ahead of schedule'), findsOneWidget);
      expect(find.text('50s'), findsOneWidget); // Variance subtitle
    });

    testWidgets('displays "Behind schedule" when behind', (tester) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 650,
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.text('Behind schedule'), findsOneWidget);
      expect(find.text('50s'), findsOneWidget); // Variance subtitle
    });

    testWidgets('displays "Start New Routine" button', (tester) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));
      when(() => mockBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.text('Start New Routine'), findsOneWidget);
    });

    testWidgets('displays "Manage Tasks" button', (tester) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.text('Manage Tasks'), findsOneWidget);
    });

    testWidgets('"Start New Routine" button resets routine and navigates', (
      tester,
    ) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));
      when(() => mockBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(buildTestWidget(state));

      await tester.tap(find.text('Start New Routine'));
      await tester.pumpAndSettle();

      verify(() => mockBloc.add(const ResetRoutine())).called(1);
    });

    testWidgets('formats time correctly for hours, minutes, and seconds', (
      tester,
    ) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 3725, // 1h 2m 5s
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      expect(find.text('1h 2m 5s'), findsOneWidget);
    });

    testWidgets('uses green background', (tester) async {
      final state = RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
          ],
          settings: settings,
        ),
      );

      when(() => mockBloc.state).thenReturn(state);
      when(() => mockBloc.stream).thenAnswer((_) => Stream.value(state));

      await tester.pumpWidget(buildTestWidget(state));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppTheme.green);
    });
  });
}
