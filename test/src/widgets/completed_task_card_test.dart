import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/widgets/completed_task_card.dart';
import 'package:routine_timer/src/models/task.dart';

void main() {
  group('CompletedTaskCard', () {
    late TaskModel testTask;

    setUp(() {
      testTask = const TaskModel(
        id: 'test-task-1',
        name: 'Test Task',
        estimatedDuration: 300, // 5 minutes
        actualDuration: 360, // 6 minutes
        isCompleted: true,
        order: 1,
      );
    });

    Widget createWidget(TaskModel task, {double? width}) {
      return MaterialApp(
        home: Scaffold(
          body: CompletedTaskCard(task: task, width: width),
        ),
      );
    }

    testWidgets('displays task name with strikethrough', (tester) async {
      await tester.pumpWidget(createWidget(testTask));

      final taskNameText = find.text('Test Task');
      expect(taskNameText, findsOneWidget);

      final textWidget = tester.widget<Text>(taskNameText);
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('displays checkmark icon', (tester) async {
      await tester.pumpWidget(createWidget(testTask));

      final checkIcon = find.byIcon(Icons.check_circle);
      expect(checkIcon, findsOneWidget);
    });

    testWidgets('displays actual duration in correct format', (tester) async {
      await tester.pumpWidget(createWidget(testTask));

      final durationText = find.text('Took: 6m');
      expect(durationText, findsOneWidget);
    });

    testWidgets('formats duration with minutes and seconds when both present', (
      tester,
    ) async {
      final taskWithSeconds = testTask.copyWith(actualDuration: 125); // 2m 5s
      await tester.pumpWidget(createWidget(taskWithSeconds));

      final durationText = find.text('Took: 2m 5s');
      expect(durationText, findsOneWidget);
    });

    testWidgets('formats duration with only seconds when less than a minute', (
      tester,
    ) async {
      final taskWithSeconds = testTask.copyWith(actualDuration: 45); // 45s
      await tester.pumpWidget(createWidget(taskWithSeconds));

      final durationText = find.text('Took: 45s');
      expect(durationText, findsOneWidget);
    });

    testWidgets('does not display duration if actualDuration is null', (
      tester,
    ) async {
      // Create a task with explicitly null actualDuration
      const taskWithoutDuration = TaskModel(
        id: 'test-task-null',
        name: 'Test Task No Duration',
        estimatedDuration: 300,
        actualDuration: null, // Explicitly null
        isCompleted: true,
        order: 1,
      );
      await tester.pumpWidget(createWidget(taskWithoutDuration));

      final timerIcon = find.byIcon(Icons.timer);
      expect(timerIcon, findsNothing);
    });

    testWidgets('applies correct width when specified', (tester) async {
      await tester.pumpWidget(createWidget(testTask, width: 200));

      // Verify the widget renders without error when width is specified
      expect(find.byType(CompletedTaskCard), findsOneWidget);

      // The Container includes margin of 8 pixels on the right, so total width is 208
      final renderBox = tester.renderObject<RenderBox>(
        find.byType(CompletedTaskCard),
      );
      expect(renderBox.size.width, equals(208.0));
    });

    testWidgets('uses default width when not specified', (tester) async {
      await tester.pumpWidget(createWidget(testTask));

      // Should not throw any errors and should render correctly
      expect(find.byType(CompletedTaskCard), findsOneWidget);
    });

    testWidgets('handles long task names with ellipsis', (tester) async {
      final longNameTask = testTask.copyWith(
        name:
            'This is a very long task name that should be truncated with ellipsis',
      );
      await tester.pumpWidget(createWidget(longNameTask));

      final textWidget = tester.widget<Text>(find.text(longNameTask.name));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 2);
    });

    testWidgets('applies proper styling for completed state', (tester) async {
      await tester.pumpWidget(createWidget(testTask));

      // Verify the card has the expected styling
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.borderRadius,
        const BorderRadius.all(Radius.circular(12)),
      );
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.border, isNotNull);
    });
  });
}
