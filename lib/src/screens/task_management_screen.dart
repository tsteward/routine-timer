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
            child: _RightSettingsAndDetails(background: color.withValues(alpha: 0.6)),
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

class _RightSettingsAndDetails extends StatefulWidget {
  const _RightSettingsAndDetails({required this.background});
  final Color background;

  @override
  State<_RightSettingsAndDetails> createState() => _RightSettingsAndDetailsState();
}

class _RightSettingsAndDetailsState extends State<_RightSettingsAndDetails> {
  late final TextEditingController _taskNameController;
  late final TextEditingController _taskDurationMinutesController;
  late final TextEditingController _breakDurationMinutesController;
  late TimeOfDay _startTimeOfDay;
  bool _breaksEnabledByDefault = true;

  int? _lastHydratedTaskIndex;

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController();
    _taskDurationMinutesController = TextEditingController();
    _breakDurationMinutesController = TextEditingController();
    final bloc = context.read<RoutineBloc>();
    _hydrateFromState(bloc.state);
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDurationMinutesController.dispose();
    _breakDurationMinutesController.dispose();
    super.dispose();
  }

  void _hydrateFromState(RoutineBlocState state) {
    final model = state.model;
    if (model == null) {
      _taskNameController.text = '';
      _taskDurationMinutesController.text = '';
      _breakDurationMinutesController.text = '5';
      _startTimeOfDay = TimeOfDay.now();
      _breaksEnabledByDefault = true;
      return;
    }

    final selectedIndex = model.currentTaskIndex;
    _lastHydratedTaskIndex = selectedIndex;
    if (selectedIndex >= 0 && selectedIndex < model.tasks.length) {
      final selected = model.tasks[selectedIndex];
      _taskNameController.text = selected.name;
      _taskDurationMinutesController.text = _minutesFromSeconds(selected.estimatedDuration).toString();
    } else {
      _taskNameController.text = '';
      _taskDurationMinutesController.text = '';
    }

    final start = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    _startTimeOfDay = TimeOfDay(hour: start.hour, minute: start.minute);
    _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
    _breakDurationMinutesController.text = _minutesFromSeconds(model.settings.defaultBreakDuration).toString();
  }

  int _minutesFromSeconds(int seconds) => (seconds / 60).round();
  int _secondsFromMinutesString(String value) {
    final minutes = int.tryParse(value.trim());
    if (minutes == null || minutes < 0) return 0;
    return minutes * 60;
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTimeOfDay);
    if (picked != null) {
      setState(() => _startTimeOfDay = picked);
    }
  }

  void _onCancel() {
    final bloc = context.read<RoutineBloc>();
    _hydrateFromState(bloc.state);
    setState(() {});
  }

  void _onSave() {
    final bloc = context.read<RoutineBloc>();
    final state = bloc.state;
    final model = state.model;
    if (model == null) return;

    // Update settings
    final currentStart = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    final newStart = DateTime(
      currentStart.year,
      currentStart.month,
      currentStart.day,
      _startTimeOfDay.hour,
      _startTimeOfDay.minute,
    );
    final newSettings = model.settings.copyWith(
      startTime: newStart.millisecondsSinceEpoch,
      breaksEnabledByDefault: _breaksEnabledByDefault,
      defaultBreakDuration: _secondsFromMinutesString(_breakDurationMinutesController.text),
    );
    bloc.add(UpdateSettings(newSettings));

    // Update task
    final updatedName = _taskNameController.text.trim();
    final updatedDurationSeconds = _secondsFromMinutesString(_taskDurationMinutesController.text);
    bloc.add(UpdateCurrentTask(name: updatedName.isEmpty ? null : updatedName, estimatedDuration: updatedDurationSeconds == 0 ? null : updatedDurationSeconds));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<RoutineBloc, RoutineBlocState>(
      listenWhen: (prev, curr) {
        final prevIndex = prev.model?.currentTaskIndex;
        final currIndex = curr.model?.currentTaskIndex;
        return prevIndex != currIndex;
      },
      listener: (context, state) {
        _hydrateFromState(state);
        setState(() {});
      },
      child: Container(
        color: widget.background,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Routine Settings', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Routine Start Time', style: theme.textTheme.titleMedium),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('start_time_button'),
                            onPressed: _pickStartTime,
                            icon: const Icon(Icons.schedule),
                            label: Text('${_startTimeOfDay.hour.toString().padLeft(2, '0')}:${_startTimeOfDay.minute.toString().padLeft(2, '0')}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        key: const ValueKey('breaks_enabled_switch'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable Breaks by Default'),
                        value: _breaksEnabledByDefault,
                        onChanged: (v) => setState(() => _breaksEnabledByDefault = v),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const ValueKey('break_duration_field'),
                        controller: _breakDurationMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Break Duration (minutes)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Task Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        key: const ValueKey('task_name_field'),
                        controller: _taskNameController,
                        decoration: const InputDecoration(
                          labelText: 'Task Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('task_duration_field'),
                        controller: _taskDurationMinutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Duration (minutes)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            key: const ValueKey('duplicate_button'),
                            onPressed: () => context.read<RoutineBloc>().add(const DuplicateCurrentTask()),
                            icon: const Icon(Icons.copy),
                            label: const Text('Duplicate'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            key: const ValueKey('delete_button'),
                            onPressed: () => context.read<RoutineBloc>().add(const DeleteCurrentTask()),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete Task'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(key: const ValueKey('cancel_button'), onPressed: _onCancel, child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    key: const ValueKey('save_button'),
                    onPressed: _onSave,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
