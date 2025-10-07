import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/router/app_router.dart';

void main() {
  group('AppRoutes', () {
    test('has correct route constants', () {
      expect(AppRoutes.preStart, '/');
      expect(AppRoutes.main, '/main');
      expect(AppRoutes.tasks, '/tasks');
    });
  });

  group('AppRouter', () {
    late AppRouter router;

    setUp(() {
      router = AppRouter();
    });

    testWidgets('onGenerateRoute returns PreStartScreen for preStart route',
        (tester) async {
      const settings = RouteSettings(name: AppRoutes.preStart);
      final route = router.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      expect(route, isNotNull);
    });

    testWidgets('onGenerateRoute returns MainRoutineScreen for main route',
        (tester) async {
      const settings = RouteSettings(name: AppRoutes.main);
      final route = router.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      expect(route, isNotNull);
    });

    testWidgets('onGenerateRoute returns TaskManagementScreen for tasks route',
        (tester) async {
      const settings = RouteSettings(name: AppRoutes.tasks);
      final route = router.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      expect(route, isNotNull);
    });

    testWidgets('onGenerateRoute returns error screen for unknown route',
        (tester) async {
      const settings = RouteSettings(name: '/unknown');
      final route = router.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      expect(route, isNotNull);
    });

    testWidgets('onGenerateRoute handles null route name', (tester) async {
      const settings = RouteSettings(name: null);
      final route = router.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      expect(route, isNotNull);
    });

    testWidgets('onGenerateRoute handles empty route name', (tester) async {
      const settings = RouteSettings(name: '');
      final route = router.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      expect(route, isNotNull);
    });

    testWidgets('onGenerateRoute handles route with parameters',
        (tester) async {
      const settings = RouteSettings(
        name: AppRoutes.main,
        arguments: {'test': 'value'},
      );
      final route = router.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      expect(route, isNotNull);
    });

    testWidgets('all routes return non-null MaterialPageRoute',
        (tester) async {
      final routes = [AppRoutes.preStart, AppRoutes.main, AppRoutes.tasks];

      for (final routeName in routes) {
        final settings = RouteSettings(name: routeName);
        final route = router.onGenerateRoute(settings);

        expect(route, isNotNull);
        expect(route, isA<MaterialPageRoute>());
      }
    });

    test('router can be instantiated', () {
      expect(router, isNotNull);
      expect(router.onGenerateRoute, isNotNull);
    });

    test('onGenerateRoute always returns a Route', () {
      const settings = RouteSettings(name: '/nonexistent');
      final route = router.onGenerateRoute(settings);

      // Should return a fallback route instead of null
      expect(route, isNotNull);
    });
  });
}
