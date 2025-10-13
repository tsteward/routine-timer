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
      // Verify text fields exist
      expect(find.byType(TextField), findsNWidgets(2));
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

      // Verify the text fields show the correct initial values
      final hoursField = find.byType(TextField).first;
      final minutesField = find.byType(TextField).last;

      expect(
        (tester.widget(hoursField) as TextField).controller?.text,
        equals('1'),
      );
      expect(
        (tester.widget(minutesField) as TextField).controller?.text,
        equals('30'),
      );
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

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 1 hour (3600s) + 30 minutes (1800s) = 5400s
      expect(result, equals(5400));
    });

    testWidgets('up arrow increments hours', (tester) async {
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

      // Find the up arrow for hours (first up arrow)
      final upArrows = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upArrows.first);
      await tester.pumpAndSettle();

      final hoursField = find.byType(TextField).first;
      expect(
        (tester.widget(hoursField) as TextField).controller?.text,
        equals('2'),
      );
    });

    testWidgets('down arrow decrements hours', (tester) async {
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

      // Find the down arrow for hours (first down arrow)
      final downArrows = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downArrows.first);
      await tester.pumpAndSettle();

      final hoursField = find.byType(TextField).first;
      expect(
        (tester.widget(hoursField) as TextField).controller?.text,
        equals('1'),
      );
    });

    testWidgets('up arrow increments minutes', (tester) async {
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

      // Find the up arrow for minutes (second up arrow)
      final upArrows = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upArrows.last);
      await tester.pumpAndSettle();

      final minutesField = find.byType(TextField).last;
      expect(
        (tester.widget(minutesField) as TextField).controller?.text,
        equals('16'),
      );
    });

    testWidgets('down arrow decrements minutes', (tester) async {
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
                      initialMinutes: 20,
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

      // Find the down arrow for minutes (second down arrow)
      final downArrows = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downArrows.last);
      await tester.pumpAndSettle();

      final minutesField = find.byType(TextField).last;
      expect(
        (tester.widget(minutesField) as TextField).controller?.text,
        equals('19'),
      );
    });

    testWidgets('hours clamp at 23 maximum', (tester) async {
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

      // Try to increment beyond max
      final upArrows = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upArrows.first);
      await tester.pumpAndSettle();

      final hoursField = find.byType(TextField).first;
      expect(
        (tester.widget(hoursField) as TextField).controller?.text,
        equals('23'), // Should remain at 23
      );
    });

    testWidgets('hours clamp at 0 minimum', (tester) async {
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

      // Try to decrement below min
      final downArrows = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downArrows.first);
      await tester.pumpAndSettle();

      final hoursField = find.byType(TextField).first;
      expect(
        (tester.widget(hoursField) as TextField).controller?.text,
        equals('0'), // Should remain at 0
      );
    });

    testWidgets('minutes clamp at 59 maximum', (tester) async {
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

      // Try to increment beyond max
      final upArrows = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upArrows.last);
      await tester.pumpAndSettle();

      final minutesField = find.byType(TextField).last;
      expect(
        (tester.widget(minutesField) as TextField).controller?.text,
        equals('59'), // Should remain at 59
      );
    });

    testWidgets('minutes clamp at 0 minimum', (tester) async {
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

      // Try to decrement below min
      final downArrows = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downArrows.last);
      await tester.pumpAndSettle();

      final minutesField = find.byType(TextField).last;
      expect(
        (tester.widget(minutesField) as TextField).controller?.text,
        equals('0'), // Should remain at 0
      );
    });

    testWidgets('can type directly into hours field', (tester) async {
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

      final hoursField = find.byType(TextField).first;
      await tester.enterText(hoursField, '5');
      await tester.pumpAndSettle();

      expect(
        (tester.widget(hoursField) as TextField).controller?.text,
        equals('5'),
      );
    });

    testWidgets('can type directly into minutes field', (tester) async {
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

      final minutesField = find.byType(TextField).last;
      await tester.enterText(minutesField, '45');
      await tester.pumpAndSettle();

      expect(
        (tester.widget(minutesField) as TextField).controller?.text,
        equals('45'),
      );
    });

    testWidgets('hours field rejects invalid input greater than max', (
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
                      initialHours: 5,
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

      final hoursField = find.byType(TextField).first;

      // Try to enter a value greater than 23
      await tester.enterText(hoursField, '25');
      await tester.pumpAndSettle();

      // Should be rejected and stay at previous value
      expect(
        (tester.widget(hoursField) as TextField).controller?.text,
        equals('5'),
      );
    });

    testWidgets('minutes field rejects invalid input greater than max', (
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

      final minutesField = find.byType(TextField).last;

      // Try to enter a value greater than 59
      await tester.enterText(minutesField, '65');
      await tester.pumpAndSettle();

      // Should be rejected and stay at previous value
      expect(
        (tester.widget(minutesField) as TextField).controller?.text,
        equals('30'),
      );
    });

    testWidgets('fields only accept numeric input', (tester) async {
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

      final hoursField = find.byType(TextField).first;
      final minutesField = find.byType(TextField).last;

      // Try to enter non-numeric characters - they should be filtered out
      await tester.enterText(hoursField, 'abc');
      await tester.pumpAndSettle();

      // Non-numeric characters are filtered out, leaving empty string
      expect(
        (tester.widget(hoursField) as TextField).controller?.text,
        equals(''),
      );

      // Enter a mix of letters and numbers - only numbers should remain
      await tester.enterText(minutesField, 'a5b');
      await tester.pumpAndSettle();

      expect(
        (tester.widget(minutesField) as TextField).controller?.text,
        equals('5'),
      );
    });

    testWidgets('typed values are used when OK is pressed', (tester) async {
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

      // Type new values
      final hoursField = find.byType(TextField).first;
      final minutesField = find.byType(TextField).last;

      await tester.enterText(hoursField, '2');
      await tester.pumpAndSettle();

      await tester.enterText(minutesField, '45');
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 2 hours (7200s) + 45 minutes (2700s) = 9900s
      expect(result, equals(9900));
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

      final hoursField = find.byType(TextField).first;

      // Clear the hours field
      await tester.enterText(hoursField, '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Empty hours defaults to 0, so 0 hours + 0 minutes = 0s
      expect(result, equals(0));
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

      final minutesField = find.byType(TextField).last;

      // Clear the minutes field
      await tester.enterText(minutesField, '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 1 hour (3600s) + empty minutes (defaults to 0) = 3600s
      expect(result, equals(3600));
    });

    testWidgets('show() static method returns dialog result', (tester) async {
      int? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DurationPickerDialog.show(
                    context: context,
                    initialHours: 2,
                    initialMinutes: 15,
                    title: 'Test Duration',
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

      expect(find.text('Test Duration'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 2 hours (7200s) + 15 minutes (900s) = 8100s
      expect(result, equals(8100));
    });
  });
}
