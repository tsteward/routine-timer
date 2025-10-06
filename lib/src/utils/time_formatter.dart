import 'package:flutter/material.dart';

/// Utility class for formatting time and duration values
class TimeFormatter {
  /// Formats a DateTime as HH:mm (24-hour format)
  static String formatTimeHHmm(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Formats a TimeOfDay as HH:mm (24-hour format)
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formats duration in seconds to a human-readable format (e.g., "1h 30m")
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Formats duration in seconds to minutes (e.g., "90 min")
  static String formatDurationMinutes(int seconds) {
    final minutes = (seconds / 60).round();
    return '$minutes min';
  }

  /// Formats duration in seconds to hours and minutes (e.g., "1h 30m" or "30m")
  static String formatDurationHoursMinutes(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

