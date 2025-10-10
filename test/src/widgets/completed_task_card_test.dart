import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/widgets/completed_task_card.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('CompletedTaskCard Widget Tests', () {
    late TaskModel testCompletedTask;

    setUp(() {
      testCompletedTask = const TaskModel(
        id: 'task-1',
        name: 'Completed Task',
        estimatedDuration: 600,
        actualDuration: 720, // Took 12 minutes
        isCompleted: true,
        order: 1,
      );
    });

    testWidgets('should display task name with checkmark icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: testCompletedTask)),
        ),
      );

      expect(find.text('Completed Task'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display actual duration in correct format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: testCompletedTask)),
        ),
      );

      // 720 seconds = 12 minutes, 0 seconds
      expect(find.text('Took: 12m'), findsOneWidget);
    });

    testWidgets('should format duration with minutes and seconds', (
      WidgetTester tester,
    ) async {
      final taskWithSeconds = testCompletedTask.copyWith(
        actualDuration: 725, // 12 minutes, 5 seconds
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: taskWithSeconds)),
        ),
      );

      expect(find.text('Took: 12m 5s'), findsOneWidget);
    });

    testWidgets(
      'should format duration with only seconds when under 1 minute',
      (WidgetTester tester) async {
        final taskWithOnlySeconds = testCompletedTask.copyWith(
          actualDuration: 45, // 45 seconds
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CompletedTaskCard(task: taskWithOnlySeconds)),
          ),
        );

        expect(find.text('Took: 45s'), findsOneWidget);
      },
    );

    testWidgets('should apply strike-through decoration to task name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: testCompletedTask)),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Completed Task'));
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));
    });

    testWidgets('should show green check icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: testCompletedTask)),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(iconWidget.color, equals(Colors.green));
    });

    testWidgets('should handle null actual duration gracefully', (
      WidgetTester tester,
    ) async {
      // Create a task with null actualDuration directly (copyWith doesn't work for setting to null)
      const taskWithoutDuration = TaskModel(
        id: 'task-1',
        name: 'Completed Task',
        estimatedDuration: 600,
        actualDuration: null, // Explicitly null
        isCompleted: true,
        order: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTaskCard(task: taskWithoutDuration)),
        ),
      );

      // Should still show task name and checkmark
      expect(find.text('Completed Task'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // But no duration text should be shown
      expect(find.textContaining('Took:'), findsNothing);
    });

    testWidgets('should respect custom width parameter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                CompletedTaskCard(task: testCompletedTask, width: 200),
              ],
            ),
          ),
        ),
      );

      // Find the CompletedTaskCard widget and check its size
      final cardWidget = tester.widget<CompletedTaskCard>(
        find.byType(CompletedTaskCard),
      );
      expect(cardWidget.width, equals(200));
    });
  });
}
