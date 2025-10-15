import 'package:flutter/material.dart';
import '../models/routine_state.dart';

/// Header widget that displays schedule status and settings button.
class ScheduleHeader extends StatelessWidget {
  const ScheduleHeader({
    required this.routineState,
    required this.onSettingsTap,
    this.currentTime,
    super.key,
  });

  final RoutineStateModel routineState;
  final VoidCallback onSettingsTap;
  final DateTime? currentTime;

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

    // Calculate expected elapsed time from scheduled start time
    // This is how much time should have passed since the scheduled start
    final expectedElapsedSeconds = now
        .difference(scheduledStartTime)
        .inSeconds
        .clamp(0, 86400);

    final currentTaskIndex = routineState.currentTaskIndex;

    // Calculate actual elapsed time (sum of actual task durations)
    int actualElapsedSeconds = 0;
    for (
      int i = 0;
      i < currentTaskIndex && i < routineState.tasks.length;
      i++
    ) {
      final task = routineState.tasks[i];
      if (task.isCompleted && task.actualDuration != null) {
        actualElapsedSeconds += task.actualDuration!;
      } else {
        // If not completed yet, use estimated duration as fallback
        actualElapsedSeconds += task.estimatedDuration;
      }

      // Add break time if there's an enabled break after this task
      if (routineState.breaks != null &&
          i < routineState.breaks!.length &&
          routineState.breaks![i].isEnabled) {
        actualElapsedSeconds += routineState.breaks![i].duration;
      }
    }

    // Calculate variance (positive = ahead, negative = behind)
    // If actual > expected, user has completed more work than time passed (ahead)
    // If actual < expected, user has completed less work than time passed (behind)
    final varianceSeconds = actualElapsedSeconds - expectedElapsedSeconds;

    // Determine status text
    String statusText;
    if (varianceSeconds.abs() < 30) {
      // Within 30 seconds is considered "on track"
      statusText = 'On track';
    } else if (varianceSeconds > 0) {
      // Ahead of schedule (completed more work than time passed)
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
      // Behind schedule (completed less work than time passed)
      final minutes = varianceSeconds.abs() ~/ 60;
      final seconds = varianceSeconds.abs() % 60;
      if (minutes > 0) {
        statusText = 'Behind by $minutes min';
        if (seconds > 0) {
          statusText += ' $seconds sec';
        }
      } else {
        statusText = 'Behind by $seconds sec';
      }
    }

    // Calculate estimated completion time
    // Current time + remaining task time + remaining break time - variance
    int remainingSeconds = 0;

    // Add remaining time for current task (if any)
    if (currentTaskIndex >= 0 && currentTaskIndex < routineState.tasks.length) {
      final currentTask = routineState.tasks[currentTaskIndex];
      if (!currentTask.isCompleted) {
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

    // Adjust for current pace (if behind, add extra time; if ahead, subtract time)
    // This makes the estimate more realistic based on current performance
    // Variance: positive = ahead, negative = behind
    // If ahead, subtract variance (finish earlier); if behind, add variance (finish later)
    final adjustedRemainingSeconds = remainingSeconds - varianceSeconds;

    final estimatedCompletion = now.add(
      Duration(
        seconds: adjustedRemainingSeconds.clamp(0, 86400),
      ), // Max 24 hours
    );

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

  /// Variance in seconds (positive = ahead, negative = behind)
  final int varianceSeconds;
}
