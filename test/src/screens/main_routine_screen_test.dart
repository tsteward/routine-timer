import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/screens/main_routine_screen.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';

void main() {
  group('MainRoutineScreen', () {
    testWidgets('displays placeholder content', (tester) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
        ),
      );

      expect(find.text('Main Routine'), findsOneWidget);
      expect(find.text('Timer & progress placeholder'), findsOneWidget);

      bloc.close();
    });

    testWidgets('has navigation FAB that opens menu', (tester) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
          routes: {
            AppRoutes.preStart: (_) => const Scaffold(body: Text('Pre-Start')),
            AppRoutes.main: (_) => const Scaffold(body: Text('Main Routine')),
            AppRoutes.tasks: (_) => const Scaffold(body: Text('Tasks')),
          },
        ),
      );

      // Tap the navigation FAB
      await tester.tap(find.byIcon(Icons.navigation));
      await tester.pumpAndSettle();

      // Menu should be visible
      expect(find.text('Pre-Start'), findsOneWidget);
      expect(find.text('Task Management'), findsOneWidget);

      bloc.close();
    });

    testWidgets('navigation FAB can navigate to Pre-Start', (tester) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const MainRoutineScreen(),
          ),
          routes: {
            AppRoutes.preStart: (_) =>
                const Scaffold(body: Text('Pre-Start Page')),
          },
        ),
      );

      // Open navigation menu
      await tester.tap(find.byIcon(Icons.navigation));
      await tester.pumpAndSettle();

      // Select Pre-Start
      await tester.tap(find.text('Pre-Start'));
      await tester.pumpAndSettle();

      // Should navigate to Pre-Start
      expect(find.text('Pre-Start Page'), findsOneWidget);

      bloc.close();
    });
  });
}
