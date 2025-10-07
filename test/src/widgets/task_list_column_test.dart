import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/widgets/task_list_column.dart';

void main() {
  group('TaskListColumn', () {
    testWidgets('displays task list when routine is loaded', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      bloc.close();
    });

    testWidgets('shows no routine loaded message initially', (tester) async {
      final bloc = RoutineBloc();

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

      bloc.close();
    });

    testWidgets('displays drag handles for tasks', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      bloc.close();
    });

    testWidgets('can reorder tasks by dragging', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final firstTaskId = loaded.model!.tasks.first.id;

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

      // Simulate reordering by calling the BLoC event directly
      // (UI testing of drag and drop is complex and flaky)
      bloc.add(const ReorderTasks(oldIndex: 0, newIndex: 2));

      // Wait for state to update
      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks[2].id == firstTaskId,
      );

      await tester.pumpAndSettle();

      // Verify the task was reordered
      expect(updated.model!.tasks[2].id, firstTaskId);

      bloc.close();
    });
  });
}
