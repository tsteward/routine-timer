import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/services/schedule_tracker.dart';
import 'package:routine_timer/src/widgets/schedule_status_card.dart';

void main() {
  group('ScheduleStatusCard', () {
    testWidgets('displays ahead status correctly', (tester) async {
      final completionTime = DateTime(2025, 1, 1, 8, 30);
      const scheduleStatus = ScheduleStatus(
        status: ScheduleStatusType.ahead,
        varianceSeconds: -120,
        estimatedCompletionTime: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleStatusCard(
              scheduleStatus: scheduleStatus.copyWith(
                estimatedCompletionTime: completionTime,
              ),
            ),
          ),
        ),
      );

      // Check for status text
      expect(find.text('Ahead by 2 min'), findsOneWidget);

      // Check for completion time
      expect(find.text('Est. Completion: 8:30 AM'), findsOneWidget);

      // Check for trending up icon
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('displays behind status correctly', (tester) async {
      final completionTime = DateTime(2025, 1, 1, 9, 15);
      const scheduleStatus = ScheduleStatus(
        status: ScheduleStatusType.behind,
        varianceSeconds: 90,
        estimatedCompletionTime: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleStatusCard(
              scheduleStatus: scheduleStatus.copyWith(
                estimatedCompletionTime: completionTime,
              ),
            ),
          ),
        ),
      );

      // Check for status text
      expect(find.text('Behind by 1 min 30 sec'), findsOneWidget);

      // Check for completion time
      expect(find.text('Est. Completion: 9:15 AM'), findsOneWidget);

      // Check for trending down icon
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('displays on track status correctly', (tester) async {
      final completionTime = DateTime(2025, 1, 1, 7, 45);
      const scheduleStatus = ScheduleStatus(
        status: ScheduleStatusType.onTrack,
        varianceSeconds: 10,
        estimatedCompletionTime: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleStatusCard(
              scheduleStatus: scheduleStatus.copyWith(
                estimatedCompletionTime: completionTime,
              ),
            ),
          ),
        ),
      );

      // Check for status text
      expect(find.text('On Track'), findsOneWidget);

      // Check for completion time
      expect(find.text('Est. Completion: 7:45 AM'), findsOneWidget);

      // Check for check circle icon
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('displays PM times correctly', (tester) async {
      final completionTime = DateTime(2025, 1, 1, 14, 30);
      const scheduleStatus = ScheduleStatus(
        status: ScheduleStatusType.onTrack,
        varianceSeconds: 0,
        estimatedCompletionTime: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleStatusCard(
              scheduleStatus: scheduleStatus.copyWith(
                estimatedCompletionTime: completionTime,
              ),
            ),
          ),
        ),
      );

      // Check for PM completion time
      expect(find.text('Est. Completion: 2:30 PM'), findsOneWidget);
    });

    testWidgets('applies correct color for ahead status', (tester) async {
      const scheduleStatus = ScheduleStatus(
        status: ScheduleStatusType.ahead,
        varianceSeconds: -60,
        estimatedCompletionTime: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleStatusCard(scheduleStatus: scheduleStatus),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ScheduleStatusCard),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.green.withValues(alpha: 0.2));
    });

    testWidgets('applies correct color for behind status', (tester) async {
      const scheduleStatus = ScheduleStatus(
        status: ScheduleStatusType.behind,
        varianceSeconds: 60,
        estimatedCompletionTime: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleStatusCard(scheduleStatus: scheduleStatus),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ScheduleStatusCard),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.red.withValues(alpha: 0.2));
    });

    testWidgets('applies correct color for on track status', (tester) async {
      const scheduleStatus = ScheduleStatus(
        status: ScheduleStatusType.onTrack,
        varianceSeconds: 0,
        estimatedCompletionTime: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScheduleStatusCard(scheduleStatus: scheduleStatus),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ScheduleStatusCard),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.blue.withValues(alpha: 0.2));
    });
  });
}

// Extension to help with testing
extension ScheduleStatusCopyWith on ScheduleStatus {
  ScheduleStatus copyWith({
    ScheduleStatusType? status,
    int? varianceSeconds,
    DateTime? estimatedCompletionTime,
  }) {
    return ScheduleStatus(
      status: status ?? this.status,
      varianceSeconds: varianceSeconds ?? this.varianceSeconds,
      estimatedCompletionTime:
          estimatedCompletionTime ?? this.estimatedCompletionTime,
    );
  }
}
