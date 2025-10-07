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
  });
}
