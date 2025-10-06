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
              child: const _SettingsPanel(),
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

class _SettingsPanel extends StatefulWidget {
  const _SettingsPanel();

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  // Controllers for text fields
  final _breakDurationController = TextEditingController();
  final _taskNameController = TextEditingController();
  final _taskDurationController = TextEditingController();

  // State for the form
  TimeOfDay? _selectedStartTime;
  bool _breaksEnabledByDefault = true;
  bool _hasUnsavedChanges = false;

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
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        // Update controllers when model changes (but not if user is editing)
        if (!_hasUnsavedChanges) {
          _updateControllersFromModel(model);
        }

        final selectedTask = model.currentTaskIndex < model.tasks.length
            ? model.tasks[model.currentTaskIndex]
            : null;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRoutineSettingsSection(context, model),
                      const SizedBox(height: 24),
                      _buildTaskDetailsSection(context, selectedTask, model.currentTaskIndex),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutineSettingsSection(BuildContext context, RoutineStateModel model) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine Settings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Routine Start Time
            _buildTimePickerField(context, model),
            const SizedBox(height: 16),
            
            // Enable Breaks by Default Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enable Breaks by Default',
                  style: theme.textTheme.bodyLarge,
                ),
                Switch(
                  value: _breaksEnabledByDefault,
                  onChanged: (value) {
                    setState(() {
                      _breaksEnabledByDefault = value;
                      _hasUnsavedChanges = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Break Duration
            TextField(
              controller: _breakDurationController,
              decoration: const InputDecoration(
                labelText: 'Break Duration (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _hasUnsavedChanges = true;
                });
              },
            ),
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _hasUnsavedChanges ? () {
                    setState(() {
                      _updateControllersFromModel(model);
                      _hasUnsavedChanges = false;
                    });
                  } : null,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _hasUnsavedChanges ? () => _saveRoutineSettings(context, model) : null,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDetailsSection(BuildContext context, TaskModel? selectedTask, int selectedIndex) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Details',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            if (selectedTask != null) ...[
              // Task Name
              TextField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _hasUnsavedChanges = true;
                  });
                },
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
                onChanged: (value) {
                  setState(() {
                    _hasUnsavedChanges = true;
                  });
                },
              ),
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _duplicateTask(context, selectedIndex),
                      icon: const Icon(Icons.copy),
                      label: const Text('Duplicate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteTask(context, selectedIndex),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Task'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_hasUnsavedChanges) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _saveTaskDetails(context, selectedTask, selectedIndex),
                    child: const Text('Save Task Changes'),
                  ),
                ),
              ],
            ] else ...[
              Text(
                'Select a task from the left to edit its details.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerField(BuildContext context, RoutineStateModel model) {
    final theme = Theme.of(context);
    final startDateTime = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    final displayTime = _selectedStartTime ?? TimeOfDay.fromDateTime(startDateTime);
    
    return InkWell(
      onTap: () => _showTimePicker(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Routine Start Time',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.access_time),
        ),
        child: Text(
          displayTime.format(context),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }

  void _updateControllersFromModel(RoutineStateModel model) {
    final selectedTask = model.currentTaskIndex < model.tasks.length
        ? model.tasks[model.currentTaskIndex]
        : null;

    // Update routine settings
    _selectedStartTime = TimeOfDay.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(model.settings.startTime)
    );
    _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
    _breakDurationController.text = (model.settings.defaultBreakDuration / 60).round().toString();

    // Update task details
    if (selectedTask != null) {
      _taskNameController.text = selectedTask.name;
      _taskDurationController.text = (selectedTask.estimatedDuration / 60).round().toString();
    } else {
      _taskNameController.clear();
      _taskDurationController.clear();
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    
    if (selectedTime != null) {
      setState(() {
        _selectedStartTime = selectedTime;
        _hasUnsavedChanges = true;
      });
    }
  }

  void _saveRoutineSettings(BuildContext context, RoutineStateModel model) {
    final breakDurationMinutes = int.tryParse(_breakDurationController.text) ?? 2;
    final now = DateTime.now();
    final selectedTime = _selectedStartTime ?? TimeOfDay.now();
    
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final updatedSettings = model.settings.copyWith(
      startTime: startDateTime.millisecondsSinceEpoch,
      breaksEnabledByDefault: _breaksEnabledByDefault,
      defaultBreakDuration: breakDurationMinutes * 60,
    );

    context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));
    
    setState(() {
      _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Routine settings saved!')),
    );
  }

  void _saveTaskDetails(BuildContext context, TaskModel selectedTask, int selectedIndex) {
    final taskName = _taskNameController.text.trim();
    final durationMinutes = int.tryParse(_taskDurationController.text) ?? 5;

    if (taskName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name cannot be empty')),
      );
      return;
    }

    final updatedTask = selectedTask.copyWith(
      name: taskName,
      estimatedDuration: durationMinutes * 60,
    );

    context.read<RoutineBloc>().add(UpdateTask(index: selectedIndex, task: updatedTask));
    
    setState(() {
      _hasUnsavedChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task details saved!')),
    );
  }

  void _duplicateTask(BuildContext context, int taskIndex) {
    context.read<RoutineBloc>().add(DuplicateTask(taskIndex));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task duplicated!')),
    );
  }

  void _deleteTask(BuildContext context, int taskIndex) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
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
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<RoutineBloc>().add(DeleteTask(taskIndex));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted!')),
        );
      }
    });
  }
}
