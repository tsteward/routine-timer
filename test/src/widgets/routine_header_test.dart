import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/widgets/routine_header.dart';
import 'package:routine_timer/src/models/schedule_status.dart';

void main() {
  group('RoutineHeader', () {
    late ScheduleStatus mockScheduleStatus;
    late bool settingsTapped;

    setUp(() {
      settingsTapped = false;
      mockScheduleStatus = ScheduleStatus(
        type: ScheduleStatusType.onTrack,
        minutesDifference: 0,
        estimatedCompletionTime: DateTime(2025, 1, 1, 12, 30),
        totalExpectedDuration: 3600,
        totalActualDuration: 1800,
        totalRemainingDuration: 1800,
      );
    });

    Widget createTestWidget(ScheduleStatus status) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.green,
          body: RoutineHeader(
            scheduleStatus: status,
            onSettingsTap: () {
              settingsTapped = true;
            },
          ),
        ),
      );
    }

    testWidgets('should display on track status correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(mockScheduleStatus));

      expect(find.text('On track'), findsOneWidget);
      expect(find.text('Est. Completion: 12:30 PM'), findsOneWidget);
      expect(find.byIcon(Icons.track_changes), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should display ahead status correctly', (tester) async {
      final aheadStatus = mockScheduleStatus.copyWith(
        type: ScheduleStatusType.ahead,
        minutesDifference: 5,
      );

      await tester.pumpWidget(createTestWidget(aheadStatus));

      expect(find.text('Ahead by 5 min'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('should display behind status correctly', (tester) async {
      final behindStatus = mockScheduleStatus.copyWith(
        type: ScheduleStatusType.behind,
        minutesDifference: 3,
      );

      await tester.pumpWidget(createTestWidget(behindStatus));

      expect(find.text('Behind by 3 min'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('should handle singular minute correctly', (tester) async {
      final aheadOneMinute = mockScheduleStatus.copyWith(
        type: ScheduleStatusType.ahead,
        minutesDifference: 1,
      );

      await tester.pumpWidget(createTestWidget(aheadOneMinute));

      expect(find.text('Ahead by 1 min'), findsOneWidget);
    });

    testWidgets('should handle singular minute for behind status', (
      tester,
    ) async {
      final behindOneMinute = mockScheduleStatus.copyWith(
        type: ScheduleStatusType.behind,
        minutesDifference: 1,
      );

      await tester.pumpWidget(createTestWidget(behindOneMinute));

      expect(find.text('Behind by 1 min'), findsOneWidget);
    });

    testWidgets('should format AM/PM time correctly', (tester) async {
      final morningStatus = mockScheduleStatus.copyWith(
        estimatedCompletionTime: DateTime(2025, 1, 1, 9, 15),
      );

      await tester.pumpWidget(createTestWidget(morningStatus));

      expect(find.text('Est. Completion: 9:15 AM'), findsOneWidget);
    });

    testWidgets('should format PM time correctly', (tester) async {
      final eveningStatus = mockScheduleStatus.copyWith(
        estimatedCompletionTime: DateTime(2025, 1, 1, 18, 45),
      );

      await tester.pumpWidget(createTestWidget(eveningStatus));

      expect(find.text('Est. Completion: 6:45 PM'), findsOneWidget);
    });

    testWidgets('should handle noon correctly', (tester) async {
      final noonStatus = mockScheduleStatus.copyWith(
        estimatedCompletionTime: DateTime(2025, 1, 1, 12, 0),
      );

      await tester.pumpWidget(createTestWidget(noonStatus));

      expect(find.text('Est. Completion: 12:00 PM'), findsOneWidget);
    });

    testWidgets('should handle midnight correctly', (tester) async {
      final midnightStatus = mockScheduleStatus.copyWith(
        estimatedCompletionTime: DateTime(2025, 1, 1, 0, 0),
      );

      await tester.pumpWidget(createTestWidget(midnightStatus));

      expect(find.text('Est. Completion: 12:00 AM'), findsOneWidget);
    });

    testWidgets('should call onSettingsTap when settings icon is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(mockScheduleStatus));

      expect(settingsTapped, isFalse);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(settingsTapped, isTrue);
    });

    testWidgets('should have proper styling and layout', (tester) async {
      await tester.pumpWidget(createTestWidget(mockScheduleStatus));

      // Check that the header has proper padding
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(
        container.padding,
        equals(const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
      );

      // Check that status card has proper styling
      final statusCard = tester.widget<Container>(find.byType(Container).at(1));
      expect(statusCard.decoration, isA<BoxDecoration>());

      final decoration = statusCard.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white.withValues(alpha: 0.2)));
      expect(decoration.borderRadius, equals(BorderRadius.circular(12)));
    });

    testWidgets('should display settings tooltip', (tester) async {
      await tester.pumpWidget(createTestWidget(mockScheduleStatus));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Settings'));
    });

    group('status card styling', () {
      testWidgets('should display status icon and text in same row', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget(mockScheduleStatus));

        // Find the row containing the icon and text
        final rows = find.byType(Row);
        expect(rows, findsAtLeastNWidgets(1));

        // Check that icon and status text are in the same row
        final statusRow = tester.widget<Row>(rows.first);
        expect(
          statusRow.children.length,
          equals(3),
        ); // Icon + SizedBox + Flexible(Text)
      });

      testWidgets('should display completion time below status', (
        tester,
      ) async {
        await tester.pumpWidget(createTestWidget(mockScheduleStatus));

        // Find the column containing status and completion time
        final column = find.byType(Column).last;
        final columnWidget = tester.widget<Column>(column);

        expect(
          columnWidget.children.length,
          equals(3),
        ); // Row + SizedBox + Text
        expect(
          columnWidget.crossAxisAlignment,
          equals(CrossAxisAlignment.start),
        );
        expect(columnWidget.mainAxisSize, equals(MainAxisSize.min));
      });
    });
  });
}
