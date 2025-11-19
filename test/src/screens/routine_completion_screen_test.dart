import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/services/auth_service.dart';

void main() {
  group('RoutineCompletionScreen', () {
    RoutineBloc? mockBloc;

    setUp(() {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth(signedIn: true);
      final authService = AuthService(auth: mockAuth);
      final repository = RoutineRepository(
        firestore: fakeFirestore,
        authService: authService,
      );
      mockBloc = RoutineBloc(repository: repository);
    });

    tearDown(() {
      mockBloc?.close();
    });

    Widget createWidgetUnderTest() {
      return BlocProvider<RoutineBloc>.value(
        value: mockBloc!,
        child: MaterialApp(
          initialRoute: AppRoutes.completion,
          onGenerateRoute: (settings) => AppRouter().onGenerateRoute(settings),
        ),
      );
    }

    testWidgets('should display completion message', (tester) async {
      // Arrange
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: const [],
      );

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
        defaultBreakDuration: 120,
      );

      mockBloc!.emit(
        RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            isCompleted: true,
            completion: completion,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Routine Accomplished! 🎉'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
    });

    testWidgets('should display correct task count', (tester) async {
      // Arrange
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: const [],
      );

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
        defaultBreakDuration: 120,
      );

      mockBloc!.emit(
        RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            isCompleted: true,
            completion: completion,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Tasks Completed'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('should display ahead of schedule status', (tester) async {
      // Arrange: total spent (3600) < estimated (4000) = ahead
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 3600, // 60 minutes
        tasksCompleted: 4,
        totalEstimatedTime: 4000, // 66 minutes 40 seconds
        taskDetails: const [],
      );

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
        defaultBreakDuration: 120,
      );

      mockBloc!.emit(
        RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            isCompleted: true,
            completion: completion,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ahead of Schedule'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.trending_up &&
              widget.color == AppTheme.green,
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display behind schedule status', (tester) async {
      // Arrange: total spent (4200) > estimated (3600) = behind
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 4200, // 70 minutes
        tasksCompleted: 4,
        totalEstimatedTime: 3600, // 60 minutes
        taskDetails: const [],
      );

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
        defaultBreakDuration: 120,
      );

      mockBloc!.emit(
        RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            isCompleted: true,
            completion: completion,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Behind Schedule'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.trending_down &&
              widget.color == AppTheme.red,
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display task details', (tester) async {
      // Arrange
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 1550,
        tasksCompleted: 2,
        totalEstimatedTime: 1800,
        taskDetails: const [
          TaskCompletionDetail(
            taskId: 'task1',
            taskName: 'Morning Workout',
            estimatedDuration: 1200,
            actualDuration: 1000,
          ),
          TaskCompletionDetail(
            taskId: 'task2',
            taskName: 'Shower',
            estimatedDuration: 600,
            actualDuration: 550,
          ),
        ],
      );

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
        defaultBreakDuration: 120,
      );

      mockBloc!.emit(
        RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            isCompleted: true,
            completion: completion,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('Shower'), findsOneWidget);
    });

    testWidgets('should have Start New Routine button', (tester) async {
      // Arrange
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: const [],
      );

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
        defaultBreakDuration: 120,
      );

      mockBloc!.emit(
        RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            isCompleted: true,
            completion: completion,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Back to Start'), findsOneWidget);
    });

    testWidgets('should have Task Management button', (tester) async {
      // Arrange
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: const [],
      );

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
        defaultBreakDuration: 120,
      );

      mockBloc!.emit(
        RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            isCompleted: true,
            completion: completion,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Task Management'), findsOneWidget);
    });

    testWidgets('should navigate to pre-start screen when no completion data', (
      tester,
    ) async {
      // Arrange
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
        defaultBreakDuration: 120,
      );

      mockBloc!.emit(
        RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            isCompleted: false,
            completion: null,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Trigger the navigation callback
      await tester.pumpAndSettle();

      // Assert - should show pre-start screen (which has "Routine Starts In:" text)
      expect(find.text('Routine Starts In:'), findsOneWidget);
    });

    testWidgets('Back to Start button should reset routine', (tester) async {
      // Arrange
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: const [],
      );

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          isCompleted: true,
          actualDuration: 550,
          order: 0,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        defaultBreakDuration: 120,
      );

      mockBloc!.emit(
        RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            isCompleted: true,
            completion: completion,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the Start New Routine button
      await tester.tap(find.text('Back to Start'));
      await tester.pumpAndSettle();

      // Assert - verify ResetRoutine event was added
      // In a real scenario with a mock bloc, we'd verify the event was added
      // For now, we just ensure no errors occurred during the tap
      expect(tester.takeException(), isNull);
    });
  });
}
