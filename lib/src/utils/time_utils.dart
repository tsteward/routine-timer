import '../models/break.dart';
import '../models/routine_state.dart';
import '../models/task.dart';

/// Utility helpers for routine time computations shared by widgets and tests.
class TimeUtils {
  const TimeUtils._();

  /// Computes the absolute start time for each task index based on the
  /// routine start time, the sum of prior task durations, and any enabled
  /// breaks between tasks.
  static List<DateTime> computeTaskStartTimes(RoutineStateModel model) {
    final start = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    final results = <DateTime>[];
    int accumulatedSeconds = 0;

    for (var i = 0; i < model.tasks.length; i++) {
      results.add(start.add(Duration(seconds: accumulatedSeconds)));
      // Add this task's duration for the next index
      accumulatedSeconds += model.tasks[i].estimatedDuration;
      // If a break exists after this index and is enabled, include it
      if (model.breaks != null && i < model.breaks!.length) {
        final BreakModel gap = model.breaks![i];
        if (gap.isEnabled) accumulatedSeconds += gap.duration;
      }
    }
    return results;
  }

  /// Returns the total duration in seconds across all tasks (no breaks).
  static int sumTaskSeconds(List<TaskModel> tasks) {
    var total = 0;
    for (final t in tasks) {
      total += t.estimatedDuration;
    }
    return total;
  }

  /// Returns the total duration in seconds across enabled breaks.
  static int sumEnabledBreakSeconds(List<BreakModel>? breaks) {
    if (breaks == null) return 0;
    var total = 0;
    for (final b in breaks) {
      if (b.isEnabled) total += b.duration;
    }
    return total;
  }

  /// Returns the total routine duration (tasks + enabled breaks) in seconds.
  static int computeTotalRoutineSeconds(RoutineStateModel model) {
    return sumTaskSeconds(model.tasks) + sumEnabledBreakSeconds(model.breaks);
  }

  /// Computes the estimated finish time based on routine start plus the total
  /// of all tasks and enabled breaks.
  static DateTime computeEstimatedFinishTime(RoutineStateModel model) {
    final totalSeconds = computeTotalRoutineSeconds(model);
    final start = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    return start.add(Duration(seconds: totalSeconds));
  }
}
