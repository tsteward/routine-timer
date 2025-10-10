import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/firebase/firebase_options_non_web.dart'
    if (dart.library.html) 'firebase_options.dart';
import 'src/app_theme.dart';
import 'src/bloc/auth_bloc.dart';
import 'src/bloc/auth_state_bloc.dart';
import 'src/bloc/routine_bloc.dart';
import 'src/repositories/routine_repository.dart';
import 'src/router/app_router.dart';
import 'src/screens/sign_in_screen.dart';
import 'src/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      // Use native configuration on Android/iOS (e.g., google-services.json)
      await Firebase.initializeApp();

      // Enable offline persistence for Firestore (not supported on web)
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (e) {
    // ignore: avoid_print
    print('Firebase initialization error: $e');
  }

  // Connect BLoC DevTools in debug mode only.
  // const enableDevtools = bool.fromEnvironment('dart.vm.product') == false;
  // if (enableDevtools) {
  //   final devObserver = RemoteDevToolsObserver(
  //     ipAddress: '127.0.0.1',
  //     portNumber: 8000,
  //   );
  //   try {
  //     await devObserver.connect();
  //     Bloc.observer = devObserver;
  //   } catch (_) {
  //     Bloc.observer = const SimpleBlocObserver();
  //   }
  // } else {
  //   Bloc.observer = const SimpleBlocObserver();
  // }

  runApp(const RoutineTimerApp());
}

class RoutineTimerApp extends StatelessWidget {
  const RoutineTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();
    return MultiBlocProvider(
      providers: [
        // Auth BLoC - available throughout the app
        BlocProvider(create: (context) => AuthBloc()),
        // Routine BLoC - needs auth for user ID
        BlocProvider(
          create: (context) {
            final authService = AuthService();
            final repository = RoutineRepository(authService: authService);
            return RoutineBloc(repository: repository);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Routine Timer',
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AuthGate(),
        onGenerateRoute: appRouter.onGenerateRoute,
      ),
    );
  }
}

/// Widget that shows sign-in screen or main app based on auth state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, authState) {
        // When auth state changes, reload routine for new user
        if (authState.isAuthenticated) {
          context.read<RoutineBloc>().add(const LoadRoutineFromFirebase());
        }
      },
      child: BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, authState) {
          // Show loading indicator while initializing or in initial state
          if (authState.status == AuthStatus.loading ||
              authState.status == AuthStatus.initial) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          // Show sign-in screen if not authenticated
          if (!authState.isAuthenticated) {
            return const SignInScreen();
          }

          // User is authenticated, show main app
          return Navigator(
            onGenerateRoute: AppRouter().onGenerateRoute,
            initialRoute: AppRoutes.preStart,
          );
        },
      ),
    );
  }
}
