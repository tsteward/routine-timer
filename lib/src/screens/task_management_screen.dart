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
  // Routine settings local state
  TimeOfDay? _startTime;
  bool _breaksEnabled = true;
  late final TextEditingController _breakMinutesController;

  // Task detail local state
  late final TextEditingController _taskNameController;
  late final TextEditingController _taskDurationMinutesController;
  String? _lastTaskIdLoaded;

  @override
  void initState() {
    super.initState();
    _breakMinutesController = TextEditingController();
    _taskNameController = TextEditingController();
    _taskDurationMinutesController = TextEditingController();
  }

  @override
  void dispose() {
    _breakMinutesController.dispose();
    _taskNameController.dispose();
    _taskDurationMinutesController.dispose();
    super.dispose();
  }

  void _loadFromModel(RoutineStateModel model) {
    final settings = model.settings;
    final dt = DateTime.fromMillisecondsSinceEpoch(settings.startTime);
    _startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    _breaksEnabled = settings.breaksEnabledByDefault;
    _breakMinutesController.text =
        ((settings.defaultBreakDuration / 60).round()).toString();

    if (model.tasks.isNotEmpty) {
      final task = model.tasks[model.currentTaskIndex];
      _lastTaskIdLoaded = task.id;
      _taskNameController.text = task.name;
      _taskDurationMinutesController.text =
          ((task.estimatedDuration / 60).round()).toString();
    } else {
      _lastTaskIdLoaded = null;
      _taskNameController.text = '';
      _taskDurationMinutesController.text = '';
    }
  }

  void _maybeLoadTaskOnSelectionChange(RoutineStateModel model) {
    if (model.tasks.isEmpty) {
      if (_lastTaskIdLoaded != null) {
        setState(() {
          _lastTaskIdLoaded = null;
          _taskNameController.text = '';
          _taskDurationMinutesController.text = '';
        });
      }
      return;
    }
    final currentTask = model.tasks[model.currentTaskIndex];
    if (_lastTaskIdLoaded != currentTask.id) {
      setState(() {
        _lastTaskIdLoaded = currentTask.id;
        _taskNameController.text = currentTask.name;
        _taskDurationMinutesController.text = ((
          currentTask.estimatedDuration / 60,
        ).round()).toString();
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final initial = _startTime ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  void _onCancel(RoutineStateModel model) {
    setState(() => _loadFromModel(model));
  }

  void _onSave(BuildContext context, RoutineStateModel model) {
    final bloc = context.read<RoutineBloc>();

    // Save Routine Settings
    final settings = model.settings;
    final existing = DateTime.fromMillisecondsSinceEpoch(settings.startTime);
    final time =
        _startTime ?? TimeOfDay(hour: existing.hour, minute: existing.minute);
    final newStart = DateTime(
      existing.year,
      existing.month,
      existing.day,
      time.hour,
      time.minute,
    ).millisecondsSinceEpoch;

    final breakMinutes = int.tryParse(_breakMinutesController.text.trim());
    final updatedSettings = settings.copyWith(
      startTime: newStart,
      breaksEnabledByDefault: _breaksEnabled,
      defaultBreakDuration: (breakMinutes != null && breakMinutes >= 0)
          ? breakMinutes * 60
          : settings.defaultBreakDuration,
    );
    bloc.add(UpdateSettings(updatedSettings));

    // Save Task Details for selected task (if any)
    if (model.tasks.isNotEmpty) {
      final index = model.currentTaskIndex;
      final current = model.tasks[index];
      final name = _taskNameController.text.trim();
      final mins = int.tryParse(_taskDurationMinutesController.text.trim());
      final updatedTask = current.copyWith(
        name: name.isNotEmpty ? name : current.name,
        estimatedDuration: (mins != null && mins > 0)
            ? mins * 60
            : current.estimatedDuration,
      );
      bloc.add(UpdateTaskAtIndex(index: index, updated: updatedTask));
    }
  }

  void _onDuplicate(BuildContext context, RoutineStateModel model) {
    if (model.tasks.isEmpty) return;
    context.read<RoutineBloc>().add(
      DuplicateTaskAtIndex(model.currentTaskIndex),
    );
  }

  void _onDelete(BuildContext context, RoutineStateModel model) {
    if (model.tasks.isEmpty) return;
    context.read<RoutineBloc>().add(DeleteTaskAtIndex(model.currentTaskIndex));
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
        // Initialize settings fields once when null
        _startTime ??= TimeOfDay(
          hour: DateTime.fromMillisecondsSinceEpoch(
            model.settings.startTime,
          ).hour,
          minute: DateTime.fromMillisecondsSinceEpoch(
            model.settings.startTime,
          ).minute,
        );
        // Keep breaks/default duration in sync initially; later user edits live in controllers
        if (_breakMinutesController.text.isEmpty) {
          _breaksEnabled = model.settings.breaksEnabledByDefault;
          _breakMinutesController.text =
              ((model.settings.defaultBreakDuration / 60).round()).toString();
        }
        // Update task fields on selection change
        _maybeLoadTaskOnSelectionChange(model);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Routine Settings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStartTimePicker(context, theme),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const ValueKey('toggle-breaks-default'),
                  title: const Text('Enable Breaks by Default'),
                  value: _breaksEnabled,
                  onChanged: (v) => setState(() => _breaksEnabled = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('input-break-duration-minutes'),
                  controller: _breakMinutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Break Duration (min)',
                    hintText: 'e.g. 2',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      key: const ValueKey('btn-cancel-settings'),
                      onPressed: () => _onCancel(model),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      key: const ValueKey('btn-save-settings'),
                      onPressed: () => _onSave(context, model),
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'Task Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (model.tasks.isEmpty)
                  Text('No tasks available', style: theme.textTheme.bodyMedium)
                else ...[
                  TextField(
                    key: const ValueKey('input-task-name'),
                    controller: _taskNameController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('input-task-duration-minutes'),
                    controller: _taskDurationMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Duration (min)',
                      hintText: 'e.g. 10',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('btn-duplicate-task'),
                        onPressed: () => _onDuplicate(context, model),
                        icon: const Icon(Icons.copy),
                        label: const Text('Duplicate'),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        key: const ValueKey('btn-delete-task'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () => _onDelete(context, model),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Task'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartTimePicker(BuildContext context, ThemeData theme) {
    final time = _startTime ?? const TimeOfDay(hour: 8, minute: 0);
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Routine Start Time'),
      subtitle: Text('$hh:$mm'),
      trailing: OutlinedButton(
        key: const ValueKey('btn-pick-time'),
        onPressed: () => _pickTime(context),
        child: const Text('Change'),
      ),
    );
  }
}
