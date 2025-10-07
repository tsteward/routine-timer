import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/widgets/settings_panel.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('SettingsPanel', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    testWidgets('displays routine settings', (tester) async {
      final bloc = FirebaseTestHelper.routineBloc
        ..add(const LoadSampleRoutine());
      final loaded = await bloc.stream.firstWhere((s) => s.model != null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: SettingsPanel(model: loaded.model!),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Routine Settings'), findsOneWidget);
      expect(find.text('Routine Start Time'), findsOneWidget);
      expect(find.text('Break Duration'), findsOneWidget);
    });
  });
}
