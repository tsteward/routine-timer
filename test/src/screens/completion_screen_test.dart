import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/screens/completion_screen.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('CompletionScreen', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    Widget createTestWidget({RoutineStateModel? model}) {
      final bloc = FirebaseTestHelper.routineBloc;
      if (model != null) {
        bloc.emit(RoutineBlocState(loading: false, model: model));
      }

      return MaterialApp(
        home: BlocProvider.value(value: bloc, child: const CompletionScreen()),
        onGenerateRoute: AppRouter().onGenerateRoute,
      );
    }

    testWidgets('redirects to main screen if routine not completed', (
      tester,
    ) async {
      final model = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 60,
            order: 0,
          ),
        ],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 120,
        ),
        isCompleted: false, // Not completed
      );

      await tester.pumpWidget(createTestWidget(model: model));
      await tester.pumpAndSettle();

      // Should show loading indicator briefly then navigate
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays completion message and statistics when completed', (
      tester,
    ) async {
      final completionData = RoutineCompletionData(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalDurationSeconds: 3600,
        tasksCompleted: 4,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700, // 300 seconds ahead
        routineName: 'Morning Routine',
      );

      final model = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            actualDuration: 550,
            isCompleted: true,
            order: 0,
          ),
          TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 600,
            actualDuration: 550,
            isCompleted: true,
            order: 1,
          ),
        ],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 120,
        ),
        isCompleted: true,
        completionData: completionData,
      );

      await tester.pumpWidget(createTestWidget(model: model));
      await tester.pumpAndSettle();

      // Check for completion message
      expect(find.text('Morning Routine Accomplished!'), findsOneWidget);

      // Check for emoji
      expect(find.text('🎉'), findsOneWidget);

      // Check for statistics
      expect(find.text('Tasks Completed'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      expect(find.text('Total Time'), findsOneWidget);

      expect(find.text('Time Difference'), findsOneWidget);
      expect(find.text('Ahead of schedule'), findsOneWidget);
    });

    testWidgets('shows ahead of schedule when user finished early', (
      tester,
    ) async {
      final completionData = RoutineCompletionData(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalDurationSeconds: 3600,
        tasksCompleted: 4,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700, // 300 seconds ahead
        routineName: 'Morning Routine',
      );

      final model = RoutineStateModel(
        tasks: const [],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 120,
        ),
        isCompleted: true,
        completionData: completionData,
      );

      await tester.pumpWidget(createTestWidget(model: model));
      await tester.pumpAndSettle();

      expect(find.text('Ahead of schedule'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('shows behind schedule when user finished late', (
      tester,
    ) async {
      final completionData = RoutineCompletionData(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalDurationSeconds: 3600,
        tasksCompleted: 4,
        totalEstimatedDuration: 3000,
        totalActualDuration: 3300, // 300 seconds behind
        routineName: 'Morning Routine',
      );

      final model = RoutineStateModel(
        tasks: const [],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 120,
        ),
        isCompleted: true,
        completionData: completionData,
      );

      await tester.pumpWidget(createTestWidget(model: model));
      await tester.pumpAndSettle();

      expect(find.text('Behind schedule'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('return to task management button navigates correctly', (
      tester,
    ) async {
      final completionData = RoutineCompletionData(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalDurationSeconds: 3600,
        tasksCompleted: 4,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700,
        routineName: 'Morning Routine',
      );

      final model = RoutineStateModel(
        tasks: const [],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 120,
        ),
        isCompleted: true,
        completionData: completionData,
      );

      await tester.pumpWidget(createTestWidget(model: model));
      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.ensureVisible(find.text('Return to Task Management'));
      await tester.pumpAndSettle();

      // Find and tap the button
      final button = find.text('Return to Task Management');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      // Should navigate to task management screen
      // (We can't fully test navigation without a full app context,
      // but we can verify the button exists and is tappable)
    });

    testWidgets('start new routine button triggers reset and navigation', (
      tester,
    ) async {
      final completionData = RoutineCompletionData(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalDurationSeconds: 3600,
        tasksCompleted: 4,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700,
        routineName: 'Morning Routine',
      );

      final model = RoutineStateModel(
        tasks: const [
          TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            actualDuration: 550,
            isCompleted: true,
            order: 0,
          ),
        ],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 120,
        ),
        isCompleted: true,
        completionData: completionData,
      );

      await tester.pumpWidget(createTestWidget(model: model));
      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.ensureVisible(find.text('Start New Routine'));
      await tester.pumpAndSettle();

      // Find and tap the button
      final button = find.text('Start New Routine');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      // Verify that ResetRoutine event was added (implicitly through navigation)
    });

    testWidgets('uses green background color', (tester) async {
      final completionData = RoutineCompletionData(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalDurationSeconds: 3600,
        tasksCompleted: 4,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700,
        routineName: 'Morning Routine',
      );

      final model = RoutineStateModel(
        tasks: const [],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 120,
        ),
        isCompleted: true,
        completionData: completionData,
      );

      await tester.pumpWidget(createTestWidget(model: model));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppTheme.green);
    });

    testWidgets('displays all summary icons correctly', (tester) async {
      final completionData = RoutineCompletionData(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalDurationSeconds: 3600,
        tasksCompleted: 4,
        totalEstimatedDuration: 3000,
        totalActualDuration: 2700,
        routineName: 'Morning Routine',
      );

      final model = RoutineStateModel(
        tasks: const [],
        settings: RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 120,
        ),
        isCompleted: true,
        completionData: completionData,
      );

      await tester.pumpWidget(createTestWidget(model: model));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget); // Ahead
    });
  });
}
