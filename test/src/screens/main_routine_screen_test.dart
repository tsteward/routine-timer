import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/screens/main_routine_screen.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('MainRoutineScreen', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    Future<RoutineBloc> pumpWithSample(
      WidgetTester tester, {
      int firstDuration = 300,
      int secondDuration = 120,
    }) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Override first two task durations for fast tests
      final first = loaded.model!.tasks[0].copyWith(
        estimatedDuration: firstDuration,
      );
      final second = loaded.model!.tasks[1].copyWith(
        estimatedDuration: secondDuration,
      );
      bloc.add(UpdateTask(index: 0, task: first));
      bloc.add(UpdateTask(index: 1, task: second));
      await bloc.stream.firstWhere(
        (s) => s.model!.tasks[0].estimatedDuration == firstDuration,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      // Allow first build
      await tester.pump();
      return bloc;
    }

    testWidgets('shows task name and countdown in MM:SS format', (
      tester,
    ) async {
      await pumpWithSample(tester, firstDuration: 300); // 5 minutes

      // Task name displayed
      expect(find.text('Morning Workout'), findsOneWidget);

      // Countdown starts at 05:00
      expect(find.text('05:00'), findsOneWidget);
    });

    testWidgets('timer goes negative and background turns red', (tester) async {
      await pumpWithSample(tester, firstDuration: 1);

      // Initially green background
      final scaffold1 = tester.widgetList<Scaffold>(find.byType(Scaffold)).last;
      expect(scaffold1.backgroundColor, AppTheme.green);

      // Advance 2 seconds -> remaining = -1
      await tester.pump(const Duration(seconds: 2));
      final scaffold2 = tester.widgetList<Scaffold>(find.byType(Scaffold)).last;
      expect(scaffold2.backgroundColor, AppTheme.red);
      expect(find.text('-00:01'), findsOneWidget);
    });

    testWidgets('Done advances to next task and records duration', (
      tester,
    ) async {
      final bloc = await pumpWithSample(
        tester,
        firstDuration: 5,
        secondDuration: 5,
      );

      // Let 3 seconds elapse
      await tester.pump(const Duration(seconds: 3));

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pump();

      // Pump a frame to reflect bloc state change in UI
      await tester.pump();
      // UI shows next task name
      expect(find.text('Shower'), findsOneWidget);

      // Actual duration recorded for first task
      final actual = bloc.state.model!.tasks.first.actualDuration;
      expect(actual, 3);
      expect(bloc.state.model!.tasks.first.isCompleted, true);
    });

    testWidgets('Previous returns to prior task and restores its timer state', (
      tester,
    ) async {
      await pumpWithSample(
        tester,
        firstDuration: 5,
        secondDuration: 5,
      );

      // Elapse 3 seconds on first, then Done to go to second
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump();

      // Spend 2 seconds on second task
      await tester.pump(const Duration(seconds: 2));

      // Tap Previous to go back
      await tester.tap(find.text('Previous'));
      await tester.pump();

      // UI shows first task name and remaining was 5 - 3 = 2 seconds
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('00:02'), findsOneWidget);
    });

    testWidgets('progress bar updates with elapsed time', (tester) async {
      await pumpWithSample(tester, firstDuration: 5);

      // After 2 seconds, progress should be ~0.4
      await tester.pump(const Duration(seconds: 2));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, closeTo(0.4, 0.05));
    });
  });
}
