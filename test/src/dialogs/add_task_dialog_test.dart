import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/dialogs/add_task_dialog.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';

void main() {
  group('AddTaskDialog', () {
    testWidgets('displays dialog with input fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AddTaskDialog(),
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

      expect(find.text('Add New Task'), findsOneWidget);
      expect(find.text('Task Name'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('validates empty task name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AddTaskDialog(),
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

      // Try to add without entering a name
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a task name'), findsOneWidget);
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
                    builder: (ctx) => const AddTaskDialog(),
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

      expect(find.byType(AddTaskDialog), findsNothing);
    });

    testWidgets('adds task successfully with valid inputs', (tester) async {
      final bloc = RoutineBloc();
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => BlocProvider.value(
                        value: bloc,
                        child: const AddTaskDialog(),
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter task name
      await tester.enterText(
        find.widgetWithText(TextFormField, ''),
        'New Task',
      );
      await tester.pumpAndSettle();

      // The default duration is 10 minutes (displayed as "10m")
      expect(find.text('10m'), findsOneWidget);

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.byType(AddTaskDialog), findsNothing);

      bloc.close();
    });

    testWidgets('opens duration picker dialog when tapping duration field', (
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
                    builder: (ctx) => const AddTaskDialog(),
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

      // Tap on duration field
      await tester.tap(find.text('10m'));
      await tester.pumpAndSettle();

      // Duration picker dialog should open
      expect(find.text('Task Duration'), findsOneWidget);
    });
  });
}
