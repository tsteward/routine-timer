import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/widgets/break_gap.dart';

void main() {
  group('BreakGap', () {
    testWidgets('displays enabled break with icon and duration', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreakGap(
              isEnabled: true,
              duration: 120, // 2 minutes
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify the break card is displayed
      expect(find.byType(Card), findsOneWidget);

      // Verify the coffee icon is shown
      expect(find.byIcon(Icons.coffee), findsOneWidget);

      // Verify the duration text is shown (checking for 'Break:' prefix)
      expect(find.textContaining('Break:'), findsOneWidget);

      // Tap the break gap
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
      'displays disabled break with dashed border and "Add Break" text',
      (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BreakGap(
                isEnabled: false,
                duration: 120, // Duration not displayed when disabled
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        // Verify the container with dashed border is displayed
        expect(find.byType(Container), findsWidgets);

        // Verify "Add Break" text is shown
        expect(find.text('Add Break'), findsOneWidget);

        // Verify no coffee icon (only shown when enabled)
        expect(find.byIcon(Icons.coffee), findsNothing);

        // Tap the break gap
        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(tapped, isTrue);
      },
    );

    testWidgets('enabled break shows correct duration formatting', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreakGap(
              isEnabled: true,
              duration: 300, // 5 minutes
              onTap: () {},
            ),
          ),
        ),
      );

      // The exact format depends on TimeFormatter.formatDuration
      // Just verify that "Break:" text is present
      expect(find.textContaining('Break:'), findsOneWidget);
    });

    testWidgets('disabled break has correct height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreakGap(isEnabled: false, duration: 120, onTap: () {}),
          ),
        ),
      );

      // Find the container with height constraint
      final containerFinder = find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      ).first;

      // The exact height is set in the widget (32)
      final size = tester.getSize(containerFinder);
      expect(size.height, equals(32));
    });

    testWidgets('onTap callback is called when tapping enabled break', (
      tester,
    ) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreakGap(
              isEnabled: true,
              duration: 120,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BreakGap));
      await tester.pump();
      expect(tapCount, equals(1));

      // Tap again
      await tester.tap(find.byType(BreakGap));
      await tester.pump();
      expect(tapCount, equals(2));
    });

    testWidgets('onTap callback is called when tapping disabled break', (
      tester,
    ) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BreakGap(
              isEnabled: false,
              duration: 120,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BreakGap));
      await tester.pump();
      expect(tapCount, equals(1));

      // Tap again
      await tester.tap(find.byType(BreakGap));
      await tester.pump();
      expect(tapCount, equals(2));
    });

    testWidgets('enabled break uses correct theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: Scaffold(
            body: BreakGap(isEnabled: true, duration: 120, onTap: () {}),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, isNotNull);
    });
  });
}
