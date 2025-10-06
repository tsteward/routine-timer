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
  TimeOfDay? _selectedTime;
  bool? _breaksEnabledByDefault;

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

        // Update controllers when state changes
        final selectedTask = model.currentTaskIndex < model.tasks.length
            ? model.tasks[model.currentTaskIndex]
            : null;

        // Initialize task controllers
        if (selectedTask != null) {
          if (_taskNameController.text != selectedTask.name) {
            _taskNameController.text = selectedTask.name;
          }
          final durationMinutes = (selectedTask.estimatedDuration / 60).round();
          if (_taskDurationController.text != durationMinutes.toString()) {
            _taskDurationController.text = durationMinutes.toString();
          }
        }

        // Initialize routine settings controllers
        if (_selectedTime == null) {
          final startTime = DateTime.fromMillisecondsSinceEpoch(
            model.settings.startTime,
          );
          _selectedTime = TimeOfDay.fromDateTime(startTime);
        }
        _breaksEnabledByDefault ??= model.settings.breaksEnabledByDefault;
        final breakMinutes = (model.settings.defaultBreakDuration / 60).round();
        if (_breakDurationController.text != breakMinutes.toString()) {
          _breakDurationController.text = breakMinutes.toString();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoutineSettingsSection(context, model),
              const SizedBox(height: 32),
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
            // Routine Start Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Routine Start Time'),
              subtitle: Text(_formatTimeOfDay(_selectedTime!)),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _pickStartTime(context),
              ),
            ),
            const Divider(),
            // Enable Breaks by Default
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Breaks by Default'),
              value: _breaksEnabledByDefault!,
              onChanged: (value) {
                setState(() {
                  _breaksEnabledByDefault = value;
                });
              },
            ),
            const Divider(),
            // Break Duration
            TextField(
              controller: _breakDurationController,
              decoration: const InputDecoration(
                labelText: 'Break Duration (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Cancel and Save buttons
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => _cancelSettingsChanges(model),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => _saveSettingsChanges(context, model),
                  child: const Text('Save'),
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
            TextField(
              controller: _taskNameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Estimated Duration
            TextField(
              controller: _taskDurationController,
              decoration: const InputDecoration(
                labelText: 'Estimated Duration (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // Duplicate button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _duplicateTask(context, model),
                icon: const Icon(Icons.content_copy),
                label: const Text('Duplicate'),
              ),
            ),
            const SizedBox(height: 8),
            // Delete button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: model.tasks.length > 1
                    ? () => _deleteTask(context, model)
                    : null,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Task'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Save task changes button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _saveTaskChanges(context, model, task),
                child: const Text('Save Task Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime!,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _cancelSettingsChanges(RoutineStateModel model) {
    setState(() {
      final startTime = DateTime.fromMillisecondsSinceEpoch(
        model.settings.startTime,
      );
      _selectedTime = TimeOfDay.fromDateTime(startTime);
      _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
      final breakMinutes = (model.settings.defaultBreakDuration / 60).round();
      _breakDurationController.text = breakMinutes.toString();
    });
  }

  void _saveSettingsChanges(BuildContext context, RoutineStateModel model) {
    final breakMinutes = int.tryParse(_breakDurationController.text) ?? 0;
    if (breakMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Break duration must be greater than 0')),
      );
      return;
    }

    // Create a DateTime from the selected time
    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final updatedSettings = model.settings.copyWith(
      startTime: startTime.millisecondsSinceEpoch,
      breaksEnabledByDefault: _breaksEnabledByDefault,
      defaultBreakDuration: breakMinutes * 60,
    );

    context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  void _saveTaskChanges(
    BuildContext context,
    RoutineStateModel model,
    TaskModel task,
  ) {
    final taskName = _taskNameController.text.trim();
    if (taskName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name cannot be empty')),
      );
      return;
    }

    final durationMinutes = int.tryParse(_taskDurationController.text) ?? 0;
    if (durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be greater than 0')),
      );
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
    ).showSnackBar(const SnackBar(content: Text('Task updated successfully')));
  }

  void _duplicateTask(BuildContext context, RoutineStateModel model) {
    context.read<RoutineBloc>().add(DuplicateTask(model.currentTaskIndex));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task duplicated successfully')),
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    RoutineStateModel model,
  ) async {
    if (model.tasks.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last task')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // ignore: use_build_context_synchronously
      context.read<RoutineBloc>().add(DeleteTask(model.currentTaskIndex));
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully')),
      );
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
