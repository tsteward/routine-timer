import '../models/routine_state.dart';

/// Service to track schedule progress and calculate time metrics.
class ScheduleTracker {
  const ScheduleTracker();

  /// Calculates the schedule status for the current routine state.
  ScheduleStatus calculateScheduleStatus(RoutineStateModel routine) {
    final currentIndex = routine.currentTaskIndex;

    if (currentIndex < 0 || routine.tasks.isEmpty) {
      return const ScheduleStatus(
        status: ScheduleStatusType.onTrack,
        varianceSeconds: 0,
        estimatedCompletionTime: null,
      );
    }

    // Calculate expected elapsed time (sum of estimated durations for completed tasks)
    int expectedElapsedSeconds = 0;
    for (int i = 0; i < currentIndex; i++) {
      expectedElapsedSeconds += routine.tasks[i].estimatedDuration;

      // Add break time if break exists and is enabled
      if (routine.breaks != null &&
          i < routine.breaks!.length &&
          routine.breaks![i].isEnabled) {
        expectedElapsedSeconds += routine.breaks![i].duration;
      }
    }

    // Calculate actual elapsed time (sum of actual durations for completed tasks)
    int actualElapsedSeconds = 0;
    for (int i = 0; i < currentIndex; i++) {
      final task = routine.tasks[i];
      actualElapsedSeconds += task.actualDuration ?? task.estimatedDuration;

      // Add break time if break exists and is enabled
      // Note: We assume breaks were taken at their full duration
      if (routine.breaks != null &&
          i < routine.breaks!.length &&
          routine.breaks![i].isEnabled) {
        actualElapsedSeconds += routine.breaks![i].duration;
      }
    }

    // Calculate variance (negative = ahead, positive = behind)
    final varianceSeconds = actualElapsedSeconds - expectedElapsedSeconds;

    // Determine status type
    final ScheduleStatusType statusType;
    if (varianceSeconds < -30) {
      // More than 30 seconds ahead
      statusType = ScheduleStatusType.ahead;
    } else if (varianceSeconds > 30) {
      // More than 30 seconds behind
      statusType = ScheduleStatusType.behind;
    } else {
      statusType = ScheduleStatusType.onTrack;
    }

    // Calculate estimated completion time
    final now = DateTime.now();

    // Sum remaining estimated time
    int remainingEstimatedSeconds = 0;
    for (int i = currentIndex; i < routine.tasks.length; i++) {
      remainingEstimatedSeconds += routine.tasks[i].estimatedDuration;

      // Add break time if break exists and is enabled
      if (routine.breaks != null &&
          i < routine.breaks!.length &&
          routine.breaks![i].isEnabled) {
        remainingEstimatedSeconds += routine.breaks![i].duration;
      }
    }

    // Adjust for variance (if behind, add extra time; if ahead, subtract)
    final adjustedRemainingSeconds =
        remainingEstimatedSeconds + varianceSeconds;
    final estimatedCompletionTime = now.add(
      Duration(seconds: adjustedRemainingSeconds),
    );

    return ScheduleStatus(
      status: statusType,
      varianceSeconds: varianceSeconds,
      estimatedCompletionTime: estimatedCompletionTime,
    );
  }
}

/// Types of schedule status.
enum ScheduleStatusType { ahead, onTrack, behind }

/// Schedule status information.
class ScheduleStatus {
  const ScheduleStatus({
    required this.status,
    required this.varianceSeconds,
    required this.estimatedCompletionTime,
  });

  /// Current schedule status type.
  final ScheduleStatusType status;

  /// Variance in seconds (negative = ahead, positive = behind).
  final int varianceSeconds;

  /// Estimated completion time based on current progress.
  final DateTime? estimatedCompletionTime;

  /// Returns absolute variance in seconds.
  int get absoluteVarianceSeconds => varianceSeconds.abs();

  /// Returns formatted variance string (e.g., "2 min", "30 sec").
  String get varianceString {
    final absSeconds = absoluteVarianceSeconds;
    if (absSeconds < 60) {
      return '$absSeconds sec';
    } else {
      final minutes = absSeconds ~/ 60;
      final seconds = absSeconds % 60;
      if (seconds == 0) {
        return '$minutes min';
      } else {
        return '$minutes min $seconds sec';
      }
    }
  }

  /// Returns formatted status text (e.g., "Ahead by 2 min").
  String get statusText {
    switch (status) {
      case ScheduleStatusType.ahead:
        return 'Ahead by $varianceString';
      case ScheduleStatusType.behind:
        return 'Behind by $varianceString';
      case ScheduleStatusType.onTrack:
        return 'On Track';
    }
  }

  /// Returns formatted completion time (e.g., "8:30 AM").
  String get completionTimeString {
    if (estimatedCompletionTime == null) return '--:--';

    final time = estimatedCompletionTime!;
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }
}
