import 'package:flutter/material.dart';
import '../models/routine_state.dart';

/// Header widget that displays schedule status and settings button.
class ScheduleHeader extends StatelessWidget {
  const ScheduleHeader({
    required this.routineState,
    required this.routineStartTime,
    required this.onSettingsTap,
    this.currentTime,
    this.currentTaskElapsedSeconds,
    super.key,
  });

  final RoutineStateModel routineState;
  final DateTime routineStartTime;
  final VoidCallback onSettingsTap;
  final DateTime? currentTime;
  final int? currentTaskElapsedSeconds;

  @override
  Widget build(BuildContext context) {
    final scheduleStatus = _calculateScheduleStatus();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Schedule status card
        Expanded(child: _buildScheduleStatusCard(scheduleStatus)),
        const SizedBox(width: 16),
        // Right side: Settings icon
        _buildSettingsButton(),
      ],
    );
  }

  Widget _buildScheduleStatusCard(ScheduleStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status line
          Text(
            status.displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Estimated completion time
          Text(
            'Est. Completion: ${status.estimatedCompletionTime}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.settings, color: Colors.white, size: 28),
        onPressed: onSettingsTap,
        tooltip: 'Settings',
      ),
    );
  }

  /// Calculates the current schedule status including ahead/behind status
  /// and estimated completion time.
  ScheduleStatus _calculateScheduleStatus() {
    final now = currentTime ?? DateTime.now();
    final scheduledStartTime = DateTime.fromMillisecondsSinceEpoch(
      routineState.settings.startTime,
    );

    // Calculate scheduled completion time (scheduled start + all tasks + breaks)
    int totalScheduledSeconds = 0;
    for (final task in routineState.tasks) {
      totalScheduledSeconds += task.estimatedDuration;
    }
    if (routineState.breaks != null) {
      for (final breakItem in routineState.breaks!) {
        if (breakItem.isEnabled) {
          totalScheduledSeconds += breakItem.duration;
        }
      }
    }
    final scheduledCompletionTime = scheduledStartTime.add(
      Duration(seconds: totalScheduledSeconds),
    );

    // Calculate estimated completion time
    // Current time + remaining time for all remaining tasks/breaks + remaining time for current task
    int remainingSeconds = 0;
    final currentTaskIndex = routineState.currentTaskIndex;

    // Add remaining time for current task (if any)
    if (currentTaskIndex >= 0 && currentTaskIndex < routineState.tasks.length) {
      final currentTask = routineState.tasks[currentTaskIndex];
      if (!currentTask.isCompleted && currentTaskElapsedSeconds != null) {
        // Calculate remaining time for current task
        // If elapsed time exceeds estimated, we're overtime
        final currentTaskRemaining =
            currentTask.estimatedDuration - currentTaskElapsedSeconds!;

        // If task is overtime (negative), we still count 0 remaining time
        // (we're already past the estimated time, just need to finish)
        // The behind status will be reflected in the variance calculation
        remainingSeconds += currentTaskRemaining > 0 ? currentTaskRemaining : 0;
      } else if (!currentTask.isCompleted) {
        // Fallback if elapsed time not provided
        remainingSeconds += currentTask.estimatedDuration;
      }

      // Add time for all remaining tasks after current
      for (int i = currentTaskIndex + 1; i < routineState.tasks.length; i++) {
        remainingSeconds += routineState.tasks[i].estimatedDuration;

        // Add break time if there's an enabled break after this task
        if (routineState.breaks != null &&
            i < routineState.breaks!.length &&
            routineState.breaks![i].isEnabled) {
          remainingSeconds += routineState.breaks![i].duration;
        }
      }

      // Add the break after current task if it exists and is enabled
      if (routineState.breaks != null &&
          currentTaskIndex < routineState.breaks!.length &&
          routineState.breaks![currentTaskIndex].isEnabled) {
        remainingSeconds += routineState.breaks![currentTaskIndex].duration;
      }
    }

    final estimatedCompletion = now.add(Duration(seconds: remainingSeconds));

    // Calculate variance (estimated completion - scheduled completion)
    // Negative = ahead, positive = behind
    final varianceSeconds = estimatedCompletion
        .difference(scheduledCompletionTime)
        .inSeconds;

    // Determine status text
    String statusText;
    if (varianceSeconds.abs() < 30) {
      // Within 30 seconds is considered "on track"
      statusText = 'On track';
    } else if (varianceSeconds < 0) {
      // Ahead of schedule
      final minutes = (varianceSeconds.abs() ~/ 60);
      final seconds = varianceSeconds.abs() % 60;
      if (minutes > 0) {
        statusText = 'Ahead by $minutes min';
        if (seconds > 0) {
          statusText += ' $seconds sec';
        }
      } else {
        statusText = 'Ahead by $seconds sec';
      }
    } else {
      // Behind schedule
      final minutes = varianceSeconds ~/ 60;
      final seconds = varianceSeconds % 60;
      if (minutes > 0) {
        statusText = 'Behind by $minutes min';
        if (seconds > 0) {
          statusText += ' $seconds sec';
        }
      } else {
        statusText = 'Behind by $seconds sec';
      }
    }

    final hour = estimatedCompletion.hour;
    final minute = estimatedCompletion.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final completionText =
        '$displayHour:${minute.toString().padLeft(2, '0')} $period';

    return ScheduleStatus(
      displayText: statusText,
      estimatedCompletionTime: completionText,
      varianceSeconds: varianceSeconds,
    );
  }
}

/// Data class representing the current schedule status.
class ScheduleStatus {
  const ScheduleStatus({
    required this.displayText,
    required this.estimatedCompletionTime,
    required this.varianceSeconds,
  });

  /// Display text for the status (e.g., "Ahead by 5 min", "On track")
  final String displayText;

  /// Formatted estimated completion time (e.g., "9:30 AM")
  final String estimatedCompletionTime;

  /// Variance in seconds (negative = ahead, positive = behind)
  final int varianceSeconds;
}
