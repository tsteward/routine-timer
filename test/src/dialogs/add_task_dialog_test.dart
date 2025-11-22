import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/dialogs/add_task_dialog.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('AddTaskDialog', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    testWidgets('displays dialog with tabbed interface', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

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
                      builder: (ctx) => const AddTaskDialog(),
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

      // Check dialog title changed from "Add New Task" to "Add Task"
      expect(find.text('Add Task'), findsWidgets); // Title + tab + button

      // Check for tabs
      expect(find.text('Create New'), findsOneWidget);

      // Check that "Task Name" field exists in Create New tab (should be visible by default)
      expect(find.text('Task Name'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('validates empty task name in Create New tab', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

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
                      builder: (ctx) => const AddTaskDialog(),
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

      // Find the "Add Task" button within the Create New tab
      final addTaskButtons = find.widgetWithText(ElevatedButton, 'Add Task');
      expect(addTaskButtons, findsOneWidget);

      // Try to add without entering a name
      await tester.tap(addTaskButtons);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a task name'), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      await bloc.stream.firstWhere((s) => s.model != null);

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
                      builder: (ctx) => const AddTaskDialog(),
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

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AddTaskDialog), findsNothing);
    });
  });
}
