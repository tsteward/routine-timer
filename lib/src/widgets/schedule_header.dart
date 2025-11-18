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
    final savedStartTime = DateTime.fromMillisecondsSinceEpoch(
      routineState.settings.startTime,
    );

    DateTime normalizeScheduledStart() {
      final base = routineStartTime;
      var candidate = DateTime(
        base.year,
        base.month,
        base.day,
        savedStartTime.hour,
        savedStartTime.minute,
        savedStartTime.second,
      );

      final difference = base.difference(candidate);
      if (difference.inHours >= 12) {
        candidate = candidate.add(const Duration(days: 1));
      } else if (difference.inHours <= -12) {
        candidate = candidate.subtract(const Duration(days: 1));
      }
      return candidate;
    }

    final scheduledStartTime = normalizeScheduledStart();

    int sumScheduledSeconds() {
      final taskSeconds = routineState.tasks.fold<int>(
        0,
        (sum, task) => sum + task.estimatedDuration,
      );
      final breakSeconds =
          routineState.breaks?.fold<int>(
            0,
            (sum, item) => item.isEnabled ? sum + item.duration : sum,
          ) ??
          0;
      return taskSeconds + breakSeconds;
    }

    final scheduledCompletionTime = scheduledStartTime.add(
      Duration(seconds: sumScheduledSeconds()),
    );

    final tasks = routineState.tasks;
    final breaks = routineState.breaks;

    final toleranceSeconds = 30;
    final int activeElapsedSeconds = currentTaskElapsedSeconds ?? 0;

    int effectiveCurrentTaskIndex = routineState.currentTaskIndex;
    if (tasks.isEmpty) {
      effectiveCurrentTaskIndex = -1;
    } else {
      if (effectiveCurrentTaskIndex < 0) effectiveCurrentTaskIndex = 0;
      if (effectiveCurrentTaskIndex >= tasks.length) {
        effectiveCurrentTaskIndex = tasks.length - 1;
      }
    }

    int firstIncompleteTaskIndex = tasks.indexWhere(
      (task) => !task.isCompleted,
    );
    if (firstIncompleteTaskIndex == -1) {
      firstIncompleteTaskIndex = tasks.length;
    }

    int remainingSeconds = 0;

    if (!routineState.isCompleted && tasks.isEmpty) {
      remainingSeconds = 0;
    } else if (!routineState.isCompleted) {
      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        final bool isTaskCompleted = task.isCompleted;
        final bool isActiveTask =
            !routineState.isOnBreak &&
            !isTaskCompleted &&
            i == effectiveCurrentTaskIndex;

        if (isActiveTask) {
          final remainingForTask =
              task.estimatedDuration - activeElapsedSeconds;
          if (remainingForTask > 0) {
            remainingSeconds += remainingForTask;
          }
        } else if (!isTaskCompleted) {
          remainingSeconds += task.estimatedDuration;
        }

        if (breaks != null && i < breaks.length) {
          final breakModel = breaks[i];
          if (!breakModel.isEnabled) {
            continue;
          }

          final bool isBreakActive =
              routineState.isOnBreak &&
              (routineState.currentBreakIndex ?? -1) == i;
          final bool hasAdvancedPastBreak =
              (!routineState.isOnBreak && effectiveCurrentTaskIndex > i) ||
              tasks.skip(i + 1).any((t) => t.isCompleted) ||
              firstIncompleteTaskIndex > i + 1;

          if (isBreakActive) {
            final remainingForBreak =
                breakModel.duration - activeElapsedSeconds;
            if (remainingForBreak > 0) {
              remainingSeconds += remainingForBreak;
            }
          } else if (!hasAdvancedPastBreak) {
            remainingSeconds += breakModel.duration;
          }
        }
      }
    }

    if (remainingSeconds < 0) {
      remainingSeconds = 0;
    }

    bool hasStartedRoutine =
        tasks.any((task) => task.isCompleted) ||
        activeElapsedSeconds > 0 ||
        routineState.isOnBreak;

    DateTime estimatedCompletion;
    if (!hasStartedRoutine && now.isBefore(scheduledStartTime)) {
      estimatedCompletion = scheduledCompletionTime;
    } else if (remainingSeconds == 0 && routineState.completion != null) {
      estimatedCompletion = DateTime.fromMillisecondsSinceEpoch(
        routineState.completion!.completedAt,
      );
    } else {
      estimatedCompletion = now.add(Duration(seconds: remainingSeconds));
    }

    final varianceSeconds = estimatedCompletion
        .difference(scheduledCompletionTime)
        .inSeconds;

    String buildStatusText() {
      if (varianceSeconds.abs() < toleranceSeconds) {
        return routineState.isCompleted ? 'Completed on track' : 'On track';
      }

      final isAhead = varianceSeconds < 0;
      final absVariance = varianceSeconds.abs();
      final minutes = absVariance ~/ 60;
      final seconds = absVariance % 60;

      final buffer = StringBuffer(
        routineState.isCompleted
            ? (isAhead ? 'Completed ahead by ' : 'Completed behind by ')
            : (isAhead ? 'Ahead by ' : 'Behind by '),
      );

      if (minutes > 0) {
        buffer.write('$minutes min');
        if (seconds > 0) {
          buffer.write(' $seconds sec');
        }
      } else {
        buffer.write('$seconds sec');
      }

      return buffer.toString();
    }

    final hour = estimatedCompletion.hour;
    final minute = estimatedCompletion.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final completionText =
        '$displayHour:${minute.toString().padLeft(2, '0')} $period';

    return ScheduleStatus(
      displayText: buildStatusText(),
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
