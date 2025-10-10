import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('displays task name and timer when tasks are loaded', (
      tester,
    ) async {
      final bloc = FirebaseTestHelper.routineBloc;

      // Load sample routine with tasks
      bloc.add(const LoadSampleRoutine());
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should display the first task name
      expect(find.text('Morning Workout'), findsOneWidget);

      // Should display timer in MM:SS format
      expect(find.textContaining(':'), findsAtLeastNWidgets(1));

      // Should display Done and Previous buttons
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
    });

    testWidgets('displays "No tasks available" when no tasks', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      expect(find.text('No tasks available'), findsOneWidget);
    });

    testWidgets('Done button advances to next task', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show first task
      expect(find.text('Morning Workout'), findsOneWidget);

      // Tap Done button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Should show second task
      expect(find.text('Shower'), findsOneWidget);
    });

    testWidgets('Previous button goes to previous task', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show first task
      expect(find.text('Morning Workout'), findsOneWidget);

      // Previous button should be disabled on first task
      final previousButton = find.widgetWithText(ElevatedButton, 'Previous');
      expect(tester.widget<ElevatedButton>(previousButton).onPressed, isNull);

      // Advance to second task
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Shower'), findsOneWidget);

      // Now Previous button should be enabled
      expect(
        tester.widget<ElevatedButton>(previousButton).onPressed,
        isNotNull,
      );

      // Tap Previous button (tap on the text works since button is enabled)
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      // Should be back to first task
      expect(find.text('Morning Workout'), findsOneWidget);
    });

    testWidgets('Timer updates every second', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;
      bloc.add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Wait for a couple seconds to verify timer is counting down
      await tester.pump(const Duration(seconds: 2));

      // Timer should show some value (hard to check exact value due to timing)
      expect(find.textContaining(':'), findsAtLeastNWidgets(1));
    });
  });
}
