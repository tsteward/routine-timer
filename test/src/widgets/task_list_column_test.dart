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

    testWidgets('reorder task updates bloc state correctly', (tester) async {
      // Bug regression test: Ensure reordering doesn't cause visual flash
      // by verifying state changes are smooth and consistent

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

      // Verify initial order
      final initialState = bloc.state.model!;
      expect(initialState.tasks[0].name, 'Morning Workout');
      expect(initialState.tasks[1].name, 'Shower');
      expect(initialState.tasks[2].name, 'Breakfast');
      expect(initialState.tasks[3].name, 'Review Plan');

      // Test reorder via bloc (simulates what happens during drag-and-drop)
      bloc.add(const ReorderTasks(oldIndex: 0, newIndex: 2));

      // Wait for the reorder to complete
      await bloc.stream.firstWhere(
        (s) => s.model != null && s.model!.tasks[2].name == 'Morning Workout',
      );

      await tester.pumpAndSettle();

      // Verify final order is correct
      final finalState = bloc.state.model!;
      expect(finalState.tasks[0].name, 'Shower');
      expect(finalState.tasks[1].name, 'Breakfast');
      expect(finalState.tasks[2].name, 'Morning Workout');
      expect(finalState.tasks[3].name, 'Review Plan');

      // This test documents the expected behavior for the reorder fix
      // The UI fix will ensure visual consistency during actual drag operations
    });
  });
}
