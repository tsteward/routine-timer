import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../router/app_router.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_state.dart';
import '../models/routine_settings.dart';
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
  late TextEditingController _breakDurationController;
  late TimeOfDay _selectedStartTime;
  late bool _breaksEnabledByDefault;

  // Controllers for task details
  late TextEditingController _taskNameController;
  late TextEditingController _taskDurationController;

  // Track if we're editing
  bool _hasSettingsChanges = false;
  bool _hasTaskChanges = false;

  @override
  void initState() {
    super.initState();
    _breakDurationController = TextEditingController();
    _taskNameController = TextEditingController();
    _taskDurationController = TextEditingController();
    _selectedStartTime = TimeOfDay.now();
    _breaksEnabledByDefault = true;
  }

  @override
  void dispose() {
    _breakDurationController.dispose();
    _taskNameController.dispose();
    _taskDurationController.dispose();
    super.dispose();
  }

  void _loadSettingsFromModel(RoutineStateModel model) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    _selectedStartTime = TimeOfDay.fromDateTime(startTime);
    _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
    _breakDurationController.text = (model.settings.defaultBreakDuration ~/ 60).toString();
    _hasSettingsChanges = false;
  }

  void _loadTaskFromModel(RoutineStateModel model) {
    if (model.currentTaskIndex >= 0 && model.currentTaskIndex < model.tasks.length) {
      final task = model.tasks[model.currentTaskIndex];
      _taskNameController.text = task.name;
      _taskDurationController.text = (task.estimatedDuration ~/ 60).toString();
      _hasTaskChanges = false;
    }
  }

  void _saveSettings(BuildContext context, RoutineSettingsModel currentSettings) {
    final breakMinutes = int.tryParse(_breakDurationController.text) ?? 2;
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedStartTime.hour,
      _selectedStartTime.minute,
    );

    final updatedSettings = currentSettings.copyWith(
      startTime: selectedDateTime.millisecondsSinceEpoch,
      breaksEnabledByDefault: _breaksEnabledByDefault,
      defaultBreakDuration: breakMinutes * 60,
    );

    context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));
    setState(() => _hasSettingsChanges = false);
  }

  void _cancelSettingsChanges(RoutineStateModel model) {
    _loadSettingsFromModel(model);
    setState(() {});
  }

  void _saveTask(BuildContext context, RoutineStateModel model) {
    final durationMinutes = int.tryParse(_taskDurationController.text) ?? 5;
    final taskName = _taskNameController.text.trim();

    if (taskName.isEmpty) return;

    final currentTask = model.tasks[model.currentTaskIndex];
    final updatedTask = currentTask.copyWith(
      name: taskName,
      estimatedDuration: durationMinutes * 60,
    );

    context.read<RoutineBloc>().add(
      UpdateTask(index: model.currentTaskIndex, task: updatedTask),
    );
    setState(() => _hasTaskChanges = false);
  }

  void _duplicateTask(BuildContext context, RoutineStateModel model) {
    context.read<RoutineBloc>().add(DuplicateTask(model.currentTaskIndex));
  }

  void _deleteTask(BuildContext context, RoutineStateModel model) {
    context.read<RoutineBloc>().add(DeleteTask(model.currentTaskIndex));
  }

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

        // Load settings and task data when model changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_hasSettingsChanges) {
            _loadSettingsFromModel(model);
          }
          if (!_hasTaskChanges) {
            _loadTaskFromModel(model);
          }
        });

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
              _buildRoutineSettingsCard(theme, model),
              const SizedBox(height: 24),

              // Task Details Section
              Text(
                'Task Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTaskDetailsCard(theme, model),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutineSettingsCard(ThemeData theme, RoutineStateModel model) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Routine Start Time
            Text(
              'Routine Start Time',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedStartTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedStartTime = time;
                    _hasSettingsChanges = true;
                  });
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  suffixIcon: const Icon(Icons.access_time),
                ),
                child: Text(_selectedStartTime.format(context)),
              ),
            ),
            const SizedBox(height: 16),

            // Enable Breaks by Default
            SwitchListTile(
              title: Text(
                'Enable Breaks by Default',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: _breaksEnabledByDefault,
              onChanged: (value) {
                setState(() {
                  _breaksEnabledByDefault = value;
                  _hasSettingsChanges = true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // Break Duration
            Text(
              'Break Duration (minutes)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _breakDurationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                hintText: 'e.g., 5',
              ),
              onChanged: (_) => setState(() => _hasSettingsChanges = true),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _hasSettingsChanges
                      ? () => _cancelSettingsChanges(model)
                      : null,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _hasSettingsChanges
                      ? () => _saveSettings(context, model.settings)
                      : null,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailsCard(ThemeData theme, RoutineStateModel model) {
    final hasTask = model.tasks.isNotEmpty;
    if (!hasTask) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No task selected')),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Task Name
            Text(
              'Task Name',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                hintText: 'e.g., Morning Workout',
              ),
              onChanged: (_) => setState(() => _hasTaskChanges = true),
            ),
            const SizedBox(height: 16),

            // Estimated Duration
            Text(
              'Estimated Duration (minutes)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskDurationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                hintText: 'e.g., 20',
              ),
              onChanged: (_) => setState(() => _hasTaskChanges = true),
            ),
            const SizedBox(height: 24),

            // Save Task Button
            if (_hasTaskChanges)
              FilledButton(
                onPressed: () => _saveTask(context, model),
                child: const Text('Save Task'),
              ),
            if (_hasTaskChanges) const SizedBox(height: 12),

            // Duplicate Button
            OutlinedButton.icon(
              onPressed: () => _duplicateTask(context, model),
              icon: const Icon(Icons.content_copy),
              label: const Text('Duplicate'),
            ),
            const SizedBox(height: 8),

            // Delete Button
            OutlinedButton.icon(
              onPressed: model.tasks.length > 1
                  ? () => _deleteTask(context, model)
                  : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Task'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
