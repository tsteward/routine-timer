import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/routine_bloc.dart';
import '../dialogs/add_task_dialog.dart';
import '../models/routine_state.dart';
import '../utils/time_formatter.dart';

/// Bottom bar displaying total time, estimated finish time, and add task button
class TaskManagementBottomBar extends StatelessWidget {
  const TaskManagementBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null) {
          return const SizedBox.shrink();
        }

        final totalTime = _calculateTotalTime(model);
        final estimatedFinishTime = _calculateEstimatedFinishTime(model);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Time',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TimeFormatter.formatDurationHoursMinutes(totalTime),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Estimated Finish',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TimeFormatter.formatTimeHHmm(estimatedFinishTime),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddTaskDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _calculateTotalTime(RoutineStateModel model) {
    int total = 0;
    for (final task in model.tasks) {
      total += task.estimatedDuration;
    }
    if (model.breaks != null) {
      for (final breakItem in model.breaks!) {
        if (breakItem.isEnabled) {
          total += breakItem.duration;
        }
      }
    }
    return total;
  }

  DateTime _calculateEstimatedFinishTime(RoutineStateModel model) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(
      model.settings.startTime,
    );
    final totalSeconds = _calculateTotalTime(model);
    return startTime.add(Duration(seconds: totalSeconds));
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<RoutineBloc>(),
        child: const AddTaskDialog(),
      ),
    );
  }
}
