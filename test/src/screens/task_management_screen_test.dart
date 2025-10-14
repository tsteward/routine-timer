import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/screens/task_management_screen.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/app_theme.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('TaskManagementScreen Integration Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    testWidgets('displays screen structure correctly', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      // Should have basic screen structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Task Management'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget); // Two-column layout
      expect(
        find.byType(Expanded),
        findsNWidgets(3),
      ); // Main content + left and right columns
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows no routine loaded initially', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      // Shows "No routine loaded" in both left and right columns
      expect(find.text('No routine loaded'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays task list after loading data', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      // Load sample data
      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Should show task list
      expect(find.byType(ReorderableListView), findsOneWidget);
      // Tasks will appear in both left column and right column (in text field)
      expect(find.text('Wake up'), findsAtLeastNWidgets(1));
      expect(find.text('Prayer'), findsAtLeastNWidgets(1));
      expect(find.text('Shower - Gather Clothes'), findsAtLeastNWidgets(1));
      expect(find.text('Cook'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays task durations correctly', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Check durations are displayed
      expect(
        find.text('2 min'),
        findsAtLeastNWidgets(1),
      ); // Wake up and other 2-min tasks
      expect(find.text('5 min'), findsAtLeastNWidgets(1)); // Prayer and Shave
      expect(find.text('15 min'), findsOneWidget); // Cook
      expect(find.text('20 min'), findsOneWidget); // Eat
    });

    testWidgets('displays drag handles', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Should have drag handles (one for each of the 14 tasks)
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(14));
    });

    testWidgets('handles task selection', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Tap on second task (Prayer)
      await tester.tap(find.text('Prayer').first);
      await tester.pumpAndSettle();

      // Verify selection changed
      expect(bloc.state.model?.currentTaskIndex, 1);
    });

    testWidgets('displays right column settings and details', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: BlocProvider<RoutineBloc>.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      bloc.add(const LoadSampleRoutine());
      await tester.pumpAndSettle();

      // Check for routine settings section
      expect(find.text('Routine Settings'), findsOneWidget);
      expect(find.text('Routine Start Time'), findsOneWidget);
      expect(find.text('Break Duration'), findsOneWidget);

      // Check for task details section
      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Task Name'), findsOneWidget);
      expect(find.text('Estimated Duration'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
