import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/widgets/break_card.dart';

void main() {
  group('BreakCard', () {
    testWidgets('displays break information correctly', (tester) async {
      const breakModel = BreakModel(
        duration: 120, // 2 minutes
        isEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      // Should display coffee icon
      expect(find.byIcon(Icons.coffee), findsOneWidget);

      // Should display "Break" text
      expect(find.text('Break'), findsOneWidget);

      // Should display formatted duration
      expect(find.text('2m'), findsOneWidget);
    });

    testWidgets('respects custom width', (tester) async {
      const breakModel = BreakModel(duration: 60, isEnabled: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel, width: 150)),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.coffee),
          matching: find.byType(Container),
        ),
      );

      expect(container.constraints?.maxWidth, 150);
    });

    testWidgets('displays different durations correctly', (tester) async {
      const breakModel = BreakModel(
        duration: 300, // 5 minutes
        isEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      // Should display formatted duration
      expect(find.text('5m'), findsOneWidget);
    });

    testWidgets('uses secondary container colors', (tester) async {
      const breakModel = BreakModel(duration: 120, isEnabled: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.coffee),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.border, isNotNull);
    });
  });
}
