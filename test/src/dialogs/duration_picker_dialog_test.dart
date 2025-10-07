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

    testWidgets('OK button returns selected duration in seconds', (
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

      // 1 hour 30 minutes = 5400 seconds
      expect(result, 5400);
    });

    testWidgets('can increment hours', (tester) async {
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

      // Find and tap the up arrow for hours
      final upArrows = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upArrows.first);
      await tester.pumpAndSettle();

      // Hours should now be 02
      expect(find.text('02'), findsOneWidget);
    });

    testWidgets('can decrement hours', (tester) async {
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

      // Find and tap the down arrow for hours
      final downArrows = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downArrows.first);
      await tester.pumpAndSettle();

      // Hours should now be 01
      expect(find.text('01'), findsOneWidget);
    });

    testWidgets('can increment minutes', (tester) async {
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

      // Find and tap the up arrow for minutes
      final upArrows = find.byIcon(Icons.arrow_drop_up);
      await tester.tap(upArrows.last);
      await tester.pumpAndSettle();

      // Minutes should now be 31
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('can decrement minutes', (tester) async {
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

      // Find and tap the down arrow for minutes
      final downArrows = find.byIcon(Icons.arrow_drop_down);
      await tester.tap(downArrows.last);
      await tester.pumpAndSettle();

      // Minutes should now be 29
      expect(find.text('29'), findsOneWidget);
    });

    testWidgets('static show method works correctly', (tester) async {
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
                    initialMinutes: 45,
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
      expect(find.text('02'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 2 hours 45 minutes = 9900 seconds
      expect(result, 9900);
    });
  });
}
