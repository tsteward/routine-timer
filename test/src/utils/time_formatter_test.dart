import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/utils/time_formatter.dart';

void main() {
  group('TimeFormatter', () {
    group('formatTimeHHmm', () {
      test('formats time correctly in HH:MM format', () {
        expect(
          TimeFormatter.formatTimeHHmm(DateTime(2024, 1, 1, 8, 0)),
          '08:00',
        );
        expect(
          TimeFormatter.formatTimeHHmm(DateTime(2024, 1, 1, 14, 30)),
          '14:30',
        );
        expect(
          TimeFormatter.formatTimeHHmm(DateTime(2024, 1, 1, 9, 5)),
          '09:05',
        );
        expect(
          TimeFormatter.formatTimeHHmm(DateTime(2024, 1, 1, 23, 59)),
          '23:59',
        );
        expect(
          TimeFormatter.formatTimeHHmm(DateTime(2024, 1, 1, 0, 0)),
          '00:00',
        );
      });
    });

    group('formatTimeOfDay', () {
      test('formats TimeOfDay correctly in HH:MM format', () {
        expect(
          TimeFormatter.formatTimeOfDay(const TimeOfDay(hour: 8, minute: 0)),
          '08:00',
        );
        expect(
          TimeFormatter.formatTimeOfDay(const TimeOfDay(hour: 14, minute: 30)),
          '14:30',
        );
        expect(
          TimeFormatter.formatTimeOfDay(const TimeOfDay(hour: 9, minute: 5)),
          '09:05',
        );
        expect(
          TimeFormatter.formatTimeOfDay(const TimeOfDay(hour: 23, minute: 59)),
          '23:59',
        );
        expect(
          TimeFormatter.formatTimeOfDay(const TimeOfDay(hour: 0, minute: 0)),
          '00:00',
        );
      });
    });

    group('formatDuration', () {
      test('formats duration less than 1 hour in minutes only', () {
        expect(TimeFormatter.formatDuration(60), '1m');
        expect(TimeFormatter.formatDuration(300), '5m');
        expect(TimeFormatter.formatDuration(1800), '30m');
        expect(TimeFormatter.formatDuration(3540), '59m');
      });

      test('formats duration over 1 hour in hours and minutes', () {
        expect(TimeFormatter.formatDuration(3600), '1h 0m');
        expect(TimeFormatter.formatDuration(5400), '1h 30m');
        expect(TimeFormatter.formatDuration(7200), '2h 0m');
        expect(TimeFormatter.formatDuration(9000), '2h 30m');
      });

      test('formats zero duration', () {
        expect(TimeFormatter.formatDuration(0), '0m');
      });
    });

    group('formatDurationMinutes', () {
      test('formats duration correctly in minutes', () {
        expect(TimeFormatter.formatDurationMinutes(60), '1 min');
        expect(TimeFormatter.formatDurationMinutes(120), '2 min');
        expect(TimeFormatter.formatDurationMinutes(90), '2 min'); // Rounds up
        expect(TimeFormatter.formatDurationMinutes(30), '1 min'); // Rounds up
        expect(TimeFormatter.formatDurationMinutes(600), '10 min');
        expect(TimeFormatter.formatDurationMinutes(0), '0 min');
      });
    });

    group('formatDurationHoursMinutes', () {
      test('formats duration less than 1 hour in minutes only', () {
        expect(TimeFormatter.formatDurationHoursMinutes(60), '1m');
        expect(TimeFormatter.formatDurationHoursMinutes(300), '5m');
        expect(TimeFormatter.formatDurationHoursMinutes(1800), '30m');
        expect(TimeFormatter.formatDurationHoursMinutes(3540), '59m');
      });

      test('formats duration over 1 hour in hours and minutes', () {
        expect(TimeFormatter.formatDurationHoursMinutes(3600), '1h 0m');
        expect(TimeFormatter.formatDurationHoursMinutes(5400), '1h 30m');
        expect(TimeFormatter.formatDurationHoursMinutes(7200), '2h 0m');
        expect(TimeFormatter.formatDurationHoursMinutes(9000), '2h 30m');
      });

      test('formats zero duration', () {
        expect(TimeFormatter.formatDurationHoursMinutes(0), '0m');
      });
    });

    group('formatCountdown', () {
      test('formats countdown in HH:MM:SS format with padding', () {
        expect(TimeFormatter.formatCountdown(0), '00:00:00');
        expect(TimeFormatter.formatCountdown(1), '00:00:01');
        expect(TimeFormatter.formatCountdown(59), '00:00:59');
        expect(TimeFormatter.formatCountdown(60), '00:01:00');
        expect(TimeFormatter.formatCountdown(61), '00:01:01');
      });

      test('formats minutes correctly in countdown', () {
        expect(TimeFormatter.formatCountdown(120), '00:02:00');
        expect(TimeFormatter.formatCountdown(125), '00:02:05');
        expect(TimeFormatter.formatCountdown(599), '00:09:59');
        expect(TimeFormatter.formatCountdown(3599), '00:59:59');
      });

      test('formats hours correctly in countdown', () {
        expect(TimeFormatter.formatCountdown(3600), '01:00:00');
        expect(TimeFormatter.formatCountdown(3661), '01:01:01');
        expect(TimeFormatter.formatCountdown(7200), '02:00:00');
        expect(TimeFormatter.formatCountdown(7325), '02:02:05');
      });

      test('formats large durations correctly', () {
        expect(TimeFormatter.formatCountdown(36000), '10:00:00');
        expect(TimeFormatter.formatCountdown(86399), '23:59:59');
        expect(TimeFormatter.formatCountdown(90061), '25:01:01');
      });

      test('handles typical countdown scenarios', () {
        // 2 minutes 30 seconds
        expect(TimeFormatter.formatCountdown(150), '00:02:30');
        // 1 hour 30 minutes 45 seconds
        expect(TimeFormatter.formatCountdown(5445), '01:30:45');
        // 5 hours exactly
        expect(TimeFormatter.formatCountdown(18000), '05:00:00');
      });
    });
  });
}
