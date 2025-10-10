import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/widgets/task_card.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('TaskCard Widget Tests', () {
    late TaskModel testTask;

    setUp(() {
      testTask = const TaskModel(
        id: 'test-task-1',
        name: 'Test Task',
        estimatedDuration: 600, // 10 minutes
        order: 1,
      );
    });

    testWidgets('should display task name correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskCard(task: testTask)),
        ),
      );

      expect(find.text('Test Task'), findsOneWidget);
    });

    testWidgets('should display formatted duration correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskCard(task: testTask)),
        ),
      );

      // 600 seconds = 10 minutes should be formatted as "10m"
      expect(find.text('10m'), findsOneWidget);
    });

    testWidgets('should show timer icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskCard(task: testTask)),
        ),
      );

      expect(find.byIcon(Icons.timer), findsOneWidget);
    });

    testWidgets('should respect custom width when provided', (
      WidgetTester tester,
    ) async {
      const customWidth = 200.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(task: testTask, width: customWidth),
          ),
        ),
      );

      final card = tester.widget<Container>(find.byType(Container));
      expect(card.constraints?.maxWidth, equals(customWidth));
    });

    testWidgets('should truncate long task names properly', (
      WidgetTester tester,
    ) async {
      final longNameTask = testTask.copyWith(
        name:
            'This is a very long task name that should be truncated in the card display',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskCard(task: longNameTask, width: 140)),
        ),
      );

      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byType(Text).first);
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      expect(textWidget.maxLines, equals(2));
    });

    testWidgets('should format hours correctly for longer tasks', (
      WidgetTester tester,
    ) async {
      final longTask = testTask.copyWith(
        estimatedDuration: 3900, // 1 hour 5 minutes
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskCard(task: longTask)),
        ),
      );

      // 3900 seconds = 1h 5m
      expect(find.text('1h 5m'), findsOneWidget);
    });
  });
}
