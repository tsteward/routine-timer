import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:routine_timer/main.dart' as app;
import 'package:routine_timer/main.dart';
import 'package:routine_timer/src/app_theme.dart';

void main() {
  testWidgets('main() initializes and runs the app', (tester) async {
    // Call main() - it will set up the app
    // Note: We can't await main() in tests as it calls runApp() which doesn't return
    // Instead, we test the app initialization separately
    await tester.pumpWidget(const RoutineTimerApp());
    await tester.pumpAndSettle();

    // Verify the app is running
    expect(find.byType(RoutineTimerApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App boots to Pre-Start and applies theme colors', (
    tester,
  ) async {
    await tester.pumpWidget(const RoutineTimerApp());
    await tester.pumpAndSettle();

    // Pre-Start placeholder should be visible
    expect(find.text('Pre-Start'), findsOneWidget);
    expect(find.text('Countdown placeholder'), findsOneWidget);

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

    await tester.tap(find.text('Main Routine'));
    await tester.pumpAndSettle();

    expect(find.text('Main Routine'), findsOneWidget);
    expect(find.text('Timer & progress placeholder'), findsOneWidget);
  });
}
