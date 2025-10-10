import '../models/routine_state.dart';

/// Service for tracking schedule status and calculating completion times
class ScheduleTrackingService {
  /// Calculate schedule status based on routine progress
  ScheduleStatus calculateScheduleStatus(
    RoutineStateModel model,
    DateTime routineStartTime,
    int currentTaskElapsedSeconds,
  ) {
    final now = DateTime.now();
    final totalActualElapsed = now.difference(routineStartTime).inSeconds;

    // Calculate expected elapsed time based on completed tasks and current progress
    int expectedElapsedSeconds = 0;

    // Add time for completed tasks
    for (int i = 0; i < model.currentTaskIndex; i++) {
      final task = model.tasks[i];
      expectedElapsedSeconds += task.estimatedDuration;

      // Add break time if enabled (breaks come after tasks, so break i comes after task i)
      if (model.breaks != null &&
          i < model.breaks!.length &&
          model.breaks![i].isEnabled) {
        expectedElapsedSeconds += model.breaks![i].duration;
      }
    }

    // Add current task elapsed time
    expectedElapsedSeconds += currentTaskElapsedSeconds;

    final difference = totalActualElapsed - expectedElapsedSeconds;

    if (difference > 60) {
      // Behind by more than 1 minute
      return ScheduleStatus.behind(difference);
    } else if (difference < -60) {
      // Ahead by more than 1 minute
      return ScheduleStatus.ahead(difference.abs());
    } else {
      return ScheduleStatus.onTrack();
    }
  }

  /// Calculate estimated completion time
  DateTime calculateEstimatedCompletion(
    RoutineStateModel model,
    DateTime routineStartTime,
    int currentTaskElapsedSeconds,
  ) {
    final now = DateTime.now();

    // Calculate remaining time for current task
    int remainingSeconds = 0;

    if (model.currentTaskIndex < model.tasks.length) {
      final currentTask = model.tasks[model.currentTaskIndex];
      remainingSeconds =
          (currentTask.estimatedDuration - currentTaskElapsedSeconds)
              .clamp(0, double.infinity)
              .toInt();
    }

    // Add time for remaining tasks (after current)
    for (int i = model.currentTaskIndex + 1; i < model.tasks.length; i++) {
      final task = model.tasks[i];
      remainingSeconds += task.estimatedDuration;
    }

    // Add remaining break times (breaks are indexed the same as tasks, break i comes after task i)
    if (model.breaks != null) {
      // Add break after current task if enabled and current task is not the last
      if (model.currentTaskIndex < model.breaks!.length &&
          model.currentTaskIndex < model.tasks.length - 1 &&
          model.breaks![model.currentTaskIndex].isEnabled) {
        remainingSeconds += model.breaks![model.currentTaskIndex].duration;
      }

      // Add breaks after remaining tasks
      for (
        int i = model.currentTaskIndex + 1;
        i < model.breaks!.length && i < model.tasks.length - 1;
        i++
      ) {
        if (model.breaks![i].isEnabled) {
          remainingSeconds += model.breaks![i].duration;
        }
      }
    }

    return now.add(Duration(seconds: remainingSeconds));
  }

  /// Calculate total estimated routine duration
  int calculateTotalEstimatedDuration(RoutineStateModel model) {
    int totalSeconds = 0;

    for (final task in model.tasks) {
      totalSeconds += task.estimatedDuration;
    }

    if (model.breaks != null) {
      for (final breakModel in model.breaks!) {
        if (breakModel.isEnabled) {
          totalSeconds += breakModel.duration;
        }
      }
    }

    return totalSeconds;
  }
}

/// Represents the schedule status of the routine
class ScheduleStatus {
  const ScheduleStatus._({
    required this.type,
    required this.differenceInSeconds,
  });

  final ScheduleStatusType type;
  final int differenceInSeconds;

  factory ScheduleStatus.ahead(int seconds) => ScheduleStatus._(
    type: ScheduleStatusType.ahead,
    differenceInSeconds: seconds,
  );

  factory ScheduleStatus.behind(int seconds) => ScheduleStatus._(
    type: ScheduleStatusType.behind,
    differenceInSeconds: seconds,
  );

  factory ScheduleStatus.onTrack() => const ScheduleStatus._(
    type: ScheduleStatusType.onTrack,
    differenceInSeconds: 0,
  );

  String get displayText {
    switch (type) {
      case ScheduleStatusType.ahead:
        final minutes = differenceInSeconds ~/ 60;
        return 'Ahead by ${minutes}m';
      case ScheduleStatusType.behind:
        final minutes = differenceInSeconds ~/ 60;
        return 'Behind by ${minutes}m';
      case ScheduleStatusType.onTrack:
        return 'On track';
    }
  }
}

enum ScheduleStatusType { ahead, behind, onTrack }
