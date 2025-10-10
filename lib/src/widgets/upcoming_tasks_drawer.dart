import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_state.dart';
import '../utils/time_formatter.dart';

/// A drawer widget that displays upcoming tasks and breaks
class UpcomingTasksDrawer extends StatelessWidget {
  const UpcomingTasksDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null || model.tasks.isEmpty) {
          return Drawer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Up Next',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('No tasks available'),
                  ],
                ),
              ),
            ),
          );
        }

        final upcomingItems = _buildUpcomingItems(model);

        return Drawer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Up Next',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (upcomingItems.isEmpty)
                    const Text(
                      'All tasks completed!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: upcomingItems.length,
                        itemBuilder: (context, index) {
                          final item = upcomingItems[index];
                          return _buildUpcomingItem(context, item);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a list of upcoming items (tasks and breaks) after the current position
  List<UpcomingItem> _buildUpcomingItems(RoutineStateModel model) {
    final items = <UpcomingItem>[];
    final startTimes = _computeTaskStartTimes(model);

    // Determine current position
    int currentIndex;

    if (model.isBreakActive && model.activeBreakIndex != null) {
      // Currently in a break, next item is the task after the break
      currentIndex = model.currentTaskIndex + 1;
    } else {
      // Currently in a task, next item starts from current task index
      currentIndex = model.currentTaskIndex;
      // If not on the current task itself, show from next task
      if (currentIndex < model.tasks.length) {
        currentIndex++;
      }
    }

    // Add remaining tasks and breaks
    for (int i = currentIndex; i < model.tasks.length; i++) {
      final task = model.tasks[i];
      final startTime = startTimes[i];

      // Add the task
      items.add(
        UpcomingItem.task(
          name: task.name,
          duration: task.estimatedDuration,
          startTime: startTime,
        ),
      );

      // Add break after this task (if not the last task and break exists)
      if (i < model.tasks.length - 1 &&
          model.breaks != null &&
          i < model.breaks!.length &&
          model.breaks![i].isEnabled) {
        final breakDuration = model.breaks![i].duration;
        final breakStartTime = startTime.add(
          Duration(seconds: task.estimatedDuration),
        );

        items.add(
          UpcomingItem.breakItem(
            duration: breakDuration,
            startTime: breakStartTime,
          ),
        );
      }
    }

    return items;
  }

  /// Computes start times for tasks (replicating logic from TaskListColumn)
  List<DateTime> _computeTaskStartTimes(RoutineStateModel model) {
    final start = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    final results = <DateTime>[];
    int accumulatedSeconds = 0;

    for (var i = 0; i < model.tasks.length; i++) {
      results.add(start.add(Duration(seconds: accumulatedSeconds)));
      accumulatedSeconds += model.tasks[i].estimatedDuration;

      if (model.breaks != null && i < model.breaks!.length) {
        final breakModel = model.breaks![i];
        if (breakModel.isEnabled) {
          accumulatedSeconds += breakModel.duration;
        }
      }
    }
    return results;
  }

  Widget _buildUpcomingItem(BuildContext context, UpcomingItem item) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isBreak
              ? AppTheme.green
              : theme.colorScheme.primary,
          radius: 16,
          child: Icon(
            item.isBreak ? Icons.coffee : Icons.task_alt,
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TimeFormatter.formatDurationMinutes(item.duration),
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            Text(
              'Starts at ${TimeFormatter.formatTimeHHmm(item.startTime)}',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

/// Data class representing an upcoming item (task or break)
class UpcomingItem {
  const UpcomingItem._({
    required this.name,
    required this.duration,
    required this.startTime,
    required this.isBreak,
  });

  factory UpcomingItem.task({
    required String name,
    required int duration,
    required DateTime startTime,
  }) {
    return UpcomingItem._(
      name: name,
      duration: duration,
      startTime: startTime,
      isBreak: false,
    );
  }

  factory UpcomingItem.breakItem({
    required int duration,
    required DateTime startTime,
  }) {
    return UpcomingItem._(
      name: 'Break',
      duration: duration,
      startTime: startTime,
      isBreak: true,
    );
  }

  final String name;
  final int duration;
  final DateTime startTime;
  final bool isBreak;
}
