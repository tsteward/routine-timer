import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/widgets/task_drawer.dart';

void main() {
  group('TaskDrawer', () {
    late List<TaskModel> mockTasks;

    setUp(() {
      mockTasks = [
        const TaskModel(
          id: '1',
          name: 'Brush Teeth',
          estimatedDuration: 120, // 2 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Take Shower',
          estimatedDuration: 600, // 10 minutes
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Get Dressed',
          estimatedDuration: 300, // 5 minutes
          order: 2,
        ),
        const TaskModel(
          id: '4',
          name: 'Make Coffee',
          estimatedDuration: 240, // 4 minutes
          order: 3,
        ),
      ];
    });

    testWidgets('should display nothing when no upcoming tasks', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TaskDrawer(upcomingTasks: [])),
        ),
      );

      expect(find.byType(TaskDrawer), findsOneWidget);
      expect(find.text('Up Next'), findsNothing);
    });

    testWidgets('should display collapsed drawer with up to 3 tasks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TaskDrawer(upcomingTasks: mockTasks, isExpanded: false),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Up Next" label
      expect(find.text('Up Next'), findsOneWidget);

      // Should show "Show More" text
      expect(find.text('Show More'), findsOneWidget);

      // Should show first 3 tasks in horizontal scroll
      expect(find.text('Brush Teeth'), findsOneWidget);
      expect(find.text('Take Shower'), findsOneWidget);
      expect(find.text('Get Dressed'), findsOneWidget);

      // Fourth task should not be visible in collapsed state
      expect(find.text('Make Coffee'), findsNothing);

      // Should show duration formatting
      expect(find.text('2m 0s'), findsOneWidget); // Brush Teeth duration
      expect(find.text('10m 0s'), findsOneWidget); // Take Shower duration
    });

    testWidgets('should expand drawer when Show More is tapped', (
      tester,
    ) async {
      bool isExpanded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                StatefulBuilder(
                  builder: (context, setState) {
                    return TaskDrawer(
                      upcomingTasks: mockTasks,
                      isExpanded: isExpanded,
                      onExpandChanged: (expanded) {
                        setState(() {
                          isExpanded = expanded;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Show More" initially
      expect(find.text('Show More'), findsOneWidget);
      expect(find.text('Show Less'), findsNothing);

      // Tap the Show More area
      await tester.tap(find.text('Show More'));
      await tester.pumpAndSettle();

      // Should now show "Show Less"
      expect(find.text('Show Less'), findsOneWidget);
      expect(find.text('Show More'), findsNothing);
    });

    testWidgets('should display all tasks in expanded state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TaskDrawer(upcomingTasks: mockTasks, isExpanded: true),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Show Less" text
      expect(find.text('Show Less'), findsOneWidget);

      // Should show all tasks
      expect(find.text('Brush Teeth'), findsOneWidget);
      expect(find.text('Take Shower'), findsOneWidget);
      expect(find.text('Get Dressed'), findsOneWidget);
      expect(find.text('Make Coffee'), findsOneWidget);
    });

    testWidgets('should format duration correctly', (tester) async {
      const testTask = TaskModel(
        id: 'test',
        name: 'Test Task',
        estimatedDuration: 125, // 2 minutes 5 seconds
        order: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const TaskDrawer(upcomingTasks: [testTask], isExpanded: false),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should format as "2m 5s"
      expect(find.text('2m 5s'), findsOneWidget);
    });

    testWidgets('should show task order indicators in collapsed state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TaskDrawer(
                  upcomingTasks: mockTasks.take(2).toList(),
                  isExpanded: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Next 1" and "Next 2" indicators
      expect(find.text('Next 1'), findsOneWidget);
      expect(find.text('Next 2'), findsOneWidget);
    });

    testWidgets('should show numbered indicators in expanded state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TaskDrawer(
                  upcomingTasks: mockTasks.take(2).toList(),
                  isExpanded: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show numbered circles
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should have horizontal scroll in collapsed state', (
      tester,
    ) async {
      // Create more tasks to ensure scrolling is needed
      final manyTasks = List.generate(
        5,
        (index) => TaskModel(
          id: 'task_$index',
          name: 'Task ${index + 1}',
          estimatedDuration: 300,
          order: index,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TaskDrawer(upcomingTasks: manyTasks, isExpanded: false),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find SingleChildScrollView with horizontal scroll
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.scrollDirection, Axis.horizontal);
    });

    testWidgets('should have vertical scroll in expanded state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TaskDrawer(upcomingTasks: mockTasks, isExpanded: true),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find ListView for vertical scrolling
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
