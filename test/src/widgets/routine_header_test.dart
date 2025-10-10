import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/widgets/routine_header.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
  group('RoutineHeader', () {
    late RoutineStateModel testModel;
    late DateTime testStartTime;

    setUp(() {
      testStartTime = DateTime(2025, 1, 1, 6, 0, 0); // 6:00 AM

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 900, // 15 minutes
          order: 1,
        ),
      ];

      final breaks = [
        const BreakModel(duration: 120, isEnabled: true), // 2 minutes
      ];

      final settings = RoutineSettingsModel(
        startTime: testStartTime.millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      testModel = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
        isRunning: true,
      );
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(body: child),
        onGenerateRoute: (settings) {
          // Simple route generator for tests
          switch (settings.name) {
            case '/tasks':
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Task Management')),
                ),
              );
            default:
              return MaterialPageRoute(
                builder: (_) =>
                    const Scaffold(body: Center(child: Text('Unknown Route'))),
              );
          }
        },
      );
    }

    testWidgets('should render without crashing', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RoutineHeader(
            model: testModel,
            routineStartTime: testStartTime,
            currentTaskElapsedSeconds: 120, // 2 minutes
          ),
        ),
      );

      // Should find the basic structure
      expect(find.byType(RoutineHeader), findsOneWidget);

      // Should find the settings button
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should display settings button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RoutineHeader(
            model: testModel,
            routineStartTime: testStartTime,
            currentTaskElapsedSeconds: 120,
          ),
        ),
      );

      // Should find settings icon
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);

      // Should be tappable
      await tester.tap(settingsButton);
      await tester.pump();
    });

    testWidgets('should display completion time text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RoutineHeader(
            model: testModel,
            routineStartTime: testStartTime,
            currentTaskElapsedSeconds: 0,
          ),
        ),
      );

      // Should display estimated completion label
      expect(find.textContaining('Est. Completion:'), findsOneWidget);
    });

    testWidgets('should handle empty model gracefully', (tester) async {
      final emptyModel = testModel.copyWith(tasks: [], breaks: []);

      await tester.pumpWidget(
        createTestWidget(
          RoutineHeader(
            model: emptyModel,
            routineStartTime: testStartTime,
            currentTaskElapsedSeconds: 0,
          ),
        ),
      );

      // Should not crash and should display basic structure
      expect(find.byType(RoutineHeader), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should have proper container structure', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RoutineHeader(
            model: testModel,
            routineStartTime: testStartTime,
            currentTaskElapsedSeconds: 60,
          ),
        ),
      );

      // Should have main container
      expect(find.byType(Container), findsWidgets);

      // Should have at least one row layout (may have multiple rows in the structure)
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('should display some form of schedule status', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          RoutineHeader(
            model: testModel,
            routineStartTime: testStartTime,
            currentTaskElapsedSeconds: 120,
          ),
        ),
      );

      // Should display some status icon (one of the possible status icons)
      final statusIcons = [
        Icons.trending_up,
        Icons.trending_down,
        Icons.track_changes,
      ];
      bool foundStatusIcon = false;

      for (final icon in statusIcons) {
        if (find.byIcon(icon).evaluate().isNotEmpty) {
          foundStatusIcon = true;
          break;
        }
      }

      expect(
        foundStatusIcon,
        isTrue,
        reason: 'Should display at least one status icon',
      );
    });
  });
}
