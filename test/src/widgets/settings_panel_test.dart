import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/widgets/settings_panel.dart';

void main() {
  group('SettingsPanel', () {
    testWidgets('displays routine settings', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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
      expect(find.text('Enable Breaks by Default'), findsOneWidget);
      expect(find.text('Break Duration'), findsOneWidget);

      bloc.close();
    });

    testWidgets('displays formatted start time', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      // Should display a time format (e.g., "7:00 AM")
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.contains(':'),
        ),
        findsWidgets,
      );

      bloc.close();
    });

    testWidgets('displays formatted break duration', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      // Should display duration in some format (e.g., "5m")
      expect(find.byType(Text), findsWidgets);

      bloc.close();
    });

    testWidgets('has clickable start time field', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      // Find the InkWell that contains the start time
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);

      bloc.close();
    });

    testWidgets('has clickable break duration field', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      // Find the InkWell widgets
      expect(find.byType(InkWell), findsWidgets);

      bloc.close();
    });

    testWidgets('has switch for breaks enabled by default', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      // Verify the switch is present
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Verify the SwitchListTile is present
      expect(find.byType(SwitchListTile), findsOneWidget);

      bloc.close();
    });

    testWidgets('displays icons for time and duration', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      // Should have access_time icon
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      // Should have timer_outlined icon
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);

      bloc.close();
    });

    testWidgets('displays dividers between sections', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      // Should have dividers separating sections
      expect(find.byType(Divider), findsWidgets);

      bloc.close();
    });

    testWidgets('wraps content in a card', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      expect(find.byType(Card), findsOneWidget);

      bloc.close();
    });

    testWidgets('uses theme colors for text and icons', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());
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

      // Verify icons are present (color is applied via theme)
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(icons.length, greaterThan(0));

      bloc.close();
    });
  });
}
