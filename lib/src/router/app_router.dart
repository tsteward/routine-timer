import 'package:flutter/material.dart';

import '../screens/pre_start_screen.dart';
import '../screens/main_routine_screen.dart';
import '../screens/task_management_screen.dart';

class AppRoutes {
  static const String preStart = '/';
  static const String main = '/main';
  static const String tasks = '/tasks';
}

class AppRouter {
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.preStart:
        return MaterialPageRoute(builder: (_) => const PreStartScreen());
      case AppRoutes.main:
        return MaterialPageRoute(builder: (_) => const MainRoutineScreen());
      case AppRoutes.tasks:
        return MaterialPageRoute(builder: (_) => const TaskManagementScreen());
    }
    return MaterialPageRoute(
      builder: (_) =>
          const Scaffold(body: Center(child: Text('Route not found'))),
    );
  }
}
