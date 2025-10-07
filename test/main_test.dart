import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine_timer/src/app_theme.dart';
import 'package:routine_timer/src/bloc/auth_bloc.dart';
import 'package:routine_timer/src/bloc/auth_state_bloc.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'src/test_helpers/firebase_test_helper.dart';

/// Test-specific app that uses mocked Firebase services
class TestRoutineTimerApp extends StatelessWidget {
  const TestRoutineTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => FirebaseTestHelper.authBloc),
        BlocProvider(create: (context) => FirebaseTestHelper.routineBloc),
      ],
      child: MaterialApp(
        title: 'Routine Timer',
        theme: AppTheme.theme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const TestAuthGate(),
        onGenerateRoute: AppRouter().onGenerateRoute,
      ),
    );
  }
}

/// Test-specific auth gate that bypasses Firebase initialization
class TestAuthGate extends StatelessWidget {
  const TestAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Set up a signed-in user for testing
    FirebaseTestHelper.setupSignedInUser();

    return BlocListener<AuthBloc, AuthBlocState>(
      listener: (context, authState) {
        if (authState.isAuthenticated) {
          context.read<RoutineBloc>().add(const LoadSampleRoutine());
        }
      },
      child: BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, authState) {
          // Always show the main app for testing (bypass auth)
          return Navigator(
            onGenerateRoute: AppRouter().onGenerateRoute,
            initialRoute: AppRoutes.preStart,
          );
        },
      ),
    );
  }
}

void main() {
  group('Main App Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    testWidgets('App boots to Pre-Start and applies theme colors', (
      tester,
    ) async {
      await tester.pumpWidget(const TestRoutineTimerApp());
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
      await tester.pumpWidget(const TestRoutineTimerApp());
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

    testWidgets('Can navigate to Main Routine via the test menu', (
      tester,
    ) async {
      await tester.pumpWidget(const TestRoutineTimerApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.navigation));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Main Routine'));
      await tester.pumpAndSettle();

      expect(find.text('Main Routine'), findsOneWidget);
      expect(find.text('Timer & progress placeholder'), findsOneWidget);
    });
  });
}
