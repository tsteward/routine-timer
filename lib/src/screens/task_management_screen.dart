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

class _SettingsAndDetailsColumn extends StatefulWidget {
  const _SettingsAndDetailsColumn();

  @override
  State<_SettingsAndDetailsColumn> createState() => _SettingsAndDetailsColumnState();
}

class _SettingsAndDetailsColumnState extends State<_SettingsAndDetailsColumn> {
  final _routineStartTimeController = TextEditingController();
  final _defaultBreakDurationController = TextEditingController();
  bool _breaksEnabledByDefault = true;

  final _taskNameController = TextEditingController();
  final _taskEstimatedMinutesController = TextEditingController();

  @override
  void dispose() {
    _routineStartTimeController.dispose();
    _defaultBreakDurationController.dispose();
    _taskNameController.dispose();
    _taskEstimatedMinutesController.dispose();
    super.dispose();
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

        // Populate controllers from state so the UI reflects selection
        final startTime = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
        _routineStartTimeController.text = _formatTimeHHmm(startTime);
        _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
        _defaultBreakDurationController.text =
            (model.settings.defaultBreakDuration / 60).round().toString();

        final selectedTask = model.tasks.isEmpty
            ? null
            : model.tasks[model.currentTaskIndex.clamp(0, model.tasks.length - 1)];
        _taskNameController.text = selectedTask?.name ?? '';
        _taskEstimatedMinutesController.text =
            selectedTask == null ? '' : ((selectedTask.estimatedDuration / 60).round()).toString();

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
                      key: const Key('routine-start-time-field'),
                      controller: _routineStartTimeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Routine Start Time',
                        hintText: 'HH:MM',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        final initial = TimeOfDay(hour: startTime.hour, minute: startTime.minute);
                        final picked = await showTimePicker(context: context, initialTime: initial);
                        if (picked != null) {
                          final now = DateTime.now();
                          final newStart = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            picked.hour,
                            picked.minute,
                          );
                          final updated = model.settings.copyWith(
                            startTime: newStart.millisecondsSinceEpoch,
                          );
                          // ignore: use_build_context_synchronously
                          context.read<RoutineBloc>().add(UpdateSettings(updated));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const Key('breaks-enabled-switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Breaks by Default'),
                value: _breaksEnabledByDefault,
                onChanged: (value) {
                  final updated = model.settings.copyWith(
                    breaksEnabledByDefault: value,
                  );
                  context.read<RoutineBloc>().add(UpdateSettings(updated));
                },
              ),
              TextField(
                key: const Key('default-break-duration-field'),
                controller: _defaultBreakDurationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Break Duration (min)',
                  prefixIcon: Icon(Icons.coffee),
                ),
                onChanged: (value) {
                  final minutes = int.tryParse(value) ?? 0;
                  final updated = model.settings.copyWith(
                    defaultBreakDuration: minutes * 60,
                  );
                  context.read<RoutineBloc>().add(UpdateSettings(updated));
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    key: const Key('settings-cancel-button'),
                    onPressed: () {
                      // Reset UI to current state values by rebuilding
                      setState(() {});
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: const Key('settings-save-button'),
                    onPressed: () {
                      final minutes = int.tryParse(_defaultBreakDurationController.text) ??
                          (model.settings.defaultBreakDuration / 60).round();
                      final now = DateTime.now();
                      final timeText = _routineStartTimeController.text;
                      final parts = timeText.split(':');
                      final hh = parts.length > 0 ? int.tryParse(parts[0]) ?? now.hour : now.hour;
                      final mm = parts.length > 1 ? int.tryParse(parts[1]) ?? now.minute : now.minute;
                      final newStart = DateTime(now.year, now.month, now.day, hh, mm);

                      final updated = model.settings.copyWith(
                        startTime: newStart.millisecondsSinceEpoch,
                        breaksEnabledByDefault: _breaksEnabledByDefault,
                        defaultBreakDuration: minutes * 60,
                      );
                      context.read<RoutineBloc>().add(UpdateSettings(updated));
                    },
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
                key: const Key('task-name-field'),
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  prefixIcon: Icon(Icons.edit),
                ),
                onChanged: (value) {
                  context.read<RoutineBloc>().add(UpdateSelectedTask(name: value));
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('task-estimated-duration-field'),
                controller: _taskEstimatedMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated Duration (min)',
                  prefixIcon: Icon(Icons.timer),
                ),
                onChanged: (value) {
                  final minutes = int.tryParse(value);
                  if (minutes != null) {
                    context.read<RoutineBloc>().add(
                          UpdateSelectedTask(
                            estimatedDurationSeconds: minutes * 60,
                          ),
                        );
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    key: const Key('duplicate-task-button'),
                    onPressed: selectedTask == null
                        ? null
                        : () {
                            context.read<RoutineBloc>().add(const DuplicateSelectedTask());
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    key: const Key('delete-task-button'),
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    onPressed: selectedTask == null
                        ? null
                        : () {
                            context.read<RoutineBloc>().add(const DeleteSelectedTask());
                          },
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
