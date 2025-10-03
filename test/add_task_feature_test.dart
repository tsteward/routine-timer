import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/screens/task_management_screen.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';

void main() {
  group('RoutineBloc AddTask', () {
    test('appends task and extends breaks with defaults', () async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      // Pre-conditions from sample
      expect(loaded.model!.tasks.length, 4);
      expect(loaded.model!.breaks!.length, 3);

      final defaultBreakDuration = loaded.model!.settings.defaultBreakDuration;
      final defaultBreakEnabled =
          loaded.model!.settings.breaksEnabledByDefault;

      bloc.add(const AddTask(name: 'Newly Added', estimatedDurationSeconds: 180));

      final updated = await bloc.stream.firstWhere(
        (s) => s.model!.tasks.length == 5,
      );

      // Tasks
      expect(updated.model!.tasks.last.name, 'Newly Added');
      expect(updated.model!.tasks.last.order, 4);
      expect(updated.model!.tasks.last.estimatedDuration, 180);

      // Breaks extended by one and uses defaults
      expect(updated.model!.breaks!.length, 4);
      expect(updated.model!.breaks!.last.duration, defaultBreakDuration);
      expect(updated.model!.breaks!.last.isEnabled, defaultBreakEnabled);

      await bloc.close();
    });
  });

  group('TaskManagementScreen bottom bar + add task flow', () {
    testWidgets('adds task and updates total minutes', (tester) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      // Load sample data
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Bottom bar exists
      expect(find.text('Est. Finish'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Add New Task'), findsOneWidget);

      // Initial total from sample tasks: 20 + 10 + 15 + 5 = 50 min
      expect(find.text('50 min'), findsOneWidget);

      // Open add dialog
      await tester.tap(find.text('Add New Task'));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task name'),
        'UI New Task',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Duration (minutes)'),
        '3',
      );

      // Submit
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // Verify new task appears at end and total updates
      expect(find.text('UI New Task'), findsOneWidget);
      expect(find.text('53 min'), findsOneWidget);

      await bloc.close();
    });
  });
}
