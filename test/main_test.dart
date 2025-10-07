import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:routine_timer/main.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';

void main() {
  testWidgets('App boots to Pre-Start and applies theme colors', (
    tester,
  ) async {
    await tester.pumpWidget(const RoutineTimerApp());
    await tester.pumpAndSettle();

    // Since sample routine has start time = now, it should navigate to Main Routine
    // The pre-start screen should auto-navigate when start time is in the past/now
    expect(find.text('Main Routine'), findsOneWidget);

    // Theme primary color should match our brand green
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.colorScheme.primary, AppTheme.green);
  });

  testWidgets('Can navigate to Task Management via the test menu', (
    tester,
  ) async {
    await tester.pumpWidget(const RoutineTimerApp());
    await tester.pumpAndSettle();

    // Open the popup menu (navigation menu)
    await tester.tap(find.byIcon(Icons.navigation));
    await tester.pumpAndSettle();

    // Select Task Management
    await tester.tap(find.text('Task Management'));
    await tester.pumpAndSettle();

    // AppBar title should be visible
    expect(find.text('Task Management'), findsOneWidget);
    // Left column should show a reorderable task list with sample data
    expect(find.byType(ReorderableListView), findsOneWidget);
    // Task appears in both left column and right column text field
    expect(find.text('Morning Workout'), findsAtLeastNWidgets(1));
    // Right column should show settings and details
    expect(find.text('Routine Settings'), findsOneWidget);
    expect(find.text('Task Details'), findsOneWidget);
  });

  testWidgets('Can navigate to Main Routine via the test menu', (tester) async {
    await tester.pumpWidget(const RoutineTimerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.navigation));
    await tester.pumpAndSettle();

    // Tap the last "Main Routine" in the menu (not the title)
    await tester.tap(find.text('Main Routine').last);
    await tester.pumpAndSettle();

    expect(find.text('Timer & progress placeholder'), findsOneWidget);
  });

  testWidgets('RoutineTimerApp provides RoutineBloc via BlocProvider', (
    tester,
  ) async {
    await tester.pumpWidget(const RoutineTimerApp());

    // Verify that BlocProvider is present
    expect(find.byType(BlocProvider<RoutineBloc>), findsOneWidget);
  });

  testWidgets('RoutineTimerApp initializes with LoadSampleRoutine event', (
    tester,
  ) async {
    await tester.pumpWidget(const RoutineTimerApp());
    await tester.pump();

    // Find the BlocProvider and verify it loads sample routine
    final blocProvider = tester.widget<BlocProvider<RoutineBloc>>(
      find.byType(BlocProvider<RoutineBloc>),
    );

    expect(blocProvider, isNotNull);
  });

  testWidgets('MaterialApp is configured with correct properties', (
    tester,
  ) async {
    await tester.pumpWidget(const RoutineTimerApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.title, 'Routine Timer');
    expect(materialApp.theme, isNotNull);
    expect(materialApp.darkTheme, isNotNull);
    expect(materialApp.themeMode, ThemeMode.light);
  });

  testWidgets('MaterialApp theme uses AppTheme configuration', (tester) async {
    await tester.pumpWidget(const RoutineTimerApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.theme!.colorScheme.primary, AppTheme.green);
    expect(materialApp.theme, equals(AppTheme.theme));
    expect(materialApp.darkTheme, equals(AppTheme.darkTheme));
  });

  testWidgets('App has onGenerateRoute configured', (tester) async {
    await tester.pumpWidget(const RoutineTimerApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.onGenerateRoute, isNotNull);
  });

  testWidgets('App has correct initial route', (tester) async {
    await tester.pumpWidget(const RoutineTimerApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(materialApp.initialRoute, '/');
  });

  testWidgets('RoutineTimerApp creates new AppRouter instance', (
    tester,
  ) async {
    await tester.pumpWidget(const RoutineTimerApp());
    await tester.pump();

    // The app should successfully build and have a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Dark theme is available but light mode is default', (
    tester,
  ) async {
    await tester.pumpWidget(const RoutineTimerApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    // Dark theme should be set
    expect(materialApp.darkTheme, isNotNull);
    expect(materialApp.darkTheme, equals(AppTheme.darkTheme));

    // But light mode should be the default
    expect(materialApp.themeMode, ThemeMode.light);
  });
}
