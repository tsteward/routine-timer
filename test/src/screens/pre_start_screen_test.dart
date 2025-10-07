import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/screens/pre_start_screen.dart';

void main() {
  group('PreStartScreen', () {
    testWidgets('displays placeholder content', (tester) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: bloc, child: const PreStartScreen()),
        ),
      );

      expect(find.text('Pre-Start'), findsOneWidget);
      expect(find.text('Countdown placeholder'), findsOneWidget);

      bloc.close();
    });

    testWidgets('has navigation menu button', (tester) async {
      final bloc = RoutineBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: bloc, child: const PreStartScreen()),
        ),
      );

      expect(find.byIcon(Icons.navigation), findsOneWidget);

      bloc.close();
    });
  });
}
