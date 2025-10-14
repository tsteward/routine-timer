import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/dialogs/duration_picker_dialog.dart';

void main() {
  group('DurationPickerDialog', () {
    testWidgets('displays dialog with hour and minute pickers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialHours: 0,
                      initialMinutes: 10,
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
      expect(find.text('hours'), findsOneWidget);
      expect(find.text('minutes'), findsOneWidget);
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
                      initialHours: 1,
                      initialMinutes: 30,
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
                      initialHours: 0,
                      initialMinutes: 10,
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

    testWidgets('allows typing hours directly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialHours: 0,
                      initialMinutes: 0,
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

      // Find the hours TextField
      final hoursField = find.ancestor(
        of: find.text('00').first,
        matching: find.byType(TextField),
      );

      // Tap to focus and enter text
      await tester.tap(hoursField);
      await tester.pumpAndSettle();

      await tester.enterText(hoursField, '05');
      await tester.pumpAndSettle();

      // Verify the value updated
      expect(find.text('05'), findsWidgets);
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
                      initialHours: 0,
                      initialMinutes: 0,
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

      // Find the minutes TextField (it's the second '00' text)
      final minutesField = find.ancestor(
        of: find.text('00').last,
        matching: find.byType(TextField),
      );

      // Tap to focus and enter text
      await tester.tap(minutesField);
      await tester.pumpAndSettle();

      await tester.enterText(minutesField, '45');
      await tester.pumpAndSettle();

      // Verify the value updated
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('clamps hours to valid range (0-23)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialHours: 22,
                      initialMinutes: 0,
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

      // Try to increment beyond 23
      final upArrow = find.byIcon(Icons.arrow_drop_up).first;
      await tester.tap(upArrow);
      await tester.pumpAndSettle();

      expect(find.text('23'), findsOneWidget);

      await tester.tap(upArrow);
      await tester.pumpAndSettle();

      // Should still be 23 (clamped)
      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('clamps minutes to valid range (0-59)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialHours: 0,
                      initialMinutes: 58,
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
                      initialHours: 5,
                      initialMinutes: 30,
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

      // Test hours increment
      final hoursUpArrow = find.byIcon(Icons.arrow_drop_up).first;
      await tester.tap(hoursUpArrow);
      await tester.pumpAndSettle();
      expect(find.text('06'), findsOneWidget);

      // Test hours decrement
      final hoursDownArrow = find.byIcon(Icons.arrow_drop_down).first;
      await tester.tap(hoursDownArrow);
      await tester.pumpAndSettle();
      expect(find.text('05'), findsOneWidget);

      // Test minutes increment
      final minutesUpArrow = find.byIcon(Icons.arrow_drop_up).last;
      await tester.tap(minutesUpArrow);
      await tester.pumpAndSettle();
      expect(find.text('31'), findsOneWidget);

      // Test minutes decrement
      final minutesDownArrow = find.byIcon(Icons.arrow_drop_down).last;
      await tester.tap(minutesDownArrow);
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
                      initialHours: 2,
                      initialMinutes: 30,
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

      // 2 hours * 3600 + 30 minutes * 60 = 7200 + 1800 = 9000 seconds
      expect(result, equals(9000));
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
                      initialHours: 0,
                      initialMinutes: 0,
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

      // Enter an invalid hour value (>23)
      final hoursField = find.ancestor(
        of: find.text('00').first,
        matching: find.byType(TextField),
      );

      await tester.tap(hoursField);
      await tester.pumpAndSettle();

      await tester.enterText(hoursField, '99');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should be clamped to 23
      expect(find.text('23'), findsOneWidget);
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
                      initialHours: 5,
                      initialMinutes: 30,
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

      // Tap the hours field
      final hoursField = find.ancestor(
        of: find.text('05'),
        matching: find.byType(TextField),
      );

      await tester.tap(hoursField);
      await tester.pumpAndSettle();

      // Enter new value - should replace the selected text
      await tester.enterText(hoursField, '12');
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
    });
  });
}
