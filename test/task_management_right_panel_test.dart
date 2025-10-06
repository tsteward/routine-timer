import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/screens/task_management_screen.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/app_theme.dart';

void main() {
  group('Right Panel interactions', () {
    testWidgets('populates when task selected and saves changes', (tester) async {
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

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Select 2nd task
      await tester.tap(find.text('Shower'));
      await tester.pumpAndSettle();

      // Ensure fields present
      expect(find.widgetWithText(TextFormField, 'Task Name'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Estimated Duration (minutes)'),
        findsOneWidget,
      );

      // Change task name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Task Name'),
        'Quick Shower',
      );
      await tester.pump();

      // Change break duration
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Break Duration (minutes)'),
        '3',
      );
      await tester.pump();

      // Save
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      // Verify bloc updated
      expect(bloc.state.model!.tasks[1].name, 'Quick Shower');
      expect(bloc.state.model!.settings.defaultBreakDuration, 3 * 60);

      bloc.close();
    });

    testWidgets('duplicate and delete task', (tester) async {
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

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Select first task
      await tester.tap(find.text('Morning Workout'));
      await tester.pumpAndSettle();

      final initialLen = bloc.state.model!.tasks.length;

      // Duplicate
      await tester.tap(find.widgetWithText(OutlinedButton, 'Duplicate'));
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, initialLen + 1);

      // Delete
      await tester.tap(find.widgetWithText(FilledButton, 'Delete Task'));
      await tester.pumpAndSettle();
      expect(bloc.state.model!.tasks.length, initialLen);

      bloc.close();
    });
  });
}
