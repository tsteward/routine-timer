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
              color: color.withValues(alpha: 0.6),
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

class _SettingsDetailsColumn extends StatefulWidget {
  const _SettingsDetailsColumn();

  @override
  State<_SettingsDetailsColumn> createState() => _SettingsDetailsColumnState();
}

class _SettingsDetailsColumnState extends State<_SettingsDetailsColumn> {
  // Routine settings local form state
  TimeOfDay? _startTimeOfDay;
  bool _breaksEnabledByDefault = true;
  final TextEditingController _breakDurationMinutesController =
      TextEditingController();

  // Task details local form state
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDurationMinutesController =
      TextEditingController();

  int? _lastSyncedTaskIndex;

  @override
  void dispose() {
    _breakDurationMinutesController.dispose();
    _taskNameController.dispose();
    _taskDurationMinutesController.dispose();
    super.dispose();
  }

  void _syncFromState(RoutineBlocState state) {
    final model = state.model;
    if (model == null) return;

    // Sync routine settings
    final start = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    _startTimeOfDay = TimeOfDay(hour: start.hour, minute: start.minute);
    _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
    _breakDurationMinutesController.text =
        (model.settings.defaultBreakDuration / 60).round().toString();

    // Sync current task
    final index = model.currentTaskIndex;
    if (index < 0 || index >= model.tasks.length) {
      _taskNameController.text = '';
      _taskDurationMinutesController.text = '';
      _lastSyncedTaskIndex = null;
      return;
    }
    final task = model.tasks[index];
    _taskNameController.text = task.name;
    _taskDurationMinutesController.text =
        (task.estimatedDuration / 60).round().toString();
    _lastSyncedTaskIndex = index;
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final initial = _startTimeOfDay ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _startTimeOfDay = picked);
    }
  }

  void _handleCancel(RoutineBlocState state) {
    setState(() => _syncFromState(state));
  }

  void _handleSave(RoutineBlocState state) {
    final model = state.model;
    if (model == null) return;

    // Prepare updated settings
    final now = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    final time = _startTimeOfDay ?? TimeOfDay(hour: now.hour, minute: now.minute);
    final updatedStart = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final parsedBreakMinutes = int.tryParse(_breakDurationMinutesController.text.trim()) ?? 0;
    final updatedSettings = model.settings.copyWith(
      startTime: updatedStart.millisecondsSinceEpoch,
      breaksEnabledByDefault: _breaksEnabledByDefault,
      defaultBreakDuration: (parsedBreakMinutes * 60).clamp(0, 24 * 60 * 60),
    );

    // Prepare updated current task
    final parsedTaskMinutes = int.tryParse(_taskDurationMinutesController.text.trim()) ?? 0;
    context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));
    context.read<RoutineBloc>().add(
          UpdateCurrentTask(
            name: _taskNameController.text.trim(),
            estimatedDuration: (parsedTaskMinutes * 60).clamp(0, 24 * 60 * 60),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<RoutineBloc, RoutineBlocState>(
      listenWhen: (prev, curr) {
        // Resync when model first loads or when the selected task changes
        final prevIndex = prev.model?.currentTaskIndex;
        final currIndex = curr.model?.currentTaskIndex;
        return prev.model == null || prevIndex != currIndex;
      },
      listener: (context, state) {
        _syncFromState(state);
      },
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        // Ensure initial sync at first build after load
        if (_lastSyncedTaskIndex == null) {
          _syncFromState(state);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Routine Settings',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('settings-start-time-button'),
                      onPressed: () => _pickStartTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _startTimeOfDay == null
                            ? '--:--'
                            : '${_startTimeOfDay!.hour.toString().padLeft(2, '0')}:${_startTimeOfDay!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Enable Breaks by Default',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Switch(
                          key: const Key('settings-breaks-default-switch'),
                          value: _breaksEnabledByDefault,
                          onChanged: (v) => setState(() => _breaksEnabledByDefault = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('settings-break-duration-field'),
                controller: _breakDurationMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Break Duration (min)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    key: const Key('settings-cancel-button'),
                    onPressed: () => _handleCancel(state),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: const Key('settings-save-button'),
                    onPressed: () => _handleSave(state),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Task Details',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('task-name-field'),
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('task-duration-field'),
                controller: _taskDurationMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated Duration (min)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    key: const Key('task-duplicate-button'),
                    onPressed: model.tasks.isEmpty
                        ? null
                        : () => context.read<RoutineBloc>().add(const DuplicateSelectedTask()),
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    key: const Key('task-delete-button'),
                    onPressed: model.tasks.isEmpty
                        ? null
                        : () => context.read<RoutineBloc>().add(const DeleteSelectedTask()),
                    icon: Icon(Icons.delete, color: theme.colorScheme.error),
                    label: Text(
                      'Delete Task',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
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
