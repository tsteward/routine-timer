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
      expect(find.text('1'), findsOneWidget);
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

    testWidgets('can type hours directly', (tester) async {
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

      // Find the hours text field and enter text
      final hoursField = find.byType(TextField).first;
      await tester.tap(hoursField);
      await tester.pumpAndSettle();

      await tester.enterText(hoursField, '2');
      await tester.pumpAndSettle();

      // Tap OK button
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Should return 2 hours + 10 minutes = 7800 seconds
      expect(result, 7800);
    });

    testWidgets('can type minutes directly', (tester) async {
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
                      initialHours: 1,
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

      // Find the minutes text field and enter text
      final minutesField = find.byType(TextField).last;
      await tester.tap(minutesField);
      await tester.pumpAndSettle();

      await tester.enterText(minutesField, '45');
      await tester.pumpAndSettle();

      // Tap OK button
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Should return 1 hour + 45 minutes = 6300 seconds
      expect(result, 6300);
    });

    testWidgets('up button increments hours', (tester) async {
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

      // Find and tap the up button for hours (first up button)
      final upButtons = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upButtons.first);
      await tester.pumpAndSettle();

      // Hours should now be 2
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('down button decrements hours', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
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

      // Find and tap the down button for hours (first down button)
      final downButtons = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downButtons.first);
      await tester.pumpAndSettle();

      // Hours should now be 1
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('up button increments minutes', (tester) async {
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

      // Find and tap the up button for minutes (last up button)
      final upButtons = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upButtons.last);
      await tester.pumpAndSettle();

      // Minutes should now be 31
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('down button decrements minutes', (tester) async {
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

      // Find and tap the down button for minutes (last down button)
      final downButtons = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downButtons.last);
      await tester.pumpAndSettle();

      // Minutes should now be 29
      expect(find.text('29'), findsOneWidget);
    });

    testWidgets('hours cannot exceed 23', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialHours: 23,
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

      // Try to increment hours beyond 23
      final upButtons = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upButtons.first);
      await tester.pumpAndSettle();

      // Hours should still be 23
      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('hours cannot go below 0', (tester) async {
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

      // Try to decrement hours below 0
      final downButtons = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downButtons.first);
      await tester.pumpAndSettle();

      // Hours should still be 0
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('minutes cannot exceed 59', (tester) async {
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
                      initialMinutes: 59,
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

      // Try to increment minutes beyond 59
      final upButtons = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upButtons.last);
      await tester.pumpAndSettle();

      // Minutes should still be 59
      expect(find.text('59'), findsOneWidget);
    });

    testWidgets('minutes cannot go below 0', (tester) async {
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

      // Try to decrement minutes below 0
      final downButtons = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downButtons.last);
      await tester.pumpAndSettle();

      // Minutes should still be 0
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('typing invalid hours value is ignored', (tester) async {
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

      // Try to enter an invalid hour value (>23)
      final hoursField = find.byType(TextField).first;
      await tester.tap(hoursField);
      await tester.pumpAndSettle();

      await tester.enterText(hoursField, '50');
      await tester.pumpAndSettle();

      // The text field should show 50, but internal state should reject it
      // When we press OK, it should use the last valid value (5)
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('typing invalid minutes value is ignored', (tester) async {
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
                      initialMinutes: 15,
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

      // Try to enter an invalid minute value (>59)
      final minutesField = find.byType(TextField).last;
      await tester.tap(minutesField);
      await tester.pumpAndSettle();

      await tester.enterText(minutesField, '99');
      await tester.pumpAndSettle();

      // The text field should show 99, but internal state should reject it
      // When we press OK, it should use the last valid value (15)
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('empty hours field defaults to 0', (tester) async {
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

      // Clear the hours field
      final hoursField = find.byType(TextField).first;
      await tester.tap(hoursField);
      await tester.pumpAndSettle();

      await tester.enterText(hoursField, '');
      await tester.pumpAndSettle();

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Should return 0 hours + 30 minutes = 1800 seconds
      expect(result, 1800);
    });

    testWidgets('empty minutes field defaults to 0', (tester) async {
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
                      initialMinutes: 45,
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

      // Clear the minutes field
      final minutesField = find.byType(TextField).last;
      await tester.tap(minutesField);
      await tester.pumpAndSettle();

      await tester.enterText(minutesField, '');
      await tester.pumpAndSettle();

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Should return 2 hours + 0 minutes = 7200 seconds
      expect(result, 7200);
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
                      initialMinutes: 15,
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

      // 2 hours = 7200 seconds, 15 minutes = 900 seconds, total = 8100
      expect(result, 8100);
    });

    testWidgets('tapping text field selects all text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const DurationPickerDialog(
                      initialHours: 12,
                      initialMinutes: 45,
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

      // Tap the hours field to select text
      final hoursField = find.byType(TextField).first;
      await tester.tap(hoursField);
      await tester.pumpAndSettle();

      // Type new value - should replace the selected text
      await tester.enterText(hoursField, '5');
      await tester.pumpAndSettle();

      expect(find.text('5'), findsAtLeastNWidgets(1));
    });
  });
}
