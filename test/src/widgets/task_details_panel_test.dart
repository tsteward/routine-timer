import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/widgets/task_details_panel.dart';

void main() {
  group('TaskDetailsPanel', () {
    testWidgets('displays task details when routine is loaded', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: TaskDetailsPanel(
                model: loaded.model!,
                task: loaded.model!.tasks.first,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Task Name'), findsOneWidget);
      expect(find.text('Estimated Duration'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      bloc.close();
    });
  });
}
