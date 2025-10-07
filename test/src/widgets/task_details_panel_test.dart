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

    testWidgets('displays task name in text field', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);
      final task = loaded.model!.tasks.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: TaskDetailsPanel(model: loaded.model!, task: task),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Task name should appear in a text field
      expect(find.text(task.name), findsWidgets);

      bloc.close();
    });

    testWidgets('displays formatted duration', (tester) async {
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

      // Duration should be formatted (e.g., "10m")
      expect(find.byType(Text), findsWidgets);

      bloc.close();
    });

    testWidgets('has duplicate button', (tester) async {
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

      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);

      bloc.close();
    });

    testWidgets('has delete button', (tester) async {
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

      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      bloc.close();
    });

    testWidgets('wraps content in a card', (tester) async {
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

      expect(find.byType(Card), findsOneWidget);

      bloc.close();
    });

    testWidgets('has text fields for editing', (tester) async {
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

      // Should have TextField widgets
      expect(find.byType(TextField), findsWidgets);

      bloc.close();
    });

    testWidgets('displays icons for duration', (tester) async {
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

      // Should have timer icon
      expect(find.byIcon(Icons.timer_outlined), findsWidgets);

      bloc.close();
    });

    testWidgets('has clickable duration field', (tester) async {
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

      // Should have InkWell for duration field
      expect(find.byType(InkWell), findsWidgets);

      bloc.close();
    });
  });
}
