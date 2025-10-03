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
          // Right column: settings & details
          Expanded(
            flex: 2,
            child: Container(
              color: color.withOpacity(0.6),
              child: const _SettingsDetailsColumn(),
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
                            : theme.colorScheme.outline.withOpacity(0.2),
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

class _SettingsDetailsColumn extends StatefulWidget {
  const _SettingsDetailsColumn();

  @override
  State<_SettingsDetailsColumn> createState() => _SettingsDetailsColumnState();
}

class _SettingsDetailsColumnState extends State<_SettingsDetailsColumn> {
  // Routine Settings controllers/state
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _breakDurationMinController =
      TextEditingController();
  bool _breaksEnabled = true;
  TimeOfDay? _selectedStartTime;

  // Task Details controllers
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDurationMinController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _breakDurationMinController.dispose();
    _taskNameController.dispose();
    _taskDurationMinController.dispose();
    super.dispose();
  }

  void _hydrateFromState(RoutineBlocState state) {
    final model = state.model;
    if (model == null) {
      _startTimeController.text = '';
      _breakDurationMinController.text = '';
      _taskNameController.text = '';
      _taskDurationMinController.text = '';
      _breaksEnabled = true;
      _selectedStartTime = null;
      return;
    }

    // Routine settings
    final start =
        DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    final startTod = TimeOfDay(hour: start.hour, minute: start.minute);
    _selectedStartTime = startTod;
    _startTimeController.text = _formatTimeHHmm(start);
    _breaksEnabled = model.settings.breaksEnabledByDefault;
    _breakDurationMinController.text =
        ((model.settings.defaultBreakDuration / 60).round()).toString();

    // Task details (selected)
    final idx = model.currentTaskIndex;
    if (idx >= 0 && idx < model.tasks.length) {
      final task = model.tasks[idx];
      _taskNameController.text = task.name;
      _taskDurationMinController.text =
          ((task.estimatedDuration / 60).round()).toString();
    } else {
      _taskNameController.text = '';
      _taskDurationMinController.text = '';
    }
  }

  String _formatTimeHHmm(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final initial = _selectedStartTime ?? const TimeOfDay(hour: 6, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        _startTimeController.text =
            picked.hour.toString().padLeft(2, '0') +
                ':' +
                picked.minute.toString().padLeft(2, '0');
      });
    }
  }

  void _onCancel(BuildContext context, RoutineStateModel? model) {
    if (!mounted) return;
    final state = context.read<RoutineBloc>().state;
    setState(() => _hydrateFromState(state));
  }

  void _onSave(BuildContext context, RoutineStateModel? model) {
    if (model == null) return;
    // Build new settings
    final originalSettings = model.settings;

    int newStartMillis = originalSettings.startTime;
    if (_selectedStartTime != null) {
      final startDate =
          DateTime.fromMillisecondsSinceEpoch(originalSettings.startTime);
      final newStart = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );
      newStartMillis = newStart.millisecondsSinceEpoch;
    }

    final parsedBreakMin = int.tryParse(_breakDurationMinController.text);
    final newBreakSeconds = parsedBreakMin != null && parsedBreakMin > 0
        ? parsedBreakMin * 60
        : originalSettings.defaultBreakDuration;

    final newSettings = originalSettings.copyWith(
      startTime: newStartMillis,
      breaksEnabledByDefault: _breaksEnabled,
      defaultBreakDuration: newBreakSeconds,
    );

    context.read<RoutineBloc>().add(UpdateSettings(newSettings));

    // Update task if selected
    final idx = model.currentTaskIndex;
    if (idx >= 0 && idx < model.tasks.length) {
      final parsedTaskMin = int.tryParse(_taskDurationMinController.text);
      final newTaskSeconds = parsedTaskMin != null && parsedTaskMin > 0
          ? parsedTaskMin * 60
          : model.tasks[idx].estimatedDuration;
      context.read<RoutineBloc>().add(
            UpdateTaskAtIndex(
              index: idx,
              name: _taskNameController.text.trim().isEmpty
                  ? model.tasks[idx].name
                  : _taskNameController.text.trim(),
              estimatedDurationSeconds: newTaskSeconds,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Keep controllers in sync with bloc
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      buildWhen: (prev, curr) => prev.model != curr.model,
      builder: (context, state) {
        _hydrateFromState(state);
        final model = state.model;
        return SingleChildScrollView(
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Routine Start Time',
                        hintText: 'HH:MM',
                        prefixIcon: Icon(Icons.schedule),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Pick time',
                    onPressed: () => _pickStartTime(context),
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Breaks by Default'),
                value: _breaksEnabled,
                onChanged: (v) => setState(() => _breaksEnabled = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _breakDurationMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Break Duration',
                  suffixText: 'min',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _onCancel(context, model),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: model == null
                        ? null
                        : () => _onSave(context, model),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                'Task Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _taskDurationMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated Duration',
                  suffixText: 'min',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: (model == null ||
                            model.currentTaskIndex < 0 ||
                            model.currentTaskIndex >= model.tasks.length)
                        ? null
                        : () => context.read<RoutineBloc>().add(
                              DuplicateTaskAtIndex(model.currentTaskIndex),
                            ),
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: (model == null ||
                            model.currentTaskIndex < 0 ||
                            model.currentTaskIndex >= model.tasks.length)
                        ? null
                        : () => context
                            .read<RoutineBloc>()
                            .add(DeleteTaskAtIndex(model.currentTaskIndex)),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Task'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
