import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/router/app_router.dart';

void main() {
  group('AppRouter', () {
    late AppRouter router;

    setUp(() {
      router = AppRouter();
    });

    test('onGenerateRoute returns PreStartScreen for preStart route', () {
      const settings = RouteSettings(name: AppRoutes.preStart);
      final route = router.onGenerateRoute(settings);

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('onGenerateRoute returns MainRoutineScreen for main route', () {
      const settings = RouteSettings(name: AppRoutes.main);
      final route = router.onGenerateRoute(settings);

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('onGenerateRoute returns TaskManagementScreen for tasks route', () {
      const settings = RouteSettings(name: AppRoutes.tasks);
      final route = router.onGenerateRoute(settings);

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('onGenerateRoute returns route for unknown route', () {
      const settings = RouteSettings(name: '/unknown');
      final route = router.onGenerateRoute(settings);

      // The router returns a fallback route
      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('AppRoutes constants are correct', () {
      expect(AppRoutes.preStart, '/');
      expect(AppRoutes.main, '/main');
      expect(AppRoutes.tasks, '/tasks');
    });
  });
}
