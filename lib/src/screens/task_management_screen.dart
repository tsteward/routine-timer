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
          // Right column: settings & task details
          Expanded(
            flex: 2,
            child: Container(
              color: color.withValues(alpha: 0.6),
              child: const _RightSettingsAndDetails(),
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

class _RightSettingsAndDetails extends StatefulWidget {
  const _RightSettingsAndDetails();

  @override
  State<_RightSettingsAndDetails> createState() =>
      _RightSettingsAndDetailsState();
}

class _RightSettingsAndDetailsState extends State<_RightSettingsAndDetails> {
  final _taskNameController = TextEditingController();
  final _taskDurationController = TextEditingController();
  final _breakDurationController = TextEditingController();

  TimeOfDay? _startTimeOfDay;
  bool _breaksEnabledByDefault = true;

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDurationController.dispose();
    _breakDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<RoutineBloc, RoutineBlocState>(
      listenWhen: (prev, next) =>
          prev.model?.currentTaskIndex != next.model?.currentTaskIndex ||
          prev.model?.settings != next.model?.settings,
      listener: (context, state) {
        final model = state.model;
        if (model == null) return;
        // Populate task fields based on current selection
        final selected = model.tasks[model.currentTaskIndex];
        _taskNameController.text = selected.name;
        _taskDurationController.text = (selected.estimatedDuration / 60)
            .round()
            .toString();

        // Populate routine settings fields
        final start = DateTime.fromMillisecondsSinceEpoch(
          model.settings.startTime,
        );
        _startTimeOfDay = TimeOfDay(hour: start.hour, minute: start.minute);
        _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
        _breakDurationController.text =
            (model.settings.defaultBreakDuration / 60).round().toString();
      },
      builder: (context, state) {
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }
        final selected = model.tasks[model.currentTaskIndex];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Routine Settings', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Routine Start Time',
                child: InkWell(
                  onTap: () async {
                    final base =
                        _startTimeOfDay ?? const TimeOfDay(hour: 7, minute: 0);
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: base,
                    );
                    if (picked != null) {
                      setState(() => _startTimeOfDay = picked);
                      // Immediately persist to settings using today's date
                      final now = DateTime.now();
                      final start = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        picked.hour,
                        picked.minute,
                      ).millisecondsSinceEpoch;
                      final newSettings = model.settings.copyWith(
                        startTime: start,
                      );
                      context.read<RoutineBloc>().add(
                        UpdateSettings(newSettings),
                      );
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    child: Text(
                      _startTimeOfDay != null
                          ? _formatTimeOfDay(_startTimeOfDay!)
                          : _formatTimeOfDay(
                              TimeOfDay.fromDateTime(
                                DateTime.fromMillisecondsSinceEpoch(
                                  model.settings.startTime,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Breaks by Default'),
                value: _breaksEnabledByDefault,
                onChanged: (v) {
                  setState(() => _breaksEnabledByDefault = v);
                  final newSettings = model.settings.copyWith(
                    breaksEnabledByDefault: v,
                  );
                  context.read<RoutineBloc>().add(UpdateSettings(newSettings));
                },
              ),
              _LabeledField(
                label: 'Break Duration (min)',
                child: TextField(
                  controller: _breakDurationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.coffee),
                  ),
                  onChanged: (text) {
                    final mins = int.tryParse(text.trim());
                    if (mins != null) {
                      final newSettings = model.settings.copyWith(
                        defaultBreakDuration: mins * 60,
                      );
                      context.read<RoutineBloc>().add(
                        UpdateSettings(newSettings),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Save buttons removed; saving occurs automatically on change
              const Divider(height: 32),
              Text('Task Details', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Task Name',
                child: TextField(
                  controller: _taskNameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.edit),
                  ),
                  onChanged: (value) {
                    final updated = selected.copyWith(name: value);
                    context.read<RoutineBloc>().add(
                      UpdateTaskAtIndex(
                        index: model.currentTaskIndex,
                        task: updated,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _LabeledField(
                label: 'Estimated Duration (min)',
                child: TextField(
                  controller: _taskDurationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.timer),
                  ),
                  onChanged: (text) {
                    final mins = int.tryParse(text.trim());
                    if (mins != null) {
                      final updated = selected.copyWith(
                        estimatedDuration: mins * 60,
                      );
                      context.read<RoutineBloc>().add(
                        UpdateTaskAtIndex(
                          index: model.currentTaskIndex,
                          task: updated,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                    onPressed: () {
                      context.read<RoutineBloc>().add(
                        const DuplicateSelectedTask(),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Task'),
                    onPressed: () {
                      context.read<RoutineBloc>().add(
                        const DeleteSelectedTask(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
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
