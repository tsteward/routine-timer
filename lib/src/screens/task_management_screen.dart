import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../router/app_router.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_state.dart';
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
          // Right column placeholder (settings & details)
          Expanded(
            flex: 2,
            child: Container(
              color: color.withValues(alpha: 0.6),
              child: const _SettingsPanelColumn(),
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

class _SettingsPanelColumn extends StatefulWidget {
  const _SettingsPanelColumn();

  @override
  State<_SettingsPanelColumn> createState() => _SettingsPanelColumnState();
}

class _SettingsPanelColumnState extends State<_SettingsPanelColumn> {
  // Controllers for routine settings
  late TextEditingController _breakDurationController;
  late TimeOfDay _selectedStartTime;
  late bool _breaksEnabledByDefault;

  // Controllers for task details
  late TextEditingController _taskNameController;
  late TextEditingController _taskDurationController;

  // Track if settings have been modified
  bool _settingsModified = false;

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
    final startDateTime = DateTime.fromMillisecondsSinceEpoch(
      model.settings.startTime,
    );
    _selectedStartTime = TimeOfDay.fromDateTime(startDateTime);
    _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
    _breakDurationController.text = (model.settings.defaultBreakDuration ~/ 60)
        .toString();
    _settingsModified = false;
  }

  void _loadTaskDetailsFromModel(RoutineStateModel model) {
    if (model.tasks.isEmpty) return;
    final task = model.tasks[model.currentTaskIndex];
    _taskNameController.text = task.name;
    _taskDurationController.text = (task.estimatedDuration ~/ 60).toString();
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

        // Update controllers when model changes (only if not modified)
        if (!_settingsModified) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadSettingsFromModel(model);
            _loadTaskDetailsFromModel(model);
          });
        } else {
          // Still update task details when selection changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadTaskDetailsFromModel(model);
          });
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Routine Settings Section
              Text(
                'Routine Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildRoutineStartTimePicker(context, model),
              const SizedBox(height: 16),
              _buildBreaksEnabledToggle(context),
              const SizedBox(height: 16),
              _buildBreakDurationField(context),
              const SizedBox(height: 24),
              _buildSettingsButtons(context, model),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              // Task Details Section
              Text(
                'Task Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTaskNameField(context),
              const SizedBox(height: 16),
              _buildTaskDurationField(context),
              const SizedBox(height: 24),
              _buildTaskActionButtons(context, model),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutineStartTimePicker(
    BuildContext context,
    RoutineStateModel model,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Routine Start Time',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedStartTime,
            );
            if (time != null) {
              setState(() {
                _selectedStartTime = time;
                _settingsModified = true;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.access_time),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: Text(
              _selectedStartTime.format(context),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreaksEnabledToggle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Enable Breaks by Default',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Switch(
          value: _breaksEnabledByDefault,
          onChanged: (value) {
            setState(() {
              _breaksEnabledByDefault = value;
              _settingsModified = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBreakDurationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Break Duration (minutes)',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _breakDurationController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixText: 'min',
          ),
          onChanged: (value) {
            setState(() {
              _settingsModified = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSettingsButtons(BuildContext context, RoutineStateModel model) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _loadSettingsFromModel(model);
              });
            },
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _settingsModified
                ? () {
                    final breakMinutes =
                        int.tryParse(_breakDurationController.text) ?? 2;
                    final now = DateTime.now();
                    final startDateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      _selectedStartTime.hour,
                      _selectedStartTime.minute,
                    );

                    final newSettings = model.settings.copyWith(
                      startTime: startDateTime.millisecondsSinceEpoch,
                      breaksEnabledByDefault: _breaksEnabledByDefault,
                      defaultBreakDuration: breakMinutes * 60,
                    );

                    context.read<RoutineBloc>().add(
                      UpdateSettings(newSettings),
                    );
                    setState(() {
                      _settingsModified = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved')),
                    );
                  }
                : null,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskNameField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task Name', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _taskNameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter task name',
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDurationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Duration (minutes)',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _taskDurationController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixText: 'min',
          ),
        ),
      ],
    );
  }

  Widget _buildTaskActionButtons(
    BuildContext context,
    RoutineStateModel model,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            // Update the task
            final task = model.tasks[model.currentTaskIndex];
            final durationMinutes =
                int.tryParse(_taskDurationController.text) ?? 10;

            final updatedTask = task.copyWith(
              name: _taskNameController.text.trim().isNotEmpty
                  ? _taskNameController.text.trim()
                  : task.name,
              estimatedDuration: durationMinutes * 60,
            );

            context.read<RoutineBloc>().add(
              UpdateTask(index: model.currentTaskIndex, task: updatedTask),
            );

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Task updated')));
          },
          icon: const Icon(Icons.save),
          label: const Text('Save Task'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            context.read<RoutineBloc>().add(
              DuplicateTask(model.currentTaskIndex),
            );

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Task duplicated')));
          },
          icon: const Icon(Icons.content_copy),
          label: const Text('Duplicate'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: model.tasks.length > 1
              ? () async {
                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: const Text(
                        'Are you sure you want to delete this task?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    // ignore: use_build_context_synchronously
                    context.read<RoutineBloc>().add(
                      DeleteTask(model.currentTaskIndex),
                    );

                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task deleted')),
                    );
                  }
                }
              : null,
          icon: const Icon(Icons.delete),
          label: const Text('Delete Task'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}
