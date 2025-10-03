import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app_theme.dart';
import 'src/router/app_router.dart';
import 'src/utils/simple_bloc_observer.dart';
import 'package:bloc_dev_tools/bloc_dev_tools.dart';
import 'src/bloc/routine_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect BLoC DevTools in debug mode only.
  const enableDevtools = bool.fromEnvironment('dart.vm.product') == false;
  if (enableDevtools) {
    final devObserver = RemoteDevToolsObserver(
      ipAddress: '127.0.0.1',
      portNumber: 8000,
    );
    try {
      await devObserver.connect();
      Bloc.observer = devObserver;
    } catch (_) {
      Bloc.observer = const SimpleBlocObserver();
    }
  } else {
    Bloc.observer = const SimpleBlocObserver();
  }

  runApp(const RoutineTimerApp());
}

class RoutineTimerApp extends StatelessWidget {
  const RoutineTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();
    return BlocProvider(
      create: (_) => RoutineBloc()..add(const LoadSampleRoutine()),
      child: MaterialApp(
        title: 'Routine Timer',
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        onGenerateRoute: appRouter.onGenerateRoute,
        initialRoute: AppRoutes.preStart,
      ),
    );
  }
}
