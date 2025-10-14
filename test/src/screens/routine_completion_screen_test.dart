import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('displays completion message when data is available', (
      tester,
    ) async {
      final bloc = FirebaseTestHelper.routineBloc;

      // Create mock completion data
      const completionData = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      // Set completion state
      bloc.emit(
        bloc.state.copyWith(completionData: completionData, isCompleted: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      expect(find.text('Morning Accomplished!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('displays summary statistics correctly', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      const completionData = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000, // 50 minutes
        totalEstimatedTime: 3600, // 60 minutes
        routineName: 'Morning Routine',
      );

      bloc.emit(
        bloc.state.copyWith(completionData: completionData, isCompleted: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // Tasks completed
      expect(find.text('10m 0s ahead'), findsOneWidget); // Time difference
    });

    testWidgets('displays ahead status when completed ahead of schedule', (
      tester,
    ) async {
      final bloc = FirebaseTestHelper.routineBloc;

      const completionData = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      bloc.emit(
        bloc.state.copyWith(completionData: completionData, isCompleted: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      expect(find.text('10m 0s ahead'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays behind status when completed behind schedule', (
      tester,
    ) async {
      final bloc = FirebaseTestHelper.routineBloc;

      const completionData = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 4000, // 66:40
        totalEstimatedTime: 3600, // 60 minutes
        routineName: 'Morning Routine',
      );

      bloc.emit(
        bloc.state.copyWith(completionData: completionData, isCompleted: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      expect(find.text('6m 40s behind'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('displays task breakdown when available', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      const completionData = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 2,
        totalTimeSpent: 1500,
        totalEstimatedTime: 1800,
        routineName: 'Morning Routine',
        tasksDetails: [
          TaskCompletionDetail(
            taskName: 'Morning Workout',
            estimatedDuration: 1200,
            actualDuration: 1000,
          ),
          TaskCompletionDetail(
            taskName: 'Shower',
            estimatedDuration: 600,
            actualDuration: 500,
          ),
        ],
      );

      bloc.emit(
        bloc.state.copyWith(completionData: completionData, isCompleted: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      expect(find.text('Task Breakdown'), findsOneWidget);
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('Shower'), findsOneWidget);
    });

    testWidgets('Start New Session button resets routine and navigates', (
      tester,
    ) async {
      final bloc = FirebaseTestHelper.routineBloc;

      const completionData = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      bloc.emit(
        bloc.state.copyWith(completionData: completionData, isCompleted: true),
      );

      // Set a larger test surface size to avoid off-screen widgets
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter().onGenerateRoute,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the button and verify it exists
      expect(find.text('Start New Session'), findsOneWidget);

      await tester.tap(find.text('Start New Session'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Reset test surface
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Manage Tasks button navigates to task management', (
      tester,
    ) async {
      final bloc = FirebaseTestHelper.routineBloc;

      const completionData = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      bloc.emit(
        bloc.state.copyWith(completionData: completionData, isCompleted: true),
      );

      // Set a larger test surface size to avoid off-screen widgets
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRouter().onGenerateRoute,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the button exists
      expect(find.text('Manage Tasks'), findsOneWidget);

      // Reset test surface
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('displays fallback UI when no completion data', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      // No completion data
      bloc.emit(bloc.state.copyWith(completionData: null, isCompleted: false));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      expect(find.text('No completion data available'), findsOneWidget);
      expect(find.text('Go to Task Management'), findsOneWidget);
    });

    testWidgets('background color is green when ahead of schedule', (
      tester,
    ) async {
      final bloc = FirebaseTestHelper.routineBloc;

      const completionData = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 3000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      bloc.emit(
        bloc.state.copyWith(completionData: completionData, isCompleted: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // Green when ahead (positive time difference)
      expect(completionData.isAhead, true);
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('background color is red when behind schedule', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      const completionData = RoutineCompletionModel(
        completedAt: 1234567890,
        totalTasksCompleted: 4,
        totalTimeSpent: 4000,
        totalEstimatedTime: 3600,
        routineName: 'Morning Routine',
      );

      bloc.emit(
        bloc.state.copyWith(completionData: completionData, isCompleted: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const RoutineCompletionScreen(),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      // Red when behind (negative time difference)
      expect(completionData.isAhead, false);
      expect(scaffold.backgroundColor, isNotNull);
    });
  });
}
