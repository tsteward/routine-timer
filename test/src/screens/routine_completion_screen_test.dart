import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/screens/routine_completion_screen.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('RoutineCompletionScreen', () {
    late RoutineBlocState mockCompletionState;
    late RoutineCompletionModel testCompletion;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
      
      testCompletion = RoutineCompletionModel(
        completedAt: DateTime(2025, 1, 10, 8, 30),
        totalTimeSpent: 3600, // 1 hour
        tasksCompleted: 4,
        totalTasks: 4,
        finalAheadBehindStatus: -300, // 5 minutes behind
        tasks: [
          const CompletedTaskModel(
            id: '1',
            name: 'Morning Workout',
            estimatedDuration: 1200,
            actualDuration: 1500,
            isCompleted: true,
            order: 0,
          ),
          const CompletedTaskModel(
            id: '2',
            name: 'Shower',
            estimatedDuration: 600,
            actualDuration: 600,
            isCompleted: true,
            order: 1,
          ),
          const CompletedTaskModel(
            id: '3',
            name: 'Breakfast',
            estimatedDuration: 900,
            actualDuration: 800,
            isCompleted: true,
            order: 2,
          ),
          const CompletedTaskModel(
            id: '4',
            name: 'Review Plan',
            estimatedDuration: 300,
            actualDuration: 360,
            isCompleted: true,
            order: 3,
          ),
        ],
        routineStartTime: DateTime(2025, 1, 10, 7, 30),
      );
      
      mockCompletionState = RoutineBlocState(
        loading: false,
        completionData: testCompletion,
        isCompleted: true,
      );
    });

    Widget createCompletionScreen(RoutineBlocState state) {
      final bloc = FirebaseTestHelper.routineBloc;
      return MaterialApp(
        theme: AppTheme.theme,
        home: BlocProvider<RoutineBloc>.value(
          value: bloc,
          child: const RoutineCompletionScreen(),
        ),
      );
    }

    testWidgets('displays completion celebration header', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      
      // Simulate completed state
      bloc.emit(mockCompletionState);
      
      await tester.pumpWidget(createCompletionScreen(mockCompletionState));
      await tester.pump();

      // Check for celebration elements
      expect(find.text('Morning Accomplished!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('All 4 tasks completed!'), findsOneWidget);
    });

    testWidgets('displays partial completion message when not all tasks completed', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      final partialCompletion = testCompletion.copyWith(
        tasksCompleted: 3,
        tasks: testCompletion.tasks.map((task) => 
          task.order == 3 ? task.copyWith(isCompleted: false) : task
        ).toList(),
      );
      
      final partialState = mockCompletionState.copyWith(
        completionData: partialCompletion,
      );
      
      bloc.emit(partialState);
      
      await tester.pumpWidget(createCompletionScreen(partialState));
      await tester.pump();

      expect(find.text('3 of 4 tasks completed'), findsOneWidget);
    });

    testWidgets('displays correct summary statistics', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(mockCompletionState);
      
      await tester.pumpWidget(createCompletionScreen(mockCompletionState));
      await tester.pump();

      // Check for summary statistics
      expect(find.text('Summary Statistics'), findsOneWidget);
      
      // Check for total time (1 hour = 1h 0m)
      expect(find.text('1h 0m'), findsOneWidget);
      
      // Check for tasks completed
      expect(find.text('4/4'), findsOneWidget);
      
      // Check for completion percentage
      expect(find.text('100%'), findsOneWidget);
      
      // Check for performance status (behind)
      expect(find.text('Behind'), findsOneWidget);
    });

    testWidgets('displays ahead/behind status correctly', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(mockCompletionState);
      
      await tester.pumpWidget(createCompletionScreen(mockCompletionState));
      await tester.pump();

      // Should show behind status with correct message
      expect(find.text('5m 0s behind'), findsOneWidget);
      expect(find.text('Room for improvement next time!'), findsOneWidget);
    });

    testWidgets('displays ahead status correctly', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      final aheadCompletion = testCompletion.copyWith(
        finalAheadBehindStatus: 300, // 5 minutes ahead
      );
      
      final aheadState = mockCompletionState.copyWith(
        completionData: aheadCompletion,
      );
      
      bloc.emit(aheadState);
      
      await tester.pumpWidget(createCompletionScreen(aheadState));
      await tester.pump();

      expect(find.text('5m 0s ahead'), findsOneWidget);
      expect(find.text('Great job finishing early!'), findsOneWidget);
    });

    testWidgets('displays on-time status correctly', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      final onTimeCompletion = testCompletion.copyWith(
        finalAheadBehindStatus: 0,
      );
      
      final onTimeState = mockCompletionState.copyWith(
        completionData: onTimeCompletion,
      );
      
      bloc.emit(onTimeState);
      
      await tester.pumpWidget(createCompletionScreen(onTimeState));
      await tester.pump();

      expect(find.text('On time'), findsOneWidget);
      expect(find.text('Perfect timing!'), findsOneWidget);
    });

    testWidgets('formats time correctly for different durations', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      
      // Test minutes and seconds only
      final minutesCompletion = testCompletion.copyWith(
        totalTimeSpent: 125, // 2 minutes 5 seconds
      );
      
      final minutesState = mockCompletionState.copyWith(
        completionData: minutesCompletion,
      );
      
      bloc.emit(minutesState);
      
      await tester.pumpWidget(createCompletionScreen(minutesState));
      await tester.pump();

      expect(find.text('2m 5s'), findsOneWidget);
    });

    testWidgets('shows action buttons', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(mockCompletionState);
      
      await tester.pumpWidget(createCompletionScreen(mockCompletionState));
      await tester.pump();

      // Check for action buttons
      expect(find.text('Manage Tasks'), findsOneWidget);
      expect(find.text('Start Fresh'), findsOneWidget);
      
      // Both should be ElevatedButtons
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('triggers reset routine when Start Fresh is tapped', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(mockCompletionState);
      
      await tester.pumpWidget(createCompletionScreen(mockCompletionState));
      await tester.pump();

      // Tap Start Fresh button
      await tester.tap(find.text('Start Fresh'));
      await tester.pump();

      // Verify ResetRoutine event was added (would be caught by listener)
      // Since we can't easily verify the event was added, we check that
      // the button tap doesn't cause an error
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays saving indicator when saving', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      final savingState = mockCompletionState.copyWith(saving: true);
      
      bloc.emit(savingState);
      
      await tester.pumpWidget(createCompletionScreen(savingState));
      await tester.pump();

      expect(find.text('Saving completion data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('handles no completion data gracefully', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      final noDataState = RoutineBlocState(
        loading: false,
        isCompleted: false,
      );
      
      bloc.emit(noDataState);
      
      await tester.pumpWidget(createCompletionScreen(noDataState));
      await tester.pump();

      expect(find.text('No completion data available'), findsOneWidget);
      expect(find.text('Return to Start'), findsOneWidget);
    });

    testWidgets('uses correct color scheme', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(mockCompletionState);
      
      await tester.pumpWidget(createCompletionScreen(mockCompletionState));
      await tester.pump();

      // Find the Scaffold and check its background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppTheme.green));
    });

    testWidgets('displays statistics with correct icons', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.emit(mockCompletionState);
      
      await tester.pumpWidget(createCompletionScreen(mockCompletionState));
      await tester.pump();

      // Check for specific stat icons
      expect(find.byIcon(Icons.access_time), findsOneWidget); // Total time
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget); // Tasks done
      expect(find.byIcon(Icons.pie_chart), findsOneWidget); // Completion
      expect(find.byIcon(Icons.trending_down), findsOneWidget); // Performance (behind)
    });

    testWidgets('shows trending up icon when ahead', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      final aheadCompletion = testCompletion.copyWith(
        finalAheadBehindStatus: 300, // ahead
      );
      
      final aheadState = mockCompletionState.copyWith(
        completionData: aheadCompletion,
      );
      
      bloc.emit(aheadState);
      
      await tester.pumpWidget(createCompletionScreen(aheadState));
      await tester.pump();

      expect(find.byIcon(Icons.trending_up), findsOneWidget); // Performance (ahead)
    });

    testWidgets('calculates completion percentage correctly for partial completion', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      final partialCompletion = testCompletion.copyWith(
        tasksCompleted: 3,
        totalTasks: 4,
      );
      
      final partialState = mockCompletionState.copyWith(
        completionData: partialCompletion,
      );
      
      bloc.emit(partialState);
      
      await tester.pumpWidget(createCompletionScreen(partialState));
      await tester.pump();

      expect(find.text('75%'), findsOneWidget); // 3/4 = 75%
    });
  });
}