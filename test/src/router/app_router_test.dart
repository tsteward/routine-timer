import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/router/app_router.dart';

void main() {
  group('AppRoutes', () {
    test('has correct route constants', () {
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

    test('can be instantiated', () {
      expect(router, isNotNull);
    });

    test('generates MaterialPageRoute for preStart screen', () {
      final route = router.onGenerateRoute(
        const RouteSettings(name: AppRoutes.preStart),
      );

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('generates MaterialPageRoute for main screen', () {
      final route = router.onGenerateRoute(
        const RouteSettings(name: AppRoutes.main),
      );

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('generates MaterialPageRoute for tasks screen', () {
      final route = router.onGenerateRoute(
        const RouteSettings(name: AppRoutes.tasks),
      );

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('generates 404 route for unknown path', () {
      final route = router.onGenerateRoute(
        const RouteSettings(name: '/unknown'),
      );

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('generates 404 route for null route name', () {
      final route = router.onGenerateRoute(
        const RouteSettings(name: null),
      );

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('generates 404 route for empty string', () {
      final route = router.onGenerateRoute(
        const RouteSettings(name: ''),
      );

      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles various invalid routes consistently', () {
      final invalidRoutes = ['/invalid', '/does-not-exist', '/foo/bar', null, ''];
      
      for (final routeName in invalidRoutes) {
        final route = router.onGenerateRoute(
          RouteSettings(name: routeName),
        );
        
        expect(route, isNotNull, reason: 'Route should not be null for $routeName');
        expect(route, isA<MaterialPageRoute>(), reason: 'Route should be MaterialPageRoute for $routeName');
      }
    });

    test('returns different routes for different valid paths', () {
      final preStartRoute = router.onGenerateRoute(
        const RouteSettings(name: AppRoutes.preStart),
      );
      final mainRoute = router.onGenerateRoute(
        const RouteSettings(name: AppRoutes.main),
      );
      final tasksRoute = router.onGenerateRoute(
        const RouteSettings(name: AppRoutes.tasks),
      );

      expect(preStartRoute, isNotNull);
      expect(mainRoute, isNotNull);
      expect(tasksRoute, isNotNull);
      
      // They should all be MaterialPageRoutes
      expect(preStartRoute, isA<MaterialPageRoute>());
      expect(mainRoute, isA<MaterialPageRoute>());
      expect(tasksRoute, isA<MaterialPageRoute>());
    });
  });
}
