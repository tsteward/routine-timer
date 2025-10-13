import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/widgets/break_card.dart';

void main() {
  group('BreakCard', () {
    testWidgets('displays break icon and duration', (tester) async {
      const breakModel = BreakModel(
        duration: 120,
        isEnabled: true,
      ); // 2 minutes

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      // Should display the coffee icon
      expect(find.byIcon(Icons.coffee), findsOneWidget);

      // Should display "Break" text
      expect(find.text('Break'), findsOneWidget);

      // Should display formatted duration (2:00)
      expect(find.text('2:00'), findsOneWidget);
    });

    testWidgets('uses correct width when specified', (tester) async {
      const breakModel = BreakModel(duration: 60, isEnabled: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel, width: 200)),
        ),
      );

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(Padding),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.constraints?.maxWidth, 200);
    });

    testWidgets('displays correctly for short break durations', (tester) async {
      const breakModel = BreakModel(
        duration: 30,
        isEnabled: true,
      ); // 30 seconds

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      expect(find.text('Break'), findsOneWidget);
      expect(find.byIcon(Icons.coffee), findsOneWidget);
      // Duration should be formatted as 0:30
      expect(find.text('0:30'), findsOneWidget);
    });

    testWidgets('displays correctly for long break durations', (tester) async {
      const breakModel = BreakModel(
        duration: 600,
        isEnabled: true,
      ); // 10 minutes

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      expect(find.text('Break'), findsOneWidget);
      expect(find.byIcon(Icons.coffee), findsOneWidget);
      // Duration should be formatted as 10:00
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('displays even when break is disabled', (tester) async {
      // Card should still render even if break is disabled
      // (This tests that isEnabled doesn't affect rendering)
      const breakModel = BreakModel(duration: 120, isEnabled: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      expect(find.byIcon(Icons.coffee), findsOneWidget);
      expect(find.text('Break'), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
    });

    testWidgets('uses theme colors correctly', (tester) async {
      const breakModel = BreakModel(duration: 120, isEnabled: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      // Should render without errors and use theme colors
      expect(find.byType(BreakCard), findsOneWidget);
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });
  });
}
