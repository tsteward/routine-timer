import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/widgets/start_time_pill.dart';

void main() {
  group('StartTimePill', () {
    testWidgets('displays text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StartTimePill(text: '08:30')),
        ),
      );

      expect(find.text('08:30'), findsOneWidget);
    });

    testWidgets('displays time with leading zeros', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StartTimePill(text: '09:05')),
        ),
      );

      expect(find.text('09:05'), findsOneWidget);
    });

    testWidgets('has correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StartTimePill(text: '12:00')),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('12:00'), matching: find.byType(Container)),
      );

      expect(container.decoration, isA<BoxDecoration>());
    });
  });
}
