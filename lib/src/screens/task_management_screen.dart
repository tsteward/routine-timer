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
          // Right column: routine settings and task details
          Expanded(
            flex: 2,
            child: Container(
              color: color.withValues(alpha: 0.6),
              child: const _RightSettingsPanel(),
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

class _RightSettingsPanel extends StatefulWidget {
  const _RightSettingsPanel();

  @override
  State<_RightSettingsPanel> createState() => _RightSettingsPanelState();
}

class _RightSettingsPanelState extends State<_RightSettingsPanel> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDurationMinutesController =
      TextEditingController();
  final TextEditingController _breakDurationMinutesController =
      TextEditingController();

  bool _breaksEnabledByDefault = true;
  TimeOfDay _startTimeOfDay = const TimeOfDay(hour: 8, minute: 0);

  // Track last applied values to avoid clobbering user edits on rebuilds
  String? _lastTaskId;
  int? _lastTaskDurationSeconds;
  String? _lastTaskName;
  int? _lastSettingsStartTime;
  bool? _lastSettingsBreaksEnabled;
  int? _lastSettingsDefaultBreakSeconds;

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDurationMinutesController.dispose();
    _breakDurationMinutesController.dispose();
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

        // Populate settings controls if changed
        if (_lastSettingsStartTime != model.settings.startTime ||
            _lastSettingsBreaksEnabled !=
                model.settings.breaksEnabledByDefault ||
            _lastSettingsDefaultBreakSeconds !=
                model.settings.defaultBreakDuration) {
          final start = DateTime.fromMillisecondsSinceEpoch(
            model.settings.startTime,
          );
          _startTimeOfDay = TimeOfDay(hour: start.hour, minute: start.minute);
          _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
          _breakDurationMinutesController.text =
              (model.settings.defaultBreakDuration / 60).round().toString();
          _lastSettingsStartTime = model.settings.startTime;
          _lastSettingsBreaksEnabled = model.settings.breaksEnabledByDefault;
          _lastSettingsDefaultBreakSeconds =
              model.settings.defaultBreakDuration;
        }

        // Populate task details if selected task changes
        final task = model.tasks.isNotEmpty
            ? model.tasks[model.currentTaskIndex.clamp(
                0,
                model.tasks.length - 1,
              )]
            : null;
        if (task != null &&
            (_lastTaskId != task.id ||
                _lastTaskDurationSeconds != task.estimatedDuration ||
                _lastTaskName != task.name)) {
          _taskNameController.text = task.name;
          _taskDurationMinutesController.text = (task.estimatedDuration / 60)
              .round()
              .toString();
          _lastTaskId = task.id;
          _lastTaskDurationSeconds = task.estimatedDuration;
          _lastTaskName = task.name;
        }

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
              _buildStartTimePicker(context, theme),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Breaks by Default'),
                value: _breaksEnabledByDefault,
                onChanged: (v) {
                  setState(() => _breaksEnabledByDefault = v);
                },
              ),
              TextField(
                key: const Key('settings_break_duration_field'),
                controller: _breakDurationMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Break Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: const Key('settings_cancel_button'),
                    onPressed: () {
                      // Reset settings inputs to bloc state
                      _lastSettingsStartTime =
                          null; // force repopulate on rebuild
                      _lastTaskId = null; // also reset task inputs
                      setState(() {});
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    key: const Key('settings_save_button'),
                    onPressed: () {
                      final now = DateTime.fromMillisecondsSinceEpoch(
                        model.settings.startTime,
                      );
                      final updatedStart = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _startTimeOfDay.hour,
                        _startTimeOfDay.minute,
                      ).millisecondsSinceEpoch;
                      final breakMinutes =
                          int.tryParse(
                            _breakDurationMinutesController.text.trim(),
                          ) ??
                          (model.settings.defaultBreakDuration / 60).round();
                      final updatedSettings = model.settings.copyWith(
                        startTime: updatedStart,
                        breaksEnabledByDefault: _breaksEnabledByDefault,
                        defaultBreakDuration: breakMinutes * 60,
                      );
                      context.read<RoutineBloc>().add(
                        UpdateSettings(updatedSettings),
                      );

                      final newName = _taskNameController.text.trim();
                      final taskMinutes =
                          int.tryParse(
                            _taskDurationMinutesController.text.trim(),
                          ) ??
                          (task?.estimatedDuration ?? 0) ~/ 60;
                      context.read<RoutineBloc>().add(
                        UpdateSelectedTask(
                          name: newName.isEmpty ? task?.name : newName,
                          estimatedDuration: taskMinutes * 60,
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Changes saved')),
                      );
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Task Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('task_name_field'),
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('task_duration_field'),
                controller: _taskDurationMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('task_duplicate_button'),
                    onPressed: task == null
                        ? null
                        : () {
                            context.read<RoutineBloc>().add(
                              const DuplicateSelectedTask(),
                            );
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                  TextButton.icon(
                    key: const Key('task_delete_button'),
                    onPressed: task == null
                        ? null
                        : () {
                            context.read<RoutineBloc>().add(
                              const DeleteSelectedTask(),
                            );
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
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

  Widget _buildStartTimePicker(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Routine Start Time',
              border: OutlineInputBorder(),
            ),
            child: Text(
              '${_startTimeOfDay.hour.toString().padLeft(2, '0')}:${_startTimeOfDay.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _startTimeOfDay,
            );
            if (picked != null) {
              setState(() => _startTimeOfDay = picked);
            }
          },
          icon: const Icon(Icons.schedule),
          label: const Text('Pick Time'),
        ),
      ],
    );
  }
}
