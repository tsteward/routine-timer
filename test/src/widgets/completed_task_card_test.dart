import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/widgets/completed_task_card.dart';

void main() {
  group('CompletedTaskCard', () {
    late TaskModel completedTask;

    setUp(() {
      completedTask = const TaskModel(
        id: 'task-1',
        name: 'Morning Workout',
        estimatedDuration: 1200, // 20 minutes
        actualDuration: 1350, // 22 minutes 30 seconds
        isCompleted: true,
        order: 1,
      );
    });

    testWidgets('displays task name with strikethrough', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: completedTask)),
        ),
      );

      // Find the text widget
      final textWidget = tester.widget<Text>(find.text('Morning Workout'));

      // Verify strikethrough decoration
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));
    });

    testWidgets('displays checkmark icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: completedTask)),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays actual duration in correct format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: completedTask)),
        ),
      );

      // 1350 seconds = 22 min 30 sec
      expect(find.text('Took: 22 min 30 sec'), findsOneWidget);
    });

    testWidgets('displays duration without seconds if exactly on minute', (
      tester,
    ) async {
      final taskOnMinute = completedTask.copyWith(
        actualDuration: 1200, // Exactly 20 minutes
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: taskOnMinute)),
        ),
      );

      expect(find.text('Took: 20 min'), findsOneWidget);
    });

    testWidgets('displays duration in seconds if less than a minute', (
      tester,
    ) async {
      final quickTask = completedTask.copyWith(
        actualDuration: 45, // 45 seconds
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: quickTask)),
        ),
      );

      expect(find.text('Took: 45 sec'), findsOneWidget);
    });

    testWidgets('displays timer icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: completedTask)),
        ),
      );

      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('has correct styling with reduced opacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: completedTask)),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Morning Workout'));

      // Verify reduced opacity for completed task
      expect(textWidget.style?.color?.a, lessThan(1.0));
    });

    testWidgets('respects custom width parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletedTaskCard(task: completedTask, width: 200),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(200));
    });

    testWidgets('uses default width when not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: completedTask)),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(140));
    });

    testWidgets('handles long task names with ellipsis', (tester) async {
      final longNameTask = completedTask.copyWith(
        name: 'This is a very long task name that should be truncated',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 140,
              child: CompletedTaskCard(task: longNameTask),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(
        find.text('This is a very long task name that should be truncated'),
      );
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      expect(textWidget.maxLines, equals(1));
    });

    testWidgets('handles null actualDuration gracefully', (tester) async {
      final taskWithNullDuration = completedTask.copyWith(actualDuration: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: taskWithNullDuration)),
        ),
      );

      // Should default to 0 sec
      expect(find.textContaining('Took:'), findsOneWidget);
      expect(find.textContaining('0 sec'), findsOneWidget);
    });
  });
}
