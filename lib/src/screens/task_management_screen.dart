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
              child: const _RightSettingsAndDetailsPanel(),
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

class _RightSettingsAndDetailsPanel extends StatefulWidget {
  const _RightSettingsAndDetailsPanel();

  @override
  State<_RightSettingsAndDetailsPanel> createState() =>
      _RightSettingsAndDetailsPanelState();
}

class _RightSettingsAndDetailsPanelState
    extends State<_RightSettingsAndDetailsPanel> {
  TimeOfDay? _startTimeOfDay;
  bool _breaksEnabledByDefault = true;
  final TextEditingController _breakDurationMinutesController =
      TextEditingController();

  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDurationMinutesController =
      TextEditingController();

  int? _lastSeenTaskIndex;

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

    // Sync settings fields
    final start = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    _startTimeOfDay ??= TimeOfDay(hour: start.hour, minute: start.minute);
    _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
    _breakDurationMinutesController.text =
        (model.settings.defaultBreakDuration / 60).round().toString();

    // Sync task detail fields when selection changes or first time
    final idx = model.currentTaskIndex;
    if (idx >= 0 && idx < model.tasks.length) {
      if (_lastSeenTaskIndex != idx || _taskNameController.text.isEmpty) {
        final t = model.tasks[idx];
        _taskNameController.text = t.name;
        _taskDurationMinutesController.text = (t.estimatedDuration / 60)
            .round()
            .toString();
        _lastSeenTaskIndex = idx;
      }
    } else {
      // Out of bounds selection: clear task fields
      _taskNameController.text = '';
      _taskDurationMinutesController.text = '';
      _lastSeenTaskIndex = null;
    }
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final initial = _startTimeOfDay ?? const TimeOfDay(hour: 6, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _startTimeOfDay = picked);
    }
  }

  void _resetToCurrentState(RoutineBlocState state) {
    setState(() {
      _startTimeOfDay = null; // forces resync from state
      _syncFromState(state);
    });
  }

  void _saveChanges(BuildContext context, RoutineBlocState state) {
    final model = state.model;
    if (model == null) return;

    // Build updated settings
    final originalStart = DateTime.fromMillisecondsSinceEpoch(
      model.settings.startTime,
    );
    final useTod =
        _startTimeOfDay ??
        TimeOfDay(hour: originalStart.hour, minute: originalStart.minute);
    final updatedStart = DateTime(
      originalStart.year,
      originalStart.month,
      originalStart.day,
      useTod.hour,
      useTod.minute,
    );

    final parsedBreakMinutes = int.tryParse(
      _breakDurationMinutesController.text.trim(),
    );
    final breakSeconds = (parsedBreakMinutes != null && parsedBreakMinutes >= 0)
        ? parsedBreakMinutes * 60
        : model.settings.defaultBreakDuration;

    final newSettings = model.settings.copyWith(
      startTime: updatedStart.millisecondsSinceEpoch,
      breaksEnabledByDefault: _breaksEnabledByDefault,
      defaultBreakDuration: breakSeconds,
    );
    context.read<RoutineBloc>().add(UpdateSettings(newSettings));

    // Build updated task fields if selection valid
    final idx = model.currentTaskIndex;
    if (idx >= 0 && idx < model.tasks.length) {
      final name = _taskNameController.text.trim();
      final parsedMinutes = int.tryParse(
        _taskDurationMinutesController.text.trim(),
      );
      final seconds = (parsedMinutes != null && parsedMinutes > 0)
          ? parsedMinutes * 60
          : model.tasks[idx].estimatedDuration;

      context.read<RoutineBloc>().add(
        UpdateTaskAtIndex(
          index: idx,
          name: name.isNotEmpty ? name : model.tasks[idx].name,
          estimatedDuration: seconds,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      buildWhen: (prev, next) => prev != next,
      builder: (context, state) {
        if (state.model == null) {
          return const Center(child: Text('No routine loaded'));
        }
        _syncFromState(state);
        final startLabel = _startTimeOfDay != null
            ? _formatTimeHHmm(_startTimeOfDay!)
            : _formatTimeHHmm(
                TimeOfDay(
                  hour: DateTime.fromMillisecondsSinceEpoch(
                    state.model!.settings.startTime,
                  ).hour,
                  minute: DateTime.fromMillisecondsSinceEpoch(
                    state.model!.settings.startTime,
                  ).minute,
                ),
              );

        final idx = state.model!.currentTaskIndex;
        final hasSelection = idx >= 0 && idx < state.model!.tasks.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Routine Settings', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('Routine Start Time')),
                          TextButton(
                            key: const ValueKey('pick-start-time'),
                            onPressed: () => _pickStartTime(context),
                            child: Text(startLabel),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Enable Breaks by Default'),
                        value: _breaksEnabledByDefault,
                        onChanged: (v) => setState(() {
                          _breaksEnabledByDefault = v;
                        }),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('break-duration-minutes'),
                        controller: _breakDurationMinutesController,
                        decoration: const InputDecoration(
                          labelText: 'Break Duration (minutes)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _resetToCurrentState(state),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => _saveChanges(context, state),
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Task Details', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: hasSelection
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              key: const ValueKey('task-name'),
                              controller: _taskNameController,
                              decoration: const InputDecoration(
                                labelText: 'Task Name',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              key: const ValueKey('task-duration-minutes'),
                              controller: _taskDurationMinutesController,
                              decoration: const InputDecoration(
                                labelText: 'Estimated Duration (minutes)',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  key: const ValueKey('duplicate-task'),
                                  onPressed: () => context
                                      .read<RoutineBloc>()
                                      .add(DuplicateTaskAtIndex(idx)),
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Duplicate'),
                                ),
                                FilledButton.tonalIcon(
                                  key: const ValueKey('delete-task'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.errorContainer,
                                  ),
                                  onPressed: () => context
                                      .read<RoutineBloc>()
                                      .add(DeleteTaskAtIndex(idx)),
                                  icon: Icon(
                                    Icons.delete,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  label: Text(
                                    'Delete Task',
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const Text('Select a task to edit details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeHHmm(TimeOfDay tod) {
    final hh = tod.hour.toString().padLeft(2, '0');
    final mm = tod.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
