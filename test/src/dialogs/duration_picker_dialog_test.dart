import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/dialogs/duration_picker_dialog.dart';

void main() {
  group('DurationPickerDialog', () {
    testWidgets('displays dialog with minute and second pickers', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 0,
                      initialSeconds: 10,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Task Duration'), findsOneWidget);
      expect(find.text('minutes'), findsOneWidget);
      expect(find.text('seconds'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('displays initial duration values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 1,
                      initialSeconds: 30,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify the pickers show the correct initial values
      expect(find.text('01'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 0,
                      initialSeconds: 10,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(DurationPickerDialog), findsNothing);
    });

    testWidgets('allows typing minutes directly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 0,
                      initialSeconds: 0,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the minutes TextField
      final minutesField = find.ancestor(
        of: find.text('00').first,
        matching: find.byType(TextField),
      );

      // Tap to focus and enter text
      await tester.tap(minutesField);
      await tester.pumpAndSettle();

      await tester.enterText(minutesField, '05');
      await tester.pumpAndSettle();

      // Verify the value updated
      expect(find.text('05'), findsWidgets);
    });

    testWidgets('allows typing seconds directly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 0,
                      initialSeconds: 0,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the seconds TextField (it's the second '00' text)
      final secondsField = find.ancestor(
        of: find.text('00').last,
        matching: find.byType(TextField),
      );

      // Tap to focus and enter text
      await tester.tap(secondsField);
      await tester.pumpAndSettle();

      await tester.enterText(secondsField, '45');
      await tester.pumpAndSettle();

      // Verify the value updated
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('clamps minutes to valid range (0-999)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 998,
                      initialSeconds: 0,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to increment beyond 999
      final upArrow = find.byIcon(Icons.arrow_drop_up).first;
      await tester.tap(upArrow);
      await tester.pumpAndSettle();

      expect(find.text('999'), findsOneWidget);

      await tester.tap(upArrow);
      await tester.pumpAndSettle();

      // Should still be 999 (clamped)
      expect(find.text('999'), findsOneWidget);
    });

    testWidgets('clamps seconds to valid range (0-59)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 0,
                      initialSeconds: 58,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to increment beyond 59
      final upArrow = find.byIcon(Icons.arrow_drop_up).last;
      await tester.tap(upArrow);
      await tester.pumpAndSettle();

      expect(find.text('59'), findsOneWidget);

      await tester.tap(upArrow);
      await tester.pumpAndSettle();

      // Should still be 59 (clamped)
      expect(find.text('59'), findsOneWidget);
    });

    testWidgets('increment/decrement buttons work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 5,
                      initialSeconds: 30,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Test minutes increment
      final minutesUpArrow = find.byIcon(Icons.arrow_drop_up).first;
      await tester.tap(minutesUpArrow);
      await tester.pumpAndSettle();
      expect(find.text('06'), findsOneWidget);

      // Test minutes decrement
      final minutesDownArrow = find.byIcon(Icons.arrow_drop_down).first;
      await tester.tap(minutesDownArrow);
      await tester.pumpAndSettle();
      expect(find.text('05'), findsOneWidget);

      // Test seconds increment
      final secondsUpArrow = find.byIcon(Icons.arrow_drop_up).last;
      await tester.tap(secondsUpArrow);
      await tester.pumpAndSettle();
      expect(find.text('31'), findsOneWidget);

      // Test seconds decrement
      final secondsDownArrow = find.byIcon(Icons.arrow_drop_down).last;
      await tester.tap(secondsDownArrow);
      await tester.pumpAndSettle();
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('OK button returns correct duration in seconds', (
      tester,
    ) async {
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<int>(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 2,
                      initialSeconds: 30,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 2 minutes * 60 + 30 seconds = 120 + 30 = 150 seconds
      expect(result, equals(150));
    });

    testWidgets('validates typed input on submission', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 0,
                      initialSeconds: 0,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter an invalid minute value (>999)
      final minutesField = find.ancestor(
        of: find.text('00').first,
        matching: find.byType(TextField),
      );

      await tester.tap(minutesField);
      await tester.pumpAndSettle();

      await tester.enterText(minutesField, '9999');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should be clamped to 999
      expect(find.text('999'), findsOneWidget);
    });

    testWidgets('selects all text when tapping field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialMinutes: 5,
                      initialSeconds: 30,
                      title: 'Task Duration',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap the minutes field
      final minutesField = find.ancestor(
        of: find.text('05'),
        matching: find.byType(TextField),
      );

      await tester.tap(minutesField);
      await tester.pumpAndSettle();

      // Enter new value - should replace the selected text
      await tester.enterText(minutesField, '12');
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
    });
  });
}
