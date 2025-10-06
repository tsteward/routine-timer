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
  // Controllers for routine settings
  late TextEditingController _breakDurationController;
  late bool _breaksEnabledByDefault;
  late TimeOfDay _routineStartTime;

  // Controllers for task details
  late TextEditingController _taskNameController;
  late TextEditingController _taskDurationController;

  // Track original values for cancel functionality
  RoutineSettingsModel? _originalSettings;

  @override
  void initState() {
    super.initState();
    _breakDurationController = TextEditingController();
    _taskNameController = TextEditingController();
    _taskDurationController = TextEditingController();
    _breaksEnabledByDefault = true;
    _routineStartTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _breakDurationController.dispose();
    _taskNameController.dispose();
    _taskDurationController.dispose();
    super.dispose();
  }

  void _loadSettingsFromModel(RoutineStateModel model) {
    if (_originalSettings == null) {
      _originalSettings = model.settings;
    }
    final startDateTime =
        DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    _routineStartTime = TimeOfDay.fromDateTime(startDateTime);
    _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
    _breakDurationController.text =
        (model.settings.defaultBreakDuration ~/ 60).toString();
  }

  void _loadTaskDetails(TaskModel task) {
    _taskNameController.text = task.name;
    _taskDurationController.text = (task.estimatedDuration ~/ 60).toString();
  }

  void _saveSettings(BuildContext context, RoutineStateModel model) {
    final breakMinutes = int.tryParse(_breakDurationController.text) ?? 2;
    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _routineStartTime.hour,
      _routineStartTime.minute,
    );

    final newSettings = model.settings.copyWith(
      startTime: startDateTime.millisecondsSinceEpoch,
      breaksEnabledByDefault: _breaksEnabledByDefault,
      defaultBreakDuration: breakMinutes * 60,
    );

    context.read<RoutineBloc>().add(UpdateSettings(newSettings));
    _originalSettings = newSettings;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  void _cancelSettings(RoutineStateModel model) {
    if (_originalSettings != null) {
      _loadSettingsFromModel(
        model.copyWith(settings: _originalSettings!),
      );
      setState(() {});
    }
  }

  void _saveTaskDetails(
    BuildContext context,
    RoutineStateModel model,
    int taskIndex,
  ) {
    final task = model.tasks[taskIndex];
    final newName = _taskNameController.text.trim();
    final durationMinutes = int.tryParse(_taskDurationController.text) ?? 0;

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name cannot be empty')),
      );
      return;
    }

    if (durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be greater than 0')),
      );
      return;
    }

    final updatedTask = task.copyWith(
      name: newName,
      estimatedDuration: durationMinutes * 60,
    );

    context.read<RoutineBloc>().add(
          UpdateTask(index: taskIndex, task: updatedTask),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        _loadSettingsFromModel(model);

        final hasSelectedTask = model.currentTaskIndex >= 0 &&
            model.currentTaskIndex < model.tasks.length;
        final selectedTask =
            hasSelectedTask ? model.tasks[model.currentTaskIndex] : null;

        if (selectedTask != null) {
          _loadTaskDetails(selectedTask);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Routine Settings Section
              Text(
                'Routine Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildRoutineStartTimePicker(context, theme),
              const SizedBox(height: 16),
              _buildBreaksEnabledToggle(theme),
              const SizedBox(height: 16),
              _buildBreakDurationField(theme),
              const SizedBox(height: 16),
              _buildSettingsButtons(context, model, theme),
              const Divider(height: 48),
              // Task Details Section
              Text(
                'Task Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (selectedTask != null) ...[
                _buildTaskNameField(theme),
                const SizedBox(height: 16),
                _buildTaskDurationField(theme),
                const SizedBox(height: 16),
                _buildTaskButtons(context, model, theme),
              ] else
                Text(
                  'Select a task to edit details',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutineStartTimePicker(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Routine Start Time',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _routineStartTime,
            );
            if (picked != null) {
              setState(() {
                _routineStartTime = picked;
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  _routineStartTime.format(context),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreaksEnabledToggle(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Enable Breaks by Default',
          style: theme.textTheme.labelLarge,
        ),
        Switch(
          value: _breaksEnabledByDefault,
          onChanged: (value) {
            setState(() {
              _breaksEnabledByDefault = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBreakDurationField(ThemeData theme) {
    return TextField(
      controller: _breakDurationController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Break Duration (minutes)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSettingsButtons(
    BuildContext context,
    RoutineStateModel model,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _cancelSettings(model),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => _saveSettings(context, model),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskNameField(ThemeData theme) {
    return TextField(
      controller: _taskNameController,
      decoration: InputDecoration(
        labelText: 'Task Name',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTaskDurationField(ThemeData theme) {
    return TextField(
      controller: _taskDurationController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Estimated Duration (minutes)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTaskButtons(
    BuildContext context,
    RoutineStateModel model,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () => _saveTaskDetails(
            context,
            model,
            model.currentTaskIndex,
          ),
          child: const Text('Save Task'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            context.read<RoutineBloc>().add(
                  DuplicateTask(model.currentTaskIndex),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task duplicated')),
            );
          },
          icon: const Icon(Icons.content_copy),
          label: const Text('Duplicate'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            _showDeleteConfirmation(context, model);
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete Task'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, RoutineStateModel model) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<RoutineBloc>().add(
                    DeleteTask(model.currentTaskIndex),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
