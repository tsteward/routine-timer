import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/router/app_router.dart';

void main() {
  group('AppRoutes', () {
    test('defines correct route constants', () {
      expect(AppRoutes.preStart, equals('/'));
      expect(AppRoutes.main, equals('/main'));
      expect(AppRoutes.tasks, equals('/tasks'));
    });
  });

  group('AppRouter', () {
    late AppRouter router;

    setUp(() {
      router = AppRouter();
    });

    testWidgets('routes to PreStartScreen for preStart route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: router.onGenerateRoute,
          initialRoute: AppRoutes.preStart,
        ),
      );

      await tester.pumpAndSettle();

      // The pre-start screen should be visible
      expect(find.text('Pre-Start'), findsOneWidget);
    });

    testWidgets('routes to MainRoutineScreen for main route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: router.onGenerateRoute,
          initialRoute: AppRoutes.main,
        ),
      );

      await tester.pumpAndSettle();

      // The main routine screen should be visible
      expect(find.text('Main Routine'), findsOneWidget);
    });

    test('generates route for tasks screen', () {
      const settings = RouteSettings(name: AppRoutes.tasks);
      final route = router.onGenerateRoute(settings);

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    testWidgets('returns 404 page for unknown route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: router.onGenerateRoute,
          initialRoute: '/unknown',
        ),
      );

      await tester.pumpAndSettle();

      // Should show the "Route not found" message
      expect(find.text('Route not found'), findsOneWidget);
    });

    test('onGenerateRoute returns a MaterialPageRoute', () {
      const settings = RouteSettings(name: AppRoutes.preStart);
      final route = router.onGenerateRoute(settings);

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('onGenerateRoute returns 404 for null route', () {
      const settings = RouteSettings(name: null);
      final route = router.onGenerateRoute(settings);

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });
  });
}
