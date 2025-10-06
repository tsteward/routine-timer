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
  bool _tempBreaksEnabled = true;
  DateTime _tempStartTime = DateTime.now();

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
    final theme = Theme.of(context);
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        // Update controllers when state changes
        final settings = model.settings;
        final currentTask =
            model.tasks.isNotEmpty &&
                model.currentTaskIndex < model.tasks.length
            ? model.tasks[model.currentTaskIndex]
            : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Routine Settings Section
              Text(
                'Routine Settings',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _RoutineSettingsSection(
                settings: settings,
                breakDurationController: _breakDurationController,
                tempBreaksEnabled: _tempBreaksEnabled,
                tempStartTime: _tempStartTime,
                onBreaksEnabledChanged: (value) {
                  setState(() {
                    _tempBreaksEnabled = value;
                  });
                },
                onStartTimeChanged: (value) {
                  setState(() {
                    _tempStartTime = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Task Details Section
              Text(
                'Task Details',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (currentTask != null)
                _TaskDetailsSection(
                  task: currentTask,
                  taskIndex: model.currentTaskIndex,
                  taskNameController: _taskNameController,
                  taskDurationController: _taskDurationController,
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No task selected'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RoutineSettingsSection extends StatefulWidget {
  const _RoutineSettingsSection({
    required this.settings,
    required this.breakDurationController,
    required this.tempBreaksEnabled,
    required this.tempStartTime,
    required this.onBreaksEnabledChanged,
    required this.onStartTimeChanged,
  });

  final RoutineSettingsModel settings;
  final TextEditingController breakDurationController;
  final bool tempBreaksEnabled;
  final DateTime tempStartTime;
  final ValueChanged<bool> onBreaksEnabledChanged;
  final ValueChanged<DateTime> onStartTimeChanged;

  @override
  State<_RoutineSettingsSection> createState() =>
      _RoutineSettingsSectionState();
}

class _RoutineSettingsSectionState extends State<_RoutineSettingsSection> {
  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void didUpdateWidget(_RoutineSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    final breakMinutes = (widget.settings.defaultBreakDuration / 60).round();
    widget.breakDurationController.text = breakMinutes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start Time Picker
            Text('Routine Start Time', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectTime(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      _formatTime(
                        DateTime.fromMillisecondsSinceEpoch(
                          widget.settings.startTime,
                        ),
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Enable Breaks Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Enable Breaks by Default',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: widget.tempBreaksEnabled,
                  onChanged: widget.onBreaksEnabledChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Break Duration
            Text(
              'Break Duration (minutes)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.breakDurationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter duration in minutes',
                suffixText: 'min',
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset to current settings
                      _updateControllers();
                      widget.onBreaksEnabledChanged(
                        widget.settings.breaksEnabledByDefault,
                      );
                      widget.onStartTimeChanged(
                        DateTime.fromMillisecondsSinceEpoch(
                          widget.settings.startTime,
                        ),
                      );
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _saveSettings(context),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final currentTime = DateTime.fromMillisecondsSinceEpoch(
      widget.settings.startTime,
    );
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentTime),
    );
    if (time != null) {
      final newDateTime = DateTime(
        currentTime.year,
        currentTime.month,
        currentTime.day,
        time.hour,
        time.minute,
      );
      widget.onStartTimeChanged(newDateTime);
    }
  }

  void _saveSettings(BuildContext context) {
    final breakMinutes = int.tryParse(widget.breakDurationController.text) ?? 0;
    final breakSeconds = breakMinutes * 60;

    final newSettings = widget.settings.copyWith(
      startTime: widget.tempStartTime.millisecondsSinceEpoch,
      breaksEnabledByDefault: widget.tempBreaksEnabled,
      defaultBreakDuration: breakSeconds,
    );

    context.read<RoutineBloc>().add(UpdateSettings(newSettings));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TaskDetailsSection extends StatefulWidget {
  const _TaskDetailsSection({
    required this.task,
    required this.taskIndex,
    required this.taskNameController,
    required this.taskDurationController,
  });

  final TaskModel task;
  final int taskIndex;
  final TextEditingController taskNameController;
  final TextEditingController taskDurationController;

  @override
  State<_TaskDetailsSection> createState() => _TaskDetailsSectionState();
}

class _TaskDetailsSectionState extends State<_TaskDetailsSection> {
  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void didUpdateWidget(_TaskDetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task != widget.task) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    widget.taskNameController.text = widget.task.name;
    final durationMinutes = (widget.task.estimatedDuration / 60).round();
    widget.taskDurationController.text = durationMinutes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Name
            Text('Task Name', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: widget.taskNameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter task name',
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (_) => _saveTask(context),
            ),
            const SizedBox(height: 16),

            // Estimated Duration
            Text(
              'Estimated Duration (minutes)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.taskDurationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter duration in minutes',
                suffixText: 'min',
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              onChanged: (_) => _saveTask(context),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _duplicateTask(context),
                    icon: const Icon(Icons.content_copy),
                    label: const Text('Duplicate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _deleteTask(context),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
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

  void _saveTask(BuildContext context) {
    final name = widget.taskNameController.text.trim();
    final durationMinutes =
        int.tryParse(widget.taskDurationController.text) ?? 0;
    final durationSeconds = durationMinutes * 60;

    if (name.isEmpty || durationSeconds <= 0) return;

    final updatedTask = widget.task.copyWith(
      name: name,
      estimatedDuration: durationSeconds,
    );

    context.read<RoutineBloc>().add(
      UpdateTask(index: widget.taskIndex, task: updatedTask),
    );
  }

  void _duplicateTask(BuildContext context) {
    context.read<RoutineBloc>().add(DuplicateTask(widget.taskIndex));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task duplicated')));
  }

  void _deleteTask(BuildContext context) {
    final bloc = context.read<RoutineBloc>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${widget.task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        bloc.add(DeleteTask(widget.taskIndex));
        messenger.showSnackBar(const SnackBar(content: Text('Task deleted')));
      }
    });
  }
}
