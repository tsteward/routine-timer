import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/screens/main_routine_screen.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('MainRoutineScreen', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    testWidgets('displays placeholder content', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc;

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
    });
  });
}
