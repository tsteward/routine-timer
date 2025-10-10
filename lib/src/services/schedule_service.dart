import '../models/routine_state.dart';
import '../models/schedule_status.dart';

/// Service for calculating schedule tracking and estimated completion times
class ScheduleService {
  /// Calculate schedule status based on routine state and current elapsed time
  static ScheduleStatus calculateScheduleStatus({
    required RoutineStateModel routine,
    required int currentTaskElapsedSeconds,
    required DateTime routineStartTime,
  }) {
    final currentTime = DateTime.now();

    // Calculate expected elapsed time based on planned schedule
    final expectedElapsedFromStart = _calculateExpectedElapsedTime(
      routine: routine,
      currentTaskElapsedSeconds: currentTaskElapsedSeconds,
    );

    // Calculate actual elapsed time for completed tasks + current task progress
    final actualElapsedForTasks = _calculateActualElapsedTime(
      routine: routine,
      currentTaskElapsedSeconds: currentTaskElapsedSeconds,
    );

    // Calculate difference in seconds (positive = ahead, negative = behind)
    final differenceSeconds = expectedElapsedFromStart - actualElapsedForTasks;
    final differenceMinutes = (differenceSeconds / 60).round();

    // Determine status type based on difference
    ScheduleStatusType statusType;
    if (differenceMinutes > 1) {
      statusType = ScheduleStatusType.ahead;
    } else if (differenceMinutes < -1) {
      statusType = ScheduleStatusType.behind;
    } else {
      statusType = ScheduleStatusType.onTrack;
    }

    // Calculate estimated completion time
    final estimatedCompletionTime = _calculateEstimatedCompletion(
      routine: routine,
      currentTaskElapsedSeconds: currentTaskElapsedSeconds,
      currentTime: currentTime,
    );

    // Calculate totals for display
    final totalExpected = _calculateTotalExpectedDuration(routine);
    final totalActual = _calculateTotalActualDuration(
      routine,
      currentTaskElapsedSeconds,
    );
    final totalRemaining = _calculateTotalRemainingDuration(
      routine,
      currentTaskElapsedSeconds,
    );

    return ScheduleStatus(
      type: statusType,
      minutesDifference: differenceMinutes.abs(),
      estimatedCompletionTime: estimatedCompletionTime,
      totalExpectedDuration: totalExpected,
      totalActualDuration: totalActual,
      totalRemainingDuration: totalRemaining,
    );
  }

  /// Calculate expected elapsed time based on task schedule up to current point
  static int _calculateExpectedElapsedTime({
    required RoutineStateModel routine,
    required int currentTaskElapsedSeconds,
  }) {
    int expectedElapsed = 0;

    // Add duration for all completed tasks
    for (int i = 0; i < routine.currentTaskIndex; i++) {
      expectedElapsed += routine.tasks[i].estimatedDuration;

      // Add break time after each task (except the last one)
      if (i < routine.tasks.length - 1 &&
          routine.breaks != null &&
          i < routine.breaks!.length) {
        final breakModel = routine.breaks![i];
        if (breakModel.isEnabled) {
          expectedElapsed += breakModel.duration;
        }
      }
    }

    // Add expected elapsed time for current task
    if (routine.currentTaskIndex < routine.tasks.length) {
      final currentTask = routine.tasks[routine.currentTaskIndex];
      expectedElapsed += currentTaskElapsedSeconds.clamp(
        0,
        currentTask.estimatedDuration,
      );
    }

    return expectedElapsed;
  }

  /// Calculate actual elapsed time for completed tasks + current task
  static int _calculateActualElapsedTime({
    required RoutineStateModel routine,
    required int currentTaskElapsedSeconds,
  }) {
    int actualElapsed = 0;

    // Add actual duration for all completed tasks
    for (int i = 0; i < routine.currentTaskIndex; i++) {
      final task = routine.tasks[i];
      actualElapsed += task.actualDuration ?? task.estimatedDuration;

      // Add break time after each completed task
      if (i < routine.tasks.length - 1 &&
          routine.breaks != null &&
          i < routine.breaks!.length) {
        final breakModel = routine.breaks![i];
        if (breakModel.isEnabled) {
          actualElapsed += breakModel.duration;
        }
      }
    }

    // Add current task elapsed time
    actualElapsed += currentTaskElapsedSeconds;

    return actualElapsed;
  }

  /// Calculate estimated completion time based on current progress and remaining tasks
  static DateTime _calculateEstimatedCompletion({
    required RoutineStateModel routine,
    required int currentTaskElapsedSeconds,
    required DateTime currentTime,
  }) {
    int remainingSeconds = 0;

    // Calculate remaining time for current task
    if (routine.currentTaskIndex < routine.tasks.length) {
      final currentTask = routine.tasks[routine.currentTaskIndex];
      final remainingForCurrentTask =
          (currentTask.estimatedDuration - currentTaskElapsedSeconds).clamp(
            0,
            currentTask.estimatedDuration,
          );
      remainingSeconds += remainingForCurrentTask;
    }

    // Add time for all remaining tasks
    for (int i = routine.currentTaskIndex + 1; i < routine.tasks.length; i++) {
      remainingSeconds += routine.tasks[i].estimatedDuration;

      // Add break time after each task (except the last one)
      if (i < routine.tasks.length - 1 &&
          routine.breaks != null &&
          i < routine.breaks!.length) {
        final breakModel = routine.breaks![i];
        if (breakModel.isEnabled) {
          remainingSeconds += breakModel.duration;
        }
      }
    }

    return currentTime.add(Duration(seconds: remainingSeconds));
  }

  /// Calculate total expected duration for all tasks and breaks
  static int _calculateTotalExpectedDuration(RoutineStateModel routine) {
    int total = 0;

    // Add all task durations
    for (final task in routine.tasks) {
      total += task.estimatedDuration;
    }

    // Add all enabled break durations
    if (routine.breaks != null) {
      for (final breakModel in routine.breaks!) {
        if (breakModel.isEnabled) {
          total += breakModel.duration;
        }
      }
    }

    return total;
  }

  /// Calculate total actual duration for completed tasks + current progress
  static int _calculateTotalActualDuration(
    RoutineStateModel routine,
    int currentTaskElapsedSeconds,
  ) {
    int total = 0;

    // Add actual duration for completed tasks
    for (int i = 0; i < routine.currentTaskIndex; i++) {
      final task = routine.tasks[i];
      total += task.actualDuration ?? task.estimatedDuration;
    }

    // Add current task elapsed time
    total += currentTaskElapsedSeconds;

    // Add breaks for completed tasks
    if (routine.breaks != null) {
      for (
        int i = 0;
        i < routine.currentTaskIndex && i < routine.breaks!.length;
        i++
      ) {
        final breakModel = routine.breaks![i];
        if (breakModel.isEnabled) {
          total += breakModel.duration;
        }
      }
    }

    return total;
  }

  /// Calculate total remaining duration for incomplete tasks and breaks
  static int _calculateTotalRemainingDuration(
    RoutineStateModel routine,
    int currentTaskElapsedSeconds,
  ) {
    int total = 0;

    // Add remaining time for current task
    if (routine.currentTaskIndex < routine.tasks.length) {
      final currentTask = routine.tasks[routine.currentTaskIndex];
      final remainingForCurrentTask =
          (currentTask.estimatedDuration - currentTaskElapsedSeconds).clamp(
            0,
            currentTask.estimatedDuration,
          );
      total += remainingForCurrentTask;
    }

    // Add time for all remaining tasks
    for (int i = routine.currentTaskIndex + 1; i < routine.tasks.length; i++) {
      total += routine.tasks[i].estimatedDuration;
    }

    // Add remaining break durations
    if (routine.breaks != null) {
      for (int i = routine.currentTaskIndex; i < routine.breaks!.length; i++) {
        final breakModel = routine.breaks![i];
        if (breakModel.isEnabled) {
          total += breakModel.duration;
        }
      }
    }

    return total;
  }
}
