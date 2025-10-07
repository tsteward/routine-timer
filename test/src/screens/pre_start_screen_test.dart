import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/screens/pre_start_screen.dart';
import 'package:routine_timer/src/utils/time_formatter.dart';

void main() {
  group('PreStartScreen', () {
    // Unit tests for TimeFormatter (used by PreStartScreen)
    group('TimeFormatter.formatCountdown', () {
      test('formats zero correctly', () {
        expect(TimeFormatter.formatCountdown(0), '00:00:00');
      });

      test('formats seconds only', () {
        expect(TimeFormatter.formatCountdown(45), '00:00:45');
      });

      test('formats minutes and seconds', () {
        expect(TimeFormatter.formatCountdown(125), '00:02:05');
      });

      test('formats hours, minutes, and seconds', () {
        expect(TimeFormatter.formatCountdown(3661), '01:01:01');
        expect(TimeFormatter.formatCountdown(7325), '02:02:05');
      });

      test('formats large durations', () {
        expect(TimeFormatter.formatCountdown(36000), '10:00:00');
      });
    });

    // Widget tests
    testWidgets('builds without error when model is null', (tester) async {
      final bloc = RoutineBloc();
      // Don't load sample data - model will be null

      bool navigationAttempted = false;

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.main) {
              navigationAttempted = true;
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Text('Main Screen'),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const PreStartScreen(),
              ),
            );
          },
          initialRoute: '/',
        ),
      );

      // Let post-frame callbacks run
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should attempt navigation since model is null
      expect(navigationAttempted, isTrue);

      await bloc.close();
    }, skip: false);

    testWidgets('displays UI elements when start time is far in future',
        (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      // Give BLoC time to load
      await Future.delayed(const Duration(milliseconds: 100));

      // Set start time far in the future (10 hours)
      final futureTime = DateTime.now().add(const Duration(hours: 10));
      final currentSettings = bloc.state.model!.settings;
      final newSettings = currentSettings.copyWith(
        startTime: futureTime.millisecondsSinceEpoch,
      );
      bloc.add(UpdateSettings(newSettings));

      // Give BLoC time to process
      await Future.delayed(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const PreStartScreen(),
          ),
        ),
      );

      // Initial pump
      await tester.pump();

      // Check for UI elements
      expect(find.text('Routine Starts In:'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2)); // Title + countdown
      expect(find.byIcon(Icons.navigation), findsOneWidget);

      // Check for Scaffold with black background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));

      await bloc.close();
    }, skip: false);

    testWidgets('navigation menu button opens popup', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await Future.delayed(const Duration(milliseconds: 100));

      // Set start time far in the future
      final futureTime = DateTime.now().add(const Duration(hours: 10));
      final currentSettings = bloc.state.model!.settings;
      final newSettings = currentSettings.copyWith(
        startTime: futureTime.millisecondsSinceEpoch,
      );
      bloc.add(UpdateSettings(newSettings));

      await Future.delayed(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const PreStartScreen(),
          ),
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Text(settings.name ?? 'unknown'),
              ),
            );
          },
        ),
      );

      await tester.pump();

      // Tap navigation button
      await tester.tap(find.byIcon(Icons.navigation));
      await tester.pumpAndSettle();

      // Check menu items appear
      expect(find.text('Pre-Start'), findsOneWidget);
      expect(find.text('Main Routine'), findsOneWidget);
      expect(find.text('Task Management'), findsOneWidget);

      await bloc.close();
    }, skip: false);

    testWidgets('countdown displays in correct format', (tester) async {
      final bloc = RoutineBloc()..add(const LoadSampleRoutine());

      await Future.delayed(const Duration(milliseconds: 100));

      // Set start time 90 seconds in the future (1:30)
      final futureTime = DateTime.now().add(const Duration(seconds: 90));
      final currentSettings = bloc.state.model!.settings;
      final newSettings = currentSettings.copyWith(
        startTime: futureTime.millisecondsSinceEpoch,
      );
      bloc.add(UpdateSettings(newSettings));

      await Future.delayed(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const PreStartScreen(),
          ),
        ),
      );

      await tester.pump();

      // Find countdown text matching HH:MM:SS format
      final countdownFinder = find.textContaining(RegExp(r'\d{2}:\d{2}:\d{2}'));
      expect(countdownFinder, findsOneWidget);

      final countdownText = tester.widget<Text>(countdownFinder).data!;
      // Should show approximately 00:01:30 or 00:01:29
      expect(
        countdownText.startsWith('00:01:'),
        isTrue,
        reason: 'Countdown should start with 00:01: for 90 seconds',
      );

      await bloc.close();
    }, skip: false);
  });
}