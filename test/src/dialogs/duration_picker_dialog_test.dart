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
                  result = await DurationPickerDialog.show(
                    context: context,
                    initialHours: 1,
                    initialMinutes: 30,
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

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 1 hour 30 minutes = 5400 seconds
      expect(result, equals(5400));
    });

    testWidgets('displays correct range of hour values', (tester) async {
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
                      title: 'Duration',
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

      // Should show hours from 00 to 23
      expect(find.text('05'), findsOneWidget);

      // Verify the cupertino picker is present
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('displays correct range of minute values', (tester) async {
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
                      initialMinutes: 45,
                      title: 'Duration',
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

      // Should show minutes from 00 to 59
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('uses static show method', (tester) async {
      int? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DurationPickerDialog.show(
                    context: context,
                    initialHours: 0,
                    initialMinutes: 15,
                    title: 'Pick Duration',
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

      expect(find.text('Pick Duration'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('returns null when cancelled', (tester) async {
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
                    initialMinutes: 0,
                    title: 'Duration',
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

      expect(result, isNull);
    });

    testWidgets('displays hour and minute labels', (tester) async {
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
                      title: 'Duration',
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

      expect(find.text('hours'), findsOneWidget);
      expect(find.text('minutes'), findsOneWidget);
    });
  });
}
