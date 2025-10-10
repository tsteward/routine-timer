import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/routine_bloc.dart';
import '../dialogs/duration_picker_dialog.dart';
import '../models/break.dart';
import '../models/routine_state.dart';
import '../utils/time_formatter.dart';
import 'break_gap.dart';
import 'start_time_pill.dart';

/// A column displaying the reorderable list of tasks with their start times
class TaskListColumn extends StatelessWidget {
  const TaskListColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        final startTimes = _computeTaskStartTimes(model);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: model.tasks.length,
            onReorder: (oldIndex, newIndex) {
              // Flutter's ReorderableListView reports newIndex after removal; adjust when moving down.
              if (newIndex > oldIndex) newIndex -= 1;
              context.read<RoutineBloc>().add(
                ReorderTasks(oldIndex: oldIndex, newIndex: newIndex),
              );
            },
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) {
              // Enhanced proxy decorator to maintain visual consistency during drag
              return Material(
                elevation: 6.0,
                shadowColor: theme.shadowColor,
                borderRadius: BorderRadius.circular(12),
                child: Transform.scale(
                  scale: 1.02, // Slightly larger during drag
                  child: child,
                ),
              );
            },
            itemBuilder: (context, index) {
              final task = model.tasks[index];
              final isSelected = index == model.currentTaskIndex;
              final startTime = startTimes[index];

              return Column(
                // Use task ID as key instead of index to maintain widget identity during reorders
                key: ValueKey('task-column-${task.id}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          context.read<RoutineBloc>().add(SelectTask(index)),
                      child: Card(
                        // Use consistent key that won't change during reorder
                        key: ValueKey('task-card-${task.id}'),
                        elevation: isSelected ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              StartTimePill(
                                key: ValueKey('start-time-${task.id}'),
                                text: TimeFormatter.formatTimeHHmm(startTime),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.name,
                                      key: ValueKey('task-name-${task.id}'),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      TimeFormatter.formatDurationMinutes(
                                        task.estimatedDuration,
                                      ),
                                      key: ValueKey('task-duration-${task.id}'),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_handle,
                                  key: ValueKey('drag-handle-${task.id}'),
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Show break gap after this task (if not the last task)
                  if (index < model.tasks.length - 1 &&
                      model.breaks != null &&
                      index < model.breaks!.length)
                    BreakGap(
                      key: ValueKey('break-gap-${task.id}'),
                      isEnabled: model.breaks![index].isEnabled,
                      duration: model.breaks![index].duration,
                      onTap: () {
                        context.read<RoutineBloc>().add(
                          ToggleBreakAtIndex(index),
                        );
                      },
                      onLongPress: model.breaks![index].isEnabled
                          ? () => _editBreakDuration(context, index, model)
                          : null,
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Computes the absolute start DateTime for each task index, based on
  /// routine start time, prior task durations, and enabled breaks.
  List<DateTime> _computeTaskStartTimes(RoutineStateModel model) {
    final start = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    final results = <DateTime>[];
    int accumulatedSeconds = 0;

    for (var i = 0; i < model.tasks.length; i++) {
      results.add(start.add(Duration(seconds: accumulatedSeconds)));
      // Add this task's duration to accumulate for the next index
      accumulatedSeconds += model.tasks[i].estimatedDuration;
      // If there is a break after this task (i < breaks.length), and it is enabled, include it
      if (model.breaks != null && i < (model.breaks!.length)) {
        final BreakModel gap = model.breaks![i];
        if (gap.isEnabled) {
          accumulatedSeconds += gap.duration;
        }
      }
    }
    return results;
  }

  Future<void> _editBreakDuration(
    BuildContext context,
    int breakIndex,
    RoutineStateModel model,
  ) async {
    final currentBreak = model.breaks![breakIndex];
    final currentDuration = currentBreak.duration;
    final hours = currentDuration ~/ 3600;
    final minutes = (currentDuration % 3600) ~/ 60;

    final picked = await DurationPickerDialog.show(
      context: context,
      initialHours: hours,
      initialMinutes: minutes,
      title: currentBreak.isCustomized
          ? 'Break Duration (Customized)'
          : 'Break Duration (Default)',
    );

    if (picked != null && context.mounted) {
      if (picked <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duration must be greater than 0')),
        );
        return;
      }

      context.read<RoutineBloc>().add(
        UpdateBreakDuration(index: breakIndex, duration: picked),
      );
    }
  }
}
