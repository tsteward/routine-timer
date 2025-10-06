import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../router/app_router.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_state.dart';
import '../models/break.dart';
import '../models/task.dart';

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
              child: const _SettingsAndDetailsColumn(),
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

class _SettingsAndDetailsColumn extends StatefulWidget {
  const _SettingsAndDetailsColumn();

  @override
  State<_SettingsAndDetailsColumn> createState() =>
      _SettingsAndDetailsColumnState();
}

class _SettingsAndDetailsColumnState extends State<_SettingsAndDetailsColumn> {
  // Controllers for routine settings
  final _breakDurationController = TextEditingController();

  // Controllers for task details
  final _taskNameController = TextEditingController();
  final _taskDurationController = TextEditingController();

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

        // Update controllers when selection changes
        final selectedTask =
            model.currentTaskIndex >= 0 &&
                model.currentTaskIndex < model.tasks.length
            ? model.tasks[model.currentTaskIndex]
            : null;

        if (selectedTask != null) {
          _taskNameController.text = selectedTask.name;
          _taskDurationController.text = (selectedTask.estimatedDuration ~/ 60)
              .toString();
        }

        _breakDurationController.text =
            (model.settings.defaultBreakDuration ~/ 60).toString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRoutineSettingsSection(context, model),
              const SizedBox(height: 24),
              if (selectedTask != null)
                _buildTaskDetailsSection(context, model, selectedTask),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutineSettingsSection(
    BuildContext context,
    RoutineStateModel model,
  ) {
    final theme = Theme.of(context);
    final startTime = DateTime.fromMillisecondsSinceEpoch(
      model.settings.startTime,
    );

    return Card(
      elevation: 1,
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

            // Routine Start Time
            Text('Routine Start Time', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _selectStartTime(context, startTime),
              icon: const Icon(Icons.access_time),
              label: Text(_formatTimeHHmm(startTime)),
            ),
            const SizedBox(height: 16),

            // Enable Breaks by Default
            SwitchListTile(
              title: Text(
                'Enable Breaks by Default',
                style: theme.textTheme.titleSmall,
              ),
              value: model.settings.breaksEnabledByDefault,
              onChanged: (value) {
                final updatedSettings = model.settings.copyWith(
                  breaksEnabledByDefault: value,
                );
                context.read<RoutineBloc>().add(
                  UpdateSettings(updatedSettings),
                );
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Break Duration
            Text(
              'Default Break Duration (minutes)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _breakDurationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Minutes',
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      // Cancel - reset to current values
                      setState(() {
                        _breakDurationController.text =
                            (model.settings.defaultBreakDuration ~/ 60)
                                .toString();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FilledButton(
                    onPressed: () => _saveRoutineSettings(context, model),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailsSection(
    BuildContext context,
    RoutineStateModel model,
    TaskModel task,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
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

            // Task Name
            Text('Task Name', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _taskNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter task name',
              ),
            ),
            const SizedBox(height: 16),

            // Estimated Duration
            Text(
              'Estimated Duration (minutes)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskDurationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Minutes',
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<RoutineBloc>().add(
                        DuplicateTask(model.currentTaskIndex),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _deleteTask(context, model),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    child: const Text('Delete Task'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _saveTaskDetails(context, model, task),
                child: const Text('Save Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartTime(BuildContext context, DateTime current) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (time != null && context.mounted) {
      final model = context.read<RoutineBloc>().state.model;
      if (model == null) return;

      final newStartTime = DateTime(
        current.year,
        current.month,
        current.day,
        time.hour,
        time.minute,
      );

      final updatedSettings = model.settings.copyWith(
        startTime: newStartTime.millisecondsSinceEpoch,
      );
      context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));
    }
  }

  void _saveRoutineSettings(BuildContext context, RoutineStateModel model) {
    final breakMinutes = int.tryParse(_breakDurationController.text);
    if (breakMinutes == null || breakMinutes < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid break duration')));
      return;
    }

    final updatedSettings = model.settings.copyWith(
      defaultBreakDuration: breakMinutes * 60,
    );
    context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Routine settings saved')));
  }

  void _saveTaskDetails(
    BuildContext context,
    RoutineStateModel model,
    TaskModel task,
  ) {
    final taskName = _taskNameController.text.trim();
    final durationMinutes = int.tryParse(_taskDurationController.text);

    if (taskName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name cannot be empty')),
      );
      return;
    }

    if (durationMinutes == null || durationMinutes <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid duration')));
      return;
    }

    final updatedTask = task.copyWith(
      name: taskName,
      estimatedDuration: durationMinutes * 60,
    );

    context.read<RoutineBloc>().add(
      UpdateTask(index: model.currentTaskIndex, task: updatedTask),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task updated')));
  }

  void _deleteTask(BuildContext context, RoutineStateModel model) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<RoutineBloc>().add(DeleteTask(model.currentTaskIndex));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task deleted')));
      }
    });
  }

  String _formatTimeHHmm(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
