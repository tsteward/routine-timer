import 'package:flutter/material.dart';
import '../models/routine_state.dart';
import '../router/app_router.dart';

class ScheduleHeader extends StatelessWidget {
  const ScheduleHeader({required this.routineState, super.key});

  final RoutineStateModel routineState;

  /// Calculate total expected elapsed time from routine start to current task
  int _calculateExpectedElapsed() {
    final currentIndex = routineState.currentTaskIndex;
    if (currentIndex < 0) return 0;

    int total = 0;

    // Sum estimated durations of all tasks up to (but not including) current task
    for (int i = 0; i < currentIndex; i++) {
      total += routineState.tasks[i].estimatedDuration;
    }

    // Add break durations for tasks already completed
    if (routineState.breaks != null) {
      for (
        int i = 0;
        i < currentIndex && i < routineState.breaks!.length;
        i++
      ) {
        if (routineState.breaks![i].isEnabled) {
          total += routineState.breaks![i].duration;
        }
      }
    }

    return total;
  }

  /// Calculate total actual elapsed time (sum of actual durations of completed tasks)
  int _calculateActualElapsed() {
    int total = 0;

    for (final task in routineState.tasks) {
      if (task.isCompleted && task.actualDuration != null) {
        total += task.actualDuration!;
      }
    }

    // Add break durations for breaks we've already taken
    if (routineState.breaks != null) {
      final currentIndex = routineState.currentTaskIndex;
      for (
        int i = 0;
        i < currentIndex && i < routineState.breaks!.length;
        i++
      ) {
        if (routineState.breaks![i].isEnabled &&
            routineState.tasks[i].isCompleted) {
          total += routineState.breaks![i].duration;
        }
      }
    }

    return total;
  }

  /// Calculate difference between expected and actual (positive = ahead, negative = behind)
  int _calculateDifference() {
    final expected = _calculateExpectedElapsed();
    final actual = _calculateActualElapsed();
    return expected - actual;
  }

  /// Calculate estimated completion time
  DateTime _calculateEstimatedCompletion() {
    final now = DateTime.now();

    // Calculate remaining time: sum of remaining tasks + breaks
    int remainingTime = 0;
    final currentIndex = routineState.currentTaskIndex;

    // Add remaining time for current task (if not on break)
    if (!routineState.isOnBreak &&
        currentIndex >= 0 &&
        currentIndex < routineState.tasks.length) {
      final currentTask = routineState.tasks[currentIndex];
      if (!currentTask.isCompleted) {
        remainingTime += currentTask.estimatedDuration;
      }
    }

    // Add time for all tasks after current
    for (int i = currentIndex + 1; i < routineState.tasks.length; i++) {
      if (!routineState.tasks[i].isCompleted) {
        remainingTime += routineState.tasks[i].estimatedDuration;
      }
    }

    // Add remaining break times
    if (routineState.breaks != null) {
      // If currently on break, add current break's remaining time
      if (routineState.isOnBreak && routineState.currentBreak != null) {
        remainingTime += routineState.currentBreak!.duration;
      }

      // Add breaks after current task
      for (int i = currentIndex; i < routineState.breaks!.length; i++) {
        if (routineState.breaks![i].isEnabled) {
          // Don't double-count current break
          if (routineState.isOnBreak && i == routineState.currentBreakIndex) {
            continue;
          }
          remainingTime += routineState.breaks![i].duration;
        }
      }
    }

    return now.add(Duration(seconds: remainingTime));
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final difference = _calculateDifference();
    final diffMinutes = (difference.abs() / 60).round();
    final estimatedCompletion = _calculateEstimatedCompletion();

    String statusText;
    Color statusColor;

    if (difference > 60) {
      // Ahead by more than 1 minute
      statusText = 'Ahead by $diffMinutes min';
      statusColor = Colors.green.shade700;
    } else if (difference < -60) {
      // Behind by more than 1 minute
      statusText = 'Behind by $diffMinutes min';
      statusColor = Colors.red.shade700;
    } else {
      // Within 1 minute - on track
      statusText = 'On track';
      statusColor = Colors.blue.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side: Schedule status card
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Est. Completion: ${_formatTime(estimatedCompletion)}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Right side: Settings gear icon
          IconButton(
            icon: const Icon(Icons.settings, size: 32),
            color: Colors.grey.shade700,
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.tasks);
            },
          ),
        ],
      ),
    );
  }
}
