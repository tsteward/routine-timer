import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../router/app_router.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_state.dart';
import '../models/routine_settings.dart';
import '../models/task.dart';
import '../models/break.dart';

class TaskManagementScreen extends StatelessWidget {
  const TaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Scaffold(
      appBar: AppBar(title: const Text('Task Management')),
      body: Row(
        children: [
          // Left column placeholder (task list with breaks)
          Expanded(
            flex: 3,
            child: Container(color: color, child: const _TaskListColumn()),
          ),
          // Right column (settings & details)
          Expanded(
            flex: 2,
            child: Container(
              color: color.withValues(alpha: 0.6),
              child: const _SettingsColumn(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final selected = await showMenu<String>(
            context: context,
            position: const RelativeRect.fromLTRB(1000, 0, 16, 0),
            items: const [
              PopupMenuItem(
                value: AppRoutes.preStart,
                child: Text('Pre-Start'),
              ),
              PopupMenuItem(value: AppRoutes.main, child: Text('Main Routine')),
              PopupMenuItem(
                value: AppRoutes.tasks,
                child: Text('Task Management'),
              ),
            ],
          );
          if (selected != null) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushNamed(selected);
          }
        },
        child: const Icon(Icons.navigation),
      ),
    );
  }
}

class _TaskListColumn extends StatelessWidget {
  const _TaskListColumn();

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
            itemBuilder: (context, index) {
              final task = model.tasks[index];
              final isSelected = index == model.currentTaskIndex;
              final startTime = startTimes[index];

              return Padding(
                key: ValueKey('task-${task.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      context.read<RoutineBloc>().add(SelectTask(index)),
                  child: Card(
                    elevation: isSelected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
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
                          _StartTimePill(text: _formatTimeHHmm(startTime)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDurationMinutes(
                                    task.estimatedDuration,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_handle,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Computes the absolute start DateTime for each task index, based on
  // routine start time, prior task durations, and enabled breaks.
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

  String _formatTimeHHmm(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatDurationMinutes(int seconds) {
    final minutes = (seconds / 60).round();
    return '$minutes min';
  }
}

class _StartTimePill extends StatelessWidget {
  const _StartTimePill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SettingsColumn extends StatefulWidget {
  const _SettingsColumn();

  @override
  State<_SettingsColumn> createState() => _SettingsColumnState();
}

class _SettingsColumnState extends State<_SettingsColumn> {
  // Local controllers for text fields
  late TextEditingController _breakDurationController;
  late TextEditingController _taskNameController;
  late TextEditingController _taskDurationController;

  @override
  void initState() {
    super.initState();
    _breakDurationController = TextEditingController();
    _taskNameController = TextEditingController();
    _taskDurationController = TextEditingController();
  }

  @override
  void dispose() {
    _breakDurationController.dispose();
    _taskNameController.dispose();
    _taskDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        // Update text controllers when state changes
        final selectedTask = model.currentTaskIndex < model.tasks.length
            ? model.tasks[model.currentTaskIndex]
            : null;

        // Update break duration from settings
        if (_breakDurationController.text !=
            (model.settings.defaultBreakDuration ~/ 60).toString()) {
          _breakDurationController.text =
              (model.settings.defaultBreakDuration ~/ 60).toString();
        }

        // Update task fields from selected task
        if (selectedTask != null) {
          if (_taskNameController.text != selectedTask.name) {
            _taskNameController.text = selectedTask.name;
          }
          if (_taskDurationController.text !=
              (selectedTask.estimatedDuration ~/ 60).toString()) {
            _taskDurationController.text =
                (selectedTask.estimatedDuration ~/ 60).toString();
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoutineSettingsSection(
                model: model,
                breakDurationController: _breakDurationController,
              ),
              const SizedBox(height: 24),
              _TaskDetailsSection(
                task: selectedTask,
                taskIndex: model.currentTaskIndex,
                taskNameController: _taskNameController,
                taskDurationController: _taskDurationController,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoutineSettingsSection extends StatelessWidget {
  const _RoutineSettingsSection({
    required this.model,
    required this.breakDurationController,
  });

  final RoutineStateModel model;
  final TextEditingController breakDurationController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Routine Start Time',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _TimePickerField(
              startTime: DateTime.fromMillisecondsSinceEpoch(
                model.settings.startTime,
              ),
              onTimeChanged: (newTime) {
                final updatedSettings = model.settings.copyWith(
                  startTime: newTime.millisecondsSinceEpoch,
                );
                context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Enable Breaks by Default',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Switch(
                  value: model.settings.breaksEnabledByDefault,
                  onChanged: (value) {
                    final updatedSettings = model.settings.copyWith(
                      breaksEnabledByDefault: value,
                    );
                    context
                        .read<RoutineBloc>()
                        .add(UpdateSettings(updatedSettings));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Break Duration (minutes)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: breakDurationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter break duration',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Reset to current values
                    breakDurationController.text =
                        (model.settings.defaultBreakDuration ~/ 60).toString();
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final breakMinutes =
                        int.tryParse(breakDurationController.text) ?? 0;
                    final updatedSettings = model.settings.copyWith(
                      defaultBreakDuration: breakMinutes * 60,
                    );
                    context
                        .read<RoutineBloc>()
                        .add(UpdateSettings(updatedSettings));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved')),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.startTime,
    required this.onTimeChanged,
  });

  final DateTime startTime;
  final ValueChanged<DateTime> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final timeOfDay = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(startTime),
        );
        if (timeOfDay != null) {
          final newTime = DateTime(
            startTime.year,
            startTime.month,
            startTime.day,
            timeOfDay.hour,
            timeOfDay.minute,
          );
          onTimeChanged(newTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              TimeOfDay.fromDateTime(startTime).format(context),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDetailsSection extends StatelessWidget {
  const _TaskDetailsSection({
    required this.task,
    required this.taskIndex,
    required this.taskNameController,
    required this.taskDurationController,
  });

  final TaskModel? task;
  final int taskIndex;
  final TextEditingController taskNameController;
  final TextEditingController taskDurationController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (task == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Select a task to edit',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Task Name',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: taskNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter task name',
              ),
              onChanged: (value) {
                // Auto-save on change
                if (value.isNotEmpty) {
                  final updatedTask = task.copyWith(name: value);
                  context.read<RoutineBloc>().add(
                        UpdateTask(index: taskIndex, task: updatedTask),
                      );
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Estimated Duration (minutes)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: taskDurationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter duration',
              ),
              onChanged: (value) {
                // Auto-save on change
                final minutes = int.tryParse(value);
                if (minutes != null && minutes > 0) {
                  final updatedTask =
                      task.copyWith(estimatedDuration: minutes * 60);
                  context.read<RoutineBloc>().add(
                        UpdateTask(index: taskIndex, task: updatedTask),
                      );
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<RoutineBloc>().add(DuplicateTask(taskIndex));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task duplicated')),
                      );
                    },
                    icon: const Icon(Icons.content_copy),
                    label: const Text('Duplicate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Task'),
                          content: const Text(
                            'Are you sure you want to delete this task?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ).then((confirmed) {
                        if (confirmed == true) {
                          context.read<RoutineBloc>().add(DeleteTask(taskIndex));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task deleted')),
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
