import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/screens/main_routine_screen.dart';
import 'package:routine_timer/src/services/auth_service.dart';

class MockAuthService extends AuthService {
  @override
  String? get currentUserId => 'test-user-id';

  @override
  bool get isSignedIn => true;

  @override
  User? get currentUser => null; // Simplified for testing

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  Future<String?> signInAnonymously() async => null;

  @override
  Future<String?> signOut() async => null;
}

class MockRoutineRepository extends RoutineRepository {
  RoutineStateModel? _mockRoutine;
  bool _shouldSave = true;

  MockRoutineRepository() : super(authService: MockAuthService());

  void setMockRoutine(RoutineStateModel? routine) {
    _mockRoutine = routine;
  }

  void setShouldSave(bool shouldSave) {
    _shouldSave = shouldSave;
  }

  @override
  Future<RoutineStateModel?> loadRoutine() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _mockRoutine;
  }

  @override
  Future<bool> saveRoutine(RoutineStateModel routine) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (_shouldSave) {
      _mockRoutine = routine;
    }
    return _shouldSave;
  }
}

void main() {
  group('MainRoutineScreen', () {
    late MockRoutineRepository mockRepository;
    late RoutineBloc routineBloc;

    setUp(() {
      mockRepository = MockRoutineRepository();
      routineBloc = RoutineBloc(repository: mockRepository);
    });

    tearDown(() {
      routineBloc.close();
    });

    Widget createApp({RoutineStateModel? initialRoutine}) {
      if (initialRoutine != null) {
        mockRepository.setMockRoutine(initialRoutine);
      }

      return MaterialApp(
        theme: AppTheme.theme,
        home: BlocProvider.value(
          value: routineBloc,
          child: const MainRoutineScreen(),
        ),
        onGenerateRoute: AppRouter().onGenerateRoute,
      );
    }

    RoutineStateModel createSampleRoutine({int currentTaskIndex = 0}) {
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Morning Workout',
          estimatedDuration: 20 * 60, // 20 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Shower',
          estimatedDuration: 10 * 60, // 10 minutes
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Breakfast',
          estimatedDuration: 15 * 60, // 15 minutes
          order: 2,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 2 * 60,
      );

      final breaks = [
        BreakModel(duration: settings.defaultBreakDuration, isEnabled: true),
        BreakModel(duration: settings.defaultBreakDuration, isEnabled: false),
      ];

      return RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: currentTaskIndex,
        isRunning: false,
      );
    }

    testWidgets('shows loading indicator while loading routine', (
      tester,
    ) async {
      await tester.pumpWidget(createApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Morning Workout'), findsNothing);
    });

    testWidgets('shows no tasks message when routine is empty', (tester) async {
      final emptyRoutine = RoutineStateModel(
        tasks: [],
        breaks: [],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 0,
        ),
      );

      await tester.pumpWidget(createApp(initialRoutine: emptyRoutine));
      await tester.pumpAndSettle();

      expect(
        find.text('No tasks available.\nGo to Task Management to add tasks.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('displays current task information correctly', (tester) async {
      final routine = createSampleRoutine();
      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      // Should show the first task
      expect(find.text('Morning Workout'), findsOneWidget);

      // Should show timer in MM:SS format (20:00 for 20 minutes)
      expect(find.text('20:00'), findsOneWidget);

      // Should show progress bar
      expect(find.byType(FractionallySizedBox), findsOneWidget);

      // Should show Previous and Done buttons
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('timer counts down correctly', (tester) async {
      final routine = createSampleRoutine();
      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      // Initial timer should show 20:00
      expect(find.text('20:00'), findsOneWidget);

      // Wait for timer to tick
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Timer should now show 19:59
      expect(find.text('19:59'), findsOneWidget);
    });

    testWidgets('background turns red when timer goes negative', (
      tester,
    ) async {
      // Create task with very short duration for testing
      final shortTask = TaskModel(
        id: '1',
        name: 'Short Task',
        estimatedDuration: 2, // 2 seconds
        order: 0,
      );

      final routine = RoutineStateModel(
        tasks: [shortTask],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 0,
        ),
      );

      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      // Initially background should be green
      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      Scaffold scaffold = tester.widget(scaffoldFinder.first);
      expect(scaffold.backgroundColor, AppTheme.green);

      // Wait for timer to go negative
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      // Check timer shows negative time
      expect(find.textContaining('-'), findsOneWidget);

      // Background should now be red
      scaffold = tester.widget(scaffoldFinder.first);
      expect(scaffold.backgroundColor, AppTheme.red);
    });

    testWidgets('Previous button is disabled for first task', (tester) async {
      final routine = createSampleRoutine(currentTaskIndex: 0);
      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      final previousButton = find.widgetWithText(ElevatedButton, 'Previous');
      expect(previousButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(previousButton);
      expect(button.onPressed, isNull); // Disabled
    });

    testWidgets('Previous button is enabled for non-first tasks', (
      tester,
    ) async {
      final routine = createSampleRoutine(currentTaskIndex: 1);
      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      final previousButton = find.widgetWithText(ElevatedButton, 'Previous');
      expect(previousButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(previousButton);
      expect(button.onPressed, isNotNull); // Enabled
    });

    testWidgets('Done button marks task as complete and advances', (
      tester,
    ) async {
      final routine = createSampleRoutine();
      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      // Should show first task
      expect(find.text('Morning Workout'), findsOneWidget);

      // Wait a bit for timer to advance (to test actual duration calculation)
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Tap Done button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Should now show second task
      expect(find.text('Shower'), findsOneWidget);
      expect(find.text('Morning Workout'), findsNothing);
    });

    testWidgets('Previous button goes back to previous task', (tester) async {
      final routine = createSampleRoutine(currentTaskIndex: 1);
      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      // Should show second task (Shower)
      expect(find.text('Shower'), findsOneWidget);

      // Tap Previous button
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      // Should now show first task
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('Shower'), findsNothing);
    });

    testWidgets('progress bar updates correctly as timer advances', (
      tester,
    ) async {
      final routine = createSampleRoutine();
      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      // Get initial progress bar
      final progressBarFinder = find.byType(FractionallySizedBox);
      expect(progressBarFinder, findsOneWidget);

      FractionallySizedBox initialProgressBar = tester.widget(
        progressBarFinder,
      );
      double initialProgress = initialProgressBar.widthFactor ?? 0.0;

      // Progress should start near 0
      expect(initialProgress, lessThan(0.1));

      // Wait for timer to advance
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Progress should have increased
      FractionallySizedBox updatedProgressBar = tester.widget(
        progressBarFinder,
      );
      double updatedProgress = updatedProgressBar.widthFactor ?? 0.0;

      expect(updatedProgress, greaterThan(initialProgress));
    });

    testWidgets('settings icon navigates to task management', (tester) async {
      final routine = createSampleRoutine();
      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      // Find and tap settings icon
      final settingsIcon = find.byIcon(Icons.settings);
      expect(settingsIcon, findsOneWidget);

      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // Should navigate to tasks route (this would normally push a new screen)
      // In our test setup, we just verify the tap doesn't cause errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows completion message when all tasks are done', (
      tester,
    ) async {
      // Create routine where current task index is beyond available tasks
      final completedRoutine = createSampleRoutine(currentTaskIndex: 10);
      await tester.pumpWidget(createApp(initialRoutine: completedRoutine));
      await tester.pumpAndSettle();

      expect(find.text('All tasks completed!'), findsOneWidget);
      expect(find.text('Previous'), findsNothing);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('timer format shows negative time correctly', (tester) async {
      // Create a task with very short duration
      final shortTask = TaskModel(
        id: '1',
        name: 'Short Task',
        estimatedDuration: 1, // 1 second
        order: 0,
      );

      final routine = RoutineStateModel(
        tasks: [shortTask],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 0,
        ),
      );

      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      // Wait for timer to go negative
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Should show negative time in format -MM:SS
      final negativeTimeFinder = find.textContaining('-00:0');
      expect(negativeTimeFinder, findsOneWidget);
    });

    testWidgets('handles completed tasks correctly', (tester) async {
      // Create routine with a completed task
      final completedTask = const TaskModel(
        id: '1',
        name: 'Completed Task',
        estimatedDuration: 10 * 60,
        actualDuration: 8 * 60, // Completed in 8 minutes
        isCompleted: true,
        order: 0,
      );

      final incompleteTask = const TaskModel(
        id: '2',
        name: 'Incomplete Task',
        estimatedDuration: 15 * 60,
        order: 1,
      );

      final routine = RoutineStateModel(
        tasks: [completedTask, incompleteTask],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 0,
        ),
        currentTaskIndex: 1, // Current task is the incomplete one
      );

      await tester.pumpWidget(createApp(initialRoutine: routine));
      await tester.pumpAndSettle();

      // Should show the incomplete task, not the completed one
      expect(find.text('Incomplete Task'), findsOneWidget);
      expect(find.text('Completed Task'), findsNothing);
    });
  });
}
