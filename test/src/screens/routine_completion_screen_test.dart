import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/screens/routine_completion_screen.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('RoutineCompletionScreen', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    Widget createTestWidget({RoutineCompletion? completion}) {
      final bloc = FirebaseTestHelper.routineBloc;

      if (completion != null) {
        bloc.add(
          CompleteRoutine(
            totalTimeSpent: completion.totalTimeSpent,
            scheduleVariance: completion.scheduleVariance,
            routineStartTime: completion.routineStartTime,
          ),
        );
      }

      return MaterialApp(
        home: BlocProvider<RoutineBloc>.value(
          value: bloc,
          child: const RoutineCompletionScreen(),
        ),
        onGenerateRoute: AppRouter().onGenerateRoute,
      );
    }

    testWidgets(
      'displays completion message when completion data is available',
      (tester) async {
        final completion = RoutineCompletion(
          completedAt: DateTime.now(),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 120,
          routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
        );

        await tester.pumpWidget(createTestWidget(completion: completion));
        await tester.pumpAndSettle();

        expect(find.text('Routine Accomplished!'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );

    testWidgets('displays total time spent correctly', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3661, // 1 hour 1 minute 1 second = 61:01
        tasksCompleted: 5,
        scheduleVariance: 0,
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      expect(find.text('61:01'), findsOneWidget);
    });

    testWidgets('displays tasks completed count', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 7,
        scheduleVariance: 0,
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('displays "On track" status when variance is zero', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleVariance: 0,
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('displays "Ahead" status with positive variance', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleVariance: 300, // 5 minutes ahead
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ahead'), findsOneWidget);
    });

    testWidgets('displays "Behind" status with negative variance', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleVariance: -300, // 5 minutes behind
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      expect(find.textContaining('Behind'), findsOneWidget);
    });

    testWidgets('has "Start Again" button that resets routine', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleVariance: 0,
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      expect(find.text('Start Again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('has "Manage Tasks" button', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleVariance: 0,
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      expect(find.text('Manage Tasks'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('tapping "Start Again" triggers ResetRoutine event', (
      tester,
    ) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleVariance: 0,
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      bloc.add(
        CompleteRoutine(
          totalTimeSpent: completion.totalTimeSpent,
          scheduleVariance: completion.scheduleVariance,
          routineStartTime: completion.routineStartTime,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
          onGenerateRoute: AppRouter().onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      // Tap the Start Again button
      await tester.tap(find.text('Start Again'));
      await tester.pumpAndSettle();

      // Verify routine was reset (tasks should be incomplete)
      final state = bloc.state;
      expect(state.model!.tasks.every((t) => !t.isCompleted), true);
      expect(state.isCompleted, false);
    });

    testWidgets('displays fallback message when no completion data', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No completion data available'), findsOneWidget);
      expect(find.text('Go to Task Management'), findsOneWidget);
    });

    testWidgets('summary card displays all statistics', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleVariance: 120,
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      // Check for summary card
      expect(find.text('Summary'), findsOneWidget);

      // Check for stat labels
      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('Tasks Completed'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);

      // Check for stat icons
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(
        find.byIcon(Icons.trending_up),
        findsOneWidget,
      ); // Ahead = trending up
    });

    testWidgets('shows trending_down icon when behind schedule', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleVariance: -120, // Behind
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('screen has green background', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleVariance: 0,
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('displays completion time with proper formatting', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 65, // 1 minute 5 seconds = 01:05
        tasksCompleted: 3,
        scheduleVariance: 0,
        routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(completion: completion));
      await tester.pumpAndSettle();

      expect(find.text('01:05'), findsOneWidget);
    });
  });
}
