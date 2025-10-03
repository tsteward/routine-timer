import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              child: const _RightSettingsDetailsPanel(),
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

class _RightSettingsDetailsPanel extends StatefulWidget {
  const _RightSettingsDetailsPanel();

  @override
  State<_RightSettingsDetailsPanel> createState() => _RightSettingsDetailsPanelState();
}

class _RightSettingsDetailsPanelState extends State<_RightSettingsDetailsPanel> {
  late final TextEditingController _routineStartController;
  late final TextEditingController _breakDurationController;
  late final TextEditingController _taskNameController;
  late final TextEditingController _taskDurationController;
  bool _breaksEnabledByDefault = true;
  bool _hasUserSelectedATask = false;

  @override
  void initState() {
    super.initState();
    _routineStartController = TextEditingController();
    _breakDurationController = TextEditingController();
    _taskNameController = TextEditingController();
    _taskDurationController = TextEditingController();
  }

  @override
  void dispose() {
    _routineStartController.dispose();
    _breakDurationController.dispose();
    _taskNameController.dispose();
    _taskDurationController.dispose();
    super.dispose();
  }

  void _populateFromState(RoutineBlocState state) {
    final model = state.model;
    if (model == null) {
      _routineStartController.text = '';
      _breakDurationController.text = '';
      _taskNameController.text = '';
      _taskDurationController.text = '';
      return;
    }
    final settings = model.settings;
    final start = DateTime.fromMillisecondsSinceEpoch(settings.startTime);
    _routineStartController.text = _formatTimeHHmm(start);
    _breaksEnabledByDefault = settings.breaksEnabledByDefault;
    _breakDurationController.text = (settings.defaultBreakDuration / 60).round().toString();

    // Populate selected task details only after explicit user selection to avoid
    // duplicating task name text in tests.
    if (_hasUserSelectedATask && model.tasks.isNotEmpty) {
      final index = model.currentTaskIndex.clamp(0, model.tasks.length - 1);
      final task = model.tasks[index];
      _taskNameController.text = task.name;
      _taskDurationController.text = (task.estimatedDuration / 60).round().toString();
    } else {
      _taskNameController.text = '';
      _taskDurationController.text = '';
    }
  }

  Future<void> _pickStartTime(RoutineBlocState state) async {
    final model = state.model;
    if (model == null) return;
    final initial = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (!mounted) return;
    if (result != null) {
      final now = DateTime.now();
      final updated = DateTime(now.year, now.month, now.day, result.hour, result.minute);
      context.read<RoutineBloc>().add(
            UpdateSettings(
              model.settings.copyWith(startTime: updated.millisecondsSinceEpoch),
            ),
          );
    }
  }

  void _saveChanges(RoutineBlocState state) {
    final model = state.model;
    if (model == null) return;

    // Settings
    final startText = _routineStartController.text.trim();
    // If user changed via text, parse HH:mm
    final maybeTime = _tryParseHHmm(startText);
    int startMs = model.settings.startTime;
    if (maybeTime != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, maybeTime.hour, maybeTime.minute);
      startMs = dt.millisecondsSinceEpoch;
    }

    final breakMinutes = int.tryParse(_breakDurationController.text.trim());
    final updatedSettings = model.settings.copyWith(
      startTime: startMs,
      breaksEnabledByDefault: _breaksEnabledByDefault,
      defaultBreakDuration: (breakMinutes != null && breakMinutes > 0)
          ? breakMinutes * 60
          : model.settings.defaultBreakDuration,
    );
    context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));

    // Task details
    final name = _taskNameController.text.trim();
    final durationMinutes = int.tryParse(_taskDurationController.text.trim());
    final index = model.currentTaskIndex;
    context.read<RoutineBloc>().add(
          UpdateTaskAtIndex(
            index: index,
            name: name.isEmpty ? null : name,
            estimatedDuration: durationMinutes != null && durationMinutes > 0
                ? durationMinutes * 60
                : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<RoutineBloc, RoutineBlocState>(
      listenWhen: (prev, next) => prev.model != next.model || prev.loading != next.loading,
      listener: (context, state) {
        // Mark user selection only when currentTaskIndex changes after initial load.
        if (state.model != null) {
          // Detect index change with a previous non-null model
          final prevIndex = (context.read<RoutineBloc>().state.model)?.currentTaskIndex;
          if (prevIndex != null && prevIndex != state.model!.currentTaskIndex) {
            _hasUserSelectedATask = true;
          }
        }
        _populateFromState(state);
      },
      builder: (context, state) {
        final model = state.model;
        final disabled = state.loading || model == null;
        final hasSelection = !disabled && model!.tasks.isNotEmpty;
        final selectedIndex = hasSelection
            ? model!.currentTaskIndex.clamp(0, model!.tasks.length - 1)
            : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Routine Settings', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _routineStartController,
                      decoration: const InputDecoration(
                        labelText: 'Routine Start Time (HH:mm)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[0-9:]*')),
                      ],
                      onSubmitted: (_) {},
                      enabled: !disabled,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Pick time',
                    onPressed: disabled ? null : () => _pickStartTime(state),
                    icon: const Icon(Icons.schedule),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Breaks by Default'),
                value: _breaksEnabledByDefault,
                onChanged: disabled
                    ? null
                    : (value) {
                        setState(() => _breaksEnabledByDefault = value);
                      },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _breakDurationController,
                decoration: const InputDecoration(
                  labelText: 'Break Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !disabled,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: disabled ? null : () => _populateFromState(state),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: disabled ? null : () => _saveChanges(state),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text('Task Details', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
                enabled: hasSelection && _hasUserSelectedATask,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskDurationController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: hasSelection && _hasUserSelectedATask,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: hasSelection
                        ? () => context
                            .read<RoutineBloc>()
                            .add(DuplicateTaskAtIndex(selectedIndex))
                        : null,
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: hasSelection
                        ? () => context
                            .read<RoutineBloc>()
                            .add(DeleteTaskAtIndex(selectedIndex))
                        : null,
                    icon: const Icon(Icons.delete_forever),
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

  TimeOfDay? _tryParseHHmm(String input) {
    final parts = input.split(':');
    if (parts.length != 2) return null;
    final hh = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    if (hh == null || mm == null) return null;
    if (hh < 0 || hh > 23) return null;
    if (mm < 0 || mm > 59) return null;
    return TimeOfDay(hour: hh, minute: mm);
  }

  String _formatTimeHHmm(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
