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
        key: const Key('two-column-layout'),
        children: [
          // Left column placeholder (task list with breaks)
          Expanded(
            flex: 3,
            child: Container(color: color, child: const _TaskListColumn()),
          ),
          // Right column (settings & details)
          const Expanded(flex: 2, child: _RightSettingsColumn()),
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

class _RightSettingsColumn extends StatefulWidget {
  const _RightSettingsColumn();

  @override
  State<_RightSettingsColumn> createState() => _RightSettingsColumnState();
}

class _RightSettingsColumnState extends State<_RightSettingsColumn> {
  final _routineStartController = TextEditingController();
  final _breakDurationController = TextEditingController();
  final _taskNameController = TextEditingController();
  final _taskDurationController = TextEditingController();

  bool _breaksEnabledByDefault = true;

  RoutineStateModel? _lastModel;

  @override
  void dispose() {
    _routineStartController.dispose();
    _breakDurationController.dispose();
    _taskNameController.dispose();
    _taskDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.6,
    );
    return Container(
      color: surface,
      child: BlocConsumer<RoutineBloc, RoutineBlocState>(
        listenWhen: (prev, curr) => prev.model != curr.model,
        listener: (context, state) {
          final model = state.model;
          if (model == null) return;

          // Populate routine settings controls
          final start = DateTime.fromMillisecondsSinceEpoch(
            model.settings.startTime,
          );
          _routineStartController.text = _formatTimeForField(start);
          _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
          _breakDurationController.text =
              (model.settings.defaultBreakDuration / 60).round().toString();

          // Populate task details for selected index (if valid)
          final idx = model.currentTaskIndex;
          if (idx >= 0 && idx < model.tasks.length) {
            final task = model.tasks[idx];
            _taskNameController.text = task.name;
            _taskDurationController.text = (task.estimatedDuration / 60)
                .round()
                .toString();
          } else {
            _taskNameController.text = '';
            _taskDurationController.text = '';
          }

          _lastModel = model;
          setState(() {});
        },
        builder: (context, state) {
          final model = state.model;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Routine Settings', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _buildRoutineSettings(context, model),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Text('Task Details', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _buildTaskDetails(context, model),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoutineSettings(BuildContext context, RoutineStateModel? model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time picker field
        TextField(
          key: const Key('routine-start-time-field'),
          controller: _routineStartController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Routine Start Time',
            hintText: 'HH:mm',
            prefixIcon: Icon(Icons.schedule),
          ),
          onTap: () async {
            final current =
                model?.settings.startTime ??
                DateTime.now().millisecondsSinceEpoch;
            final initial = DateTime.fromMillisecondsSinceEpoch(current);
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: initial.hour,
                minute: initial.minute,
              ),
            );
            if (picked != null) {
              final now = DateTime.now();
              final newStart = DateTime(
                now.year,
                now.month,
                now.day,
                picked.hour,
                picked.minute,
              );
              _routineStartController.text = _formatTimeForField(newStart);
            }
          },
        ),
        const SizedBox(height: 12),
        // Breaks enabled toggle
        SwitchListTile(
          key: const Key('breaks-enabled-toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable Breaks by Default'),
          value: _breaksEnabledByDefault,
          onChanged: (v) => setState(() => _breaksEnabledByDefault = v),
        ),
        const SizedBox(height: 12),
        // Break duration in minutes
        TextField(
          key: const Key('default-break-duration-field'),
          controller: _breakDurationController,
          decoration: const InputDecoration(
            labelText: 'Break Duration (minutes)',
            prefixIcon: Icon(Icons.timer_outlined),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('cancel-settings'),
              onPressed: () {
                // Revert text fields to last known model
                if (_lastModel == null) return;
                final s = _lastModel!.settings;
                _breaksEnabledByDefault = s.breaksEnabledByDefault;
                _breakDurationController.text = (s.defaultBreakDuration / 60)
                    .round()
                    .toString();
                _routineStartController.text = _formatTimeForField(
                  DateTime.fromMillisecondsSinceEpoch(s.startTime),
                );
                setState(() {});
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('save-settings'),
              onPressed: () {
                if (_lastModel == null) return;
                final current = _lastModel!;

                // Parse inputs
                final durationMinutes =
                    int.tryParse(_breakDurationController.text.trim()) ??
                    (current.settings.defaultBreakDuration / 60).round();
                final start = _parseTimeFromField(
                  _routineStartController.text.trim(),
                );
                final startMs =
                    start?.millisecondsSinceEpoch ?? current.settings.startTime;

                final newSettings = current.settings.copyWith(
                  startTime: startMs,
                  breaksEnabledByDefault: _breaksEnabledByDefault,
                  defaultBreakDuration: durationMinutes * 60,
                );

                context.read<RoutineBloc>().add(UpdateSettings(newSettings));
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskDetails(BuildContext context, RoutineStateModel? model) {
    final theme = Theme.of(context);
    final selectedIndex = model?.currentTaskIndex ?? -1;
    final hasSelection =
        selectedIndex >= 0 && selectedIndex < (model?.tasks.length ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('task-name-field'),
          controller: _taskNameController,
          decoration: const InputDecoration(
            labelText: 'Task Name',
            prefixIcon: Icon(Icons.edit),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('task-duration-field'),
          controller: _taskDurationController,
          decoration: const InputDecoration(
            labelText: 'Estimated Duration (minutes)',
            prefixIcon: Icon(Icons.hourglass_bottom),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('duplicate-task'),
              onPressed: hasSelection
                  ? () {
                      context
                          .read<RoutineBloc>()
                          .add(DuplicateTaskAtIndex(selectedIndex));
                    }
                  : null,
              icon: const Icon(Icons.copy),
              label: const Text('Duplicate'),
            ),
            OutlinedButton.icon(
              key: const Key('delete-task'),
              onPressed: hasSelection
                  ? () {
                      context
                          .read<RoutineBloc>()
                          .add(DeleteTaskAtIndex(selectedIndex));
                    }
                  : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Task'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
            FilledButton(
              key: const Key('save-task'),
              onPressed: hasSelection
                  ? () {
                      final name = _taskNameController.text.trim();
                      final minutes = int.tryParse(
                        _taskDurationController.text.trim(),
                      );
                      context.read<RoutineBloc>().add(
                            UpdateTaskAtIndex(
                              index: selectedIndex,
                              name: name.isNotEmpty ? name : null,
                              estimatedDuration: minutes != null
                                  ? minutes * 60
                                  : null,
                            ),
                          );
                    }
                  : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimeForField(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  DateTime? _parseTimeFromField(String input) {
    final parts = input.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }
}
