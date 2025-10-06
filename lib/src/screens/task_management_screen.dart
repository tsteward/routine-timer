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
          // Right column (settings & details)
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
  final _taskNameController = TextEditingController();
  final _taskDurationController = TextEditingController();
  final _breakDurationController = TextEditingController();

  late TimeOfDay _routineStartTime;
  late bool _breaksEnabledByDefault;
  late int _breakDuration;

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
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        // Initialize settings from model
        final startDateTime = DateTime.fromMillisecondsSinceEpoch(
          model.settings.startTime,
        );
        _routineStartTime = TimeOfDay.fromDateTime(startDateTime);
        _breaksEnabledByDefault = model.settings.breaksEnabledByDefault;
        _breakDuration = model.settings.defaultBreakDuration;
        _breakDurationController.text = (_breakDuration ~/ 60).toString();

        // Get selected task
        final selectedTask = model.currentTaskIndex < model.tasks.length
            ? model.tasks[model.currentTaskIndex]
            : null;

        if (selectedTask != null) {
          _taskNameController.text = selectedTask.name;
          _taskDurationController.text = (selectedTask.estimatedDuration ~/ 60)
              .toString();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Routine Settings Section
              _buildSectionCard(
                theme: theme,
                title: 'Routine Settings',
                children: [
                  _buildTimePickerField(
                    theme: theme,
                    label: 'Routine Start Time',
                    time: _routineStartTime,
                    onTap: () => _selectTime(context),
                  ),
                  const SizedBox(height: 16),
                  _buildToggleField(
                    theme: theme,
                    label: 'Enable Breaks by Default',
                    value: _breaksEnabledByDefault,
                    onChanged: (value) {
                      setState(() {
                        _breaksEnabledByDefault = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    theme: theme,
                    controller: _breakDurationController,
                    label: 'Break Duration (minutes)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Reset to current values
                          setState(() {
                            final startDateTime =
                                DateTime.fromMillisecondsSinceEpoch(
                                  model.settings.startTime,
                                );
                            _routineStartTime = TimeOfDay.fromDateTime(
                              startDateTime,
                            );
                            _breaksEnabledByDefault =
                                model.settings.breaksEnabledByDefault;
                            _breakDuration =
                                model.settings.defaultBreakDuration;
                            _breakDurationController.text =
                                (_breakDuration ~/ 60).toString();
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => _saveSettings(context, model),
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Task Details Section
              if (selectedTask != null)
                _buildSectionCard(
                  theme: theme,
                  title: 'Task Details',
                  children: [
                    _buildTextField(
                      theme: theme,
                      controller: _taskNameController,
                      label: 'Task Name',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      theme: theme,
                      controller: _taskDurationController,
                      label: 'Estimated Duration (minutes)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            context.read<RoutineBloc>().add(
                              DuplicateTask(model.currentTaskIndex),
                            );
                          },
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Duplicate'),
                        ),
                        FilledButton(
                          onPressed: () => _saveTask(context, model),
                          child: const Text('Save Task'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: model.tasks.length > 1
                            ? () {
                                context.read<RoutineBloc>().add(
                                  DeleteTask(model.currentTaskIndex),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete Task'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
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

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTimePickerField({
    required ThemeData theme,
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(time.format(context), style: theme.textTheme.bodyLarge),
      ),
    );
  }

  Widget _buildToggleField({
    required ThemeData theme,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _routineStartTime,
    );
    if (picked != null) {
      setState(() {
        _routineStartTime = picked;
      });
    }
  }

  void _saveSettings(BuildContext context, RoutineStateModel model) {
    final breakDurationMinutes = int.tryParse(_breakDurationController.text);
    if (breakDurationMinutes == null || breakDurationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid break duration')),
      );
      return;
    }

    // Create a DateTime with today's date and the selected time
    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _routineStartTime.hour,
      _routineStartTime.minute,
    );

    final updatedSettings = model.settings.copyWith(
      startTime: startDateTime.millisecondsSinceEpoch,
      breaksEnabledByDefault: _breaksEnabledByDefault,
      defaultBreakDuration: breakDurationMinutes * 60,
    );

    context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  void _saveTask(BuildContext context, RoutineStateModel model) {
    final taskName = _taskNameController.text.trim();
    final durationMinutes = int.tryParse(_taskDurationController.text);

    if (taskName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a task name')));
      return;
    }

    if (durationMinutes == null || durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid duration')),
      );
      return;
    }

    context.read<RoutineBloc>().add(
      UpdateTask(
        index: model.currentTaskIndex,
        name: taskName,
        estimatedDuration: durationMinutes * 60,
      ),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task updated')));
  }
}
