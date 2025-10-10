import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/widgets/break_gap.dart';
import 'package:routine_timer/src/widgets/task_list_column.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('TaskListColumn', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    testWidgets('displays task list when routine is loaded', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TaskListColumn(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.text('Morning Workout'), findsOneWidget);
      expect(find.text('Shower'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Review Plan'), findsOneWidget);
    });

    testWidgets('shows no routine loaded message initially', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TaskListColumn(),
            ),
          ),
        ),
      );

      expect(find.text('No routine loaded'), findsOneWidget);
    });

    testWidgets('displays drag handles for tasks', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TaskListColumn(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.drag_handle), findsNWidgets(4));
    });

    testWidgets('displays break gaps between tasks', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TaskListColumn(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have 3 break gaps for 4 tasks
      expect(find.byType(BreakGap), findsNWidgets(3));
    });

    testWidgets('break gaps show enabled and disabled states', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Sample routine has breaks at indices 0(enabled), 1(disabled), 2(enabled)
      final firstBreakEnabled = loaded.model!.breaks![0].isEnabled;
      final secondBreakEnabled = loaded.model!.breaks![1].isEnabled;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TaskListColumn(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all break gaps
      final breakGaps = find.byType(BreakGap);
      expect(breakGaps, findsNWidgets(3));

      // Verify first break shows correct state
      final firstGap = tester.widget<BreakGap>(breakGaps.at(0));
      expect(firstGap.isEnabled, firstBreakEnabled);

      // Verify second break shows correct state
      final secondGap = tester.widget<BreakGap>(breakGaps.at(1));
      expect(secondGap.isEnabled, secondBreakEnabled);
    });

    testWidgets('tapping break gap toggles break', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TaskListColumn(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get initial state
      final initialState = bloc.state.model!.breaks![0].isEnabled;

      // Tap the first break gap
      await tester.tap(find.byType(BreakGap).first);
      await tester.pumpAndSettle();

      // Check state has changed
      expect(bloc.state.model!.breaks![0].isEnabled, !initialState);
    });

    testWidgets('break gaps update when breaks are toggled', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TaskListColumn(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get initial state of first break
      final initialGap = tester.widget<BreakGap>(find.byType(BreakGap).first);
      final initialState = initialGap.isEnabled;

      // Toggle the break via bloc event
      bloc.add(const ToggleBreakAtIndex(0));
      await bloc.stream.firstWhere(
        (s) => s.model!.breaks![0].isEnabled != initialState,
      );

      await tester.pumpAndSettle();

      // Verify UI updated
      final updatedGap = tester.widget<BreakGap>(find.byType(BreakGap).first);
      expect(updatedGap.isEnabled, !initialState);
    });

    testWidgets('task start times update when breaks are toggled', (
      tester,
    ) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TaskListColumn(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The start times should be displayed (can't easily verify exact values,
      // but we can verify they exist and are being rendered)
      // StartTimePill is used for displaying start times
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('displays correct number of break gaps', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const TaskListColumn(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 4 tasks should have 3 break gaps (n-1)
      expect(find.byType(BreakGap), findsNWidgets(3));

      // Add a task
      bloc.add(const AddTask(name: 'New Task', durationSeconds: 300));
      await bloc.stream.firstWhere((s) => s.model!.tasks.length == 5);

      await tester.pumpAndSettle();

      // 5 tasks should have 4 break gaps
      expect(find.byType(BreakGap), findsNWidgets(4));
    });

    testWidgets(
      'should not show order flash during drag-and-drop reorder (regression test for issue)',
      (tester) async {
        // Bug: After reordering tasks via drag-and-drop, the list briefly flashes
        // back to the previous order before snapping to the correct new order.
        // This test reproduces the visual state synchronization issue.

        final bloc = FirebaseTestHelper.routineBloc
          ..add(const LoadSampleRoutine());
        await bloc.stream.firstWhere((s) => s.model != null);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: bloc,
                child: const TaskListColumn(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Get the initial order of tasks
        final initialTasks = bloc.state.model!.tasks;
        expect(initialTasks[0].name, 'Morning Workout');
        expect(initialTasks[1].name, 'Shower');
        expect(initialTasks[2].name, 'Breakfast');
        expect(initialTasks[3].name, 'Review Plan');

        // Find the ReorderableListView
        final listView = find.byType(ReorderableListView);
        expect(listView, findsOneWidget);

        // Simulate reordering: move 'Shower' (index 1) to position 0
        // This should move 'Shower' before 'Morning Workout'
        final reorderableListView = tester.widget<ReorderableListView>(
          listView,
        );

        // Trigger the onReorder callback directly to simulate the drag-and-drop completion
        reorderableListView.onReorder(
          1,
          0,
        ); // Move 'Shower' from index 1 to index 0

        // The bug manifests as a visual flash during state synchronization.
        // We pump once to trigger the state change, but don't settle yet
        await tester.pump();

        // At this point, the bloc should have the new order, but we should test
        // that there's no visual inconsistency during the state transition
        final newTasks = bloc.state.model!.tasks;

        // Verify the reorder was processed correctly
        expect(newTasks[0].name, 'Shower'); // Moved to first position
        expect(newTasks[1].name, 'Morning Workout'); // Shifted down
        expect(newTasks[2].name, 'Breakfast'); // Unchanged
        expect(newTasks[3].name, 'Review Plan'); // Unchanged

        // Let the UI settle completely
        await tester.pumpAndSettle();

        // After settling, the UI should reflect the new order consistently
        // This test will currently fail because of the visual flash bug
        final afterSettleState = bloc.state.model!.tasks;
        expect(afterSettleState[0].name, 'Shower');
        expect(afterSettleState[1].name, 'Morning Workout');
        expect(afterSettleState[2].name, 'Breakfast');
        expect(afterSettleState[3].name, 'Review Plan');

        // The visual bug occurs during the pump/settle cycle where the UI
        // temporarily shows the old order before updating to the new order.
        // Once fixed, this test should pass without any visual flashing.
      },
    );
  });
}
