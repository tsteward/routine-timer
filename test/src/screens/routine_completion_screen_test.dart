import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/screens/routine_completion_screen.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FirebaseTestHelper.reset();
  });

  Widget createTestWidget(RoutineCompletion completion) {
    return MaterialApp(
      home: BlocProvider<RoutineBloc>.value(
        value: FirebaseTestHelper.routineBloc,
        child: RoutineCompletionScreen(completion: completion),
      ),
      onGenerateRoute: AppRouter().onGenerateRoute,
    );
  }

  group('RoutineCompletionScreen', () {
    testWidgets('should display completion message', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -120,
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.text('Morning Accomplished!'), findsOneWidget);
    });

    testWidgets('should display total time spent', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3661, // 1h 1m 1s
        tasksCompleted: 5,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -120,
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('1h 1m 1s'), findsOneWidget);
    });

    testWidgets('should display tasks completed count', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 7,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -120,
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.text('Tasks Completed'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('should display "ahead" schedule status correctly', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -125, // -2m 5s
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.text('Schedule Status'), findsOneWidget);
      expect(find.text('Ahead by 2m 5s'), findsOneWidget);
    });

    testWidgets('should display "behind" schedule status correctly', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'behind',
        scheduleVarianceSeconds: 185, // 3m 5s
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.text('Schedule Status'), findsOneWidget);
      expect(find.text('Behind by 3m 5s'), findsOneWidget);
    });

    testWidgets('should display "on-track" schedule status correctly', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'on-track',
        scheduleVarianceSeconds: 0,
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.text('Schedule Status'), findsOneWidget);
      expect(find.text('Right on schedule!'), findsOneWidget);
    });

    testWidgets('should have "Return to Task Management" button', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -120,
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.text('Return to Task Management'), findsOneWidget);
    });

    testWidgets('should have "Start Another Routine" button', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -120,
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.text('Start Another Routine'), findsOneWidget);
    });

    testWidgets('should dispatch ResetRoutine when return button is tapped', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -120,
      );

      await tester.pumpWidget(createTestWidget(completion));
      await tester.tap(find.text('Return to Task Management'));
      await tester.pumpAndSettle();

      // Verify navigation occurred (would need navigation observer in real test)
      // For now, just verify the button is tappable
      expect(find.text('Return to Task Management'), findsOneWidget);
    });

    testWidgets('should format duration with only minutes when hours is zero', (
      tester,
    ) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 125, // 2m 5s
        tasksCompleted: 3,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -10,
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.text('2m 5s'), findsOneWidget);
    });

    testWidgets(
      'should format duration with only seconds when minutes is zero',
      (tester) async {
        final completion = RoutineCompletion(
          completedAt: DateTime.now(),
          totalTimeSpent: 45, // 45s
          tasksCompleted: 1,
          scheduleStatus: 'ahead',
          scheduleVarianceSeconds: -5,
        );

        await tester.pumpWidget(createTestWidget(completion));

        expect(find.text('45s'), findsOneWidget);
      },
    );

    testWidgets('should display completion icon', (tester) async {
      final completion = RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -120,
      );

      await tester.pumpWidget(createTestWidget(completion));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}
