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

  /// Formats duration in seconds to a human-readable format (e.g., "10m 30s" or "90m")
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    if (minutes > 0 && secs > 0) {
      return '${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${secs}s';
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

  /// Formats duration in seconds to HH:MM:SS format
  static String formatCountdown(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
  }

  /// Formats actual duration in seconds to "X min Y sec" format
  /// If duration is less than a minute, shows only seconds
  /// If duration is exactly on the minute, omits seconds
  static String formatActualDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    if (minutes == 0) {
      return '$secs sec';
    } else if (secs == 0) {
      return '$minutes min';
    } else {
      return '$minutes min $secs sec';
    }
  }
}
