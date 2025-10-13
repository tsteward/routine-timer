import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/screens/main_routine_screen.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('MainRoutineScreen Break Handling', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    testWidgets('displays break screen when in break state', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify task screen is displayed initially
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('Break Time'), findsNothing);

      // Mark task as done to enter break
      bloc.add(const MarkTaskDone(actualDuration: 600));
      await tester.pumpAndSettle();

      // Verify break screen is displayed
      expect(find.text('Break Time'), findsOneWidget);
      expect(find.byIcon(Icons.coffee), findsOneWidget);
      expect(find.text('Skip Break'), findsOneWidget);
      expect(find.text('Next up: Shower'), findsOneWidget);
    });

    testWidgets('skip break button advances to next task', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mark task as done to enter break
      bloc.add(const MarkTaskDone(actualDuration: 600));
      await tester.pumpAndSettle();

      // Verify break screen
      expect(find.text('Break Time'), findsOneWidget);

      // Tap skip break button
      await tester.tap(find.text('Skip Break'));
      await tester.pumpAndSettle();

      // Verify next task is displayed
      expect(find.text('Shower'), findsOneWidget);
      expect(find.text('Break Time'), findsNothing);
    });

    testWidgets('break timer counts down correctly', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mark task as done to enter break (default break is 2 minutes = 120 seconds)
      bloc.add(const MarkTaskDone(actualDuration: 600));
      await tester.pumpAndSettle();

      // Verify initial break timer (should show 02:00 or close to it)
      expect(find.textContaining('02:'), findsOneWidget);

      // Wait for 2 seconds
      await tester.pump(const Duration(seconds: 2));

      // Timer should have decremented (approximately 01:58)
      // Note: Due to timing, we just verify it's counting down
      expect(find.textContaining('01:'), findsOneWidget);
    });

    testWidgets('break screen shows correct progress bar', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mark task as done to enter break
      bloc.add(const MarkTaskDone(actualDuration: 600));
      await tester.pumpAndSettle();

      // Verify progress indicator exists
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('break screen keeps green background', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mark task as done to enter break
      bloc.add(const MarkTaskDone(actualDuration: 600));
      await tester.pumpAndSettle();

      // Find the Scaffold
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));

      // Verify green background (AppTheme.green = Color(0xFF4CAF50))
      expect(scaffold.backgroundColor, const Color(0xFF4CAF50));
    });

    testWidgets('no break shown when break is disabled', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      // Disable first break
      bloc.add(const ToggleBreakAtIndex(0));
      await bloc.stream.firstWhere(
        (s) => s.model!.breaks![0].isEnabled == false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mark task as done
      bloc.add(const MarkTaskDone(actualDuration: 600));
      await tester.pumpAndSettle();

      // Should go directly to next task, not break
      expect(find.text('Break Time'), findsNothing);
      expect(find.text('Shower'), findsOneWidget);
    });

    testWidgets('break screen shows next task name', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mark first task as done
      bloc.add(const MarkTaskDone(actualDuration: 600));
      await tester.pumpAndSettle();

      // Verify next task is shown
      expect(find.text('Next up: Shower'), findsOneWidget);

      // Complete break
      await tester.tap(find.text('Skip Break'));
      await tester.pumpAndSettle();

      // Mark second task as done (break disabled)
      bloc.add(const MarkTaskDone(actualDuration: 700));
      await tester.pumpAndSettle();

      // Should be on third task now (no break for second task)
      expect(find.text('Breakfast'), findsOneWidget);
    });
  });
}
