import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/screens/pre_start_screen.dart';
import 'package:routine_timer/src/router/app_router.dart';
import 'package:routine_timer/src/utils/time_formatter.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('PreStartScreen', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      FirebaseTestHelper.reset();
    });

    // Test the TimeFormatter used by PreStartScreen
    group('TimeFormatter.formatCountdown', () {
      test('formats zero correctly', () {
        expect(TimeFormatter.formatCountdown(0), '00:00:00');
      });

      test('formats seconds only', () {
        expect(TimeFormatter.formatCountdown(1), '00:00:01');
        expect(TimeFormatter.formatCountdown(45), '00:00:45');
        expect(TimeFormatter.formatCountdown(59), '00:00:59');
      });

      test('formats minutes and seconds', () {
        expect(TimeFormatter.formatCountdown(60), '00:01:00');
        expect(TimeFormatter.formatCountdown(125), '00:02:05');
        expect(TimeFormatter.formatCountdown(599), '00:09:59');
      });

      test('formats hours, minutes, and seconds', () {
        expect(TimeFormatter.formatCountdown(3600), '01:00:00');
        expect(TimeFormatter.formatCountdown(3661), '01:01:01');
        expect(TimeFormatter.formatCountdown(7325), '02:02:05');
      });

      test('formats large durations correctly', () {
        expect(TimeFormatter.formatCountdown(36000), '10:00:00');
        expect(TimeFormatter.formatCountdown(86399), '23:59:59');
      });

      test('formats typical countdown scenarios', () {
        // 2 minutes 30 seconds
        expect(TimeFormatter.formatCountdown(150), '00:02:30');
        // 1 hour 30 minutes
        expect(TimeFormatter.formatCountdown(5400), '01:30:00');
        // 5 hours exactly
        expect(TimeFormatter.formatCountdown(18000), '05:00:00');
      });
    });
  });
}
