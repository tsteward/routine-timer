import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/widgets/task_list_column.dart';

import '../../helpers/fake_routine_repository.dart';

void main() {
  group('TaskListColumn', () {
    testWidgets('displays task list when routine is loaded', (tester) async {
      final bloc = RoutineBloc(repository: FakeRoutineRepository())
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
      final bloc = RoutineBloc(repository: FakeRoutineRepository())
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

      bloc.close();
    });
  });
}
