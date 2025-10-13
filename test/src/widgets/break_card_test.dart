import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/widgets/break_card.dart';

void main() {
  group('BreakCard', () {
    testWidgets('displays break icon and text', (tester) async {
      const breakModel = BreakModel(duration: 300, isEnabled: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      // Verify break icon is present
      expect(find.byIcon(Icons.coffee), findsOneWidget);

      // Verify "Break" text is present
      expect(find.text('Break'), findsOneWidget);
    });

    testWidgets('displays formatted duration', (tester) async {
      const breakModel = BreakModel(
        duration: 300,
        isEnabled: true,
      ); // 5 minutes

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      // Verify duration is formatted and displayed
      expect(find.text('5m'), findsOneWidget);
    });

    testWidgets('respects custom width', (tester) async {
      const breakModel = BreakModel(duration: 120, isEnabled: true);
      const customWidth = 200.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreakCard(breakModel: breakModel, width: customWidth),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);

      expect(container.constraints?.maxWidth, customWidth);
    });

    testWidgets('displays different durations correctly', (tester) async {
      // Test 1 minute
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreakCard(breakModel: const BreakModel(duration: 60)),
          ),
        ),
      );
      expect(find.text('1m'), findsOneWidget);

      // Test 2 minutes
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreakCard(breakModel: const BreakModel(duration: 120)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2m'), findsOneWidget);

      // Test 1 hour 30 minutes
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreakCard(breakModel: const BreakModel(duration: 5400)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1h 30m'), findsOneWidget);
    });

    testWidgets('applies secondary container color scheme', (tester) async {
      const breakModel = BreakModel(duration: 180, isEnabled: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(body: BreakCard(breakModel: breakModel)),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(BreakCard),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });
  });
}
