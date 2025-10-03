import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/screens/task_management_screen.dart';

void main() {
  group('TaskManagementScreen gaps & breaks', () {
    testWidgets('renders gap UI and toggles between states', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // There should be 3 gaps between 4 tasks. Initially 2 enabled (per sample).
      // Find enabled break widgets by icon and label text
      expect(find.textContaining('Break ·'), findsNWidgets(2));
      expect(find.byIcon(Icons.local_cafe), findsNWidgets(2));

      // Find disabled gap placeholders by text
      expect(find.text('Add Break'), findsNWidgets(1));

      // Tap the disabled gap to enable it
      await tester.tap(find.text('Add Break'));
      await tester.pumpAndSettle();

      // Now all 3 should be enabled
      expect(find.textContaining('Break ·'), findsNWidgets(3));

      // Toggle one back off by tapping its container (first enabled)
      final firstEnabled = find.textContaining('Break ·').first;
      await tester.tap(firstEnabled);
      await tester.pumpAndSettle();

      // We should have 2 enabled again
      expect(find.textContaining('Break ·'), findsNWidgets(2));
    });

    testWidgets('Enable Breaks by Default switch updates all gaps', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const TaskManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle switch off
      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // All gaps disabled (3 placeholders)
      expect(find.text('Add Break'), findsNWidgets(3));
      expect(find.textContaining('Break ·'), findsNothing);

      // Toggle switch on
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // All gaps enabled
      expect(find.textContaining('Break ·'), findsNWidgets(3));
      expect(find.text('Add Break'), findsNothing);
    });
  });
}
