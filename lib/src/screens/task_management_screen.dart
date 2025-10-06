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
          // Right column: settings and details
          Expanded(
            flex: 2,
            child: Container(
              color: color.withValues(alpha: 0.6),
              child: const _RightPanel(),
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

class _RightPanel extends StatefulWidget {
  const _RightPanel();

  @override
  State<_RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<_RightPanel> {
  late final TextEditingController _taskNameController;
  late final TextEditingController _taskDurationMinutesController;
  late final TextEditingController _breakDurationMinutesController;
  TimeOfDay? _startTimeOfDay;
  bool _breaksEnabled = true;

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController();
    _taskDurationMinutesController = TextEditingController();
    _breakDurationMinutesController = TextEditingController();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDurationMinutesController.dispose();
    _breakDurationMinutesController.dispose();
    super.dispose();
  }

  void _syncFromState(RoutineStateModel model) {
    final currentIndex = model.currentTaskIndex;
    if (currentIndex >= 0 && currentIndex < model.tasks.length) {
      final t = model.tasks[currentIndex];
      _taskNameController.text = t.name;
      _taskDurationMinutesController.text = (t.estimatedDuration / 60).round().toString();
    }
    _breaksEnabled = model.settings.breaksEnabledByDefault;
    _breakDurationMinutesController.text = (model.settings.defaultBreakDuration / 60).round().toString();
    final start = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    _startTimeOfDay = TimeOfDay(hour: start.hour, minute: start.minute);
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTimeOfDay ?? TimeOfDay.now(),
    );
    if (selected != null) {
      setState(() {
        _startTimeOfDay = selected;
      });
    }
  }

  void _onSave(RoutineStateModel model) {
    final currentIndex = model.currentTaskIndex;
    if (currentIndex >= 0 && currentIndex < model.tasks.length) {
      final name = _taskNameController.text.trim();
      final minsRaw = int.tryParse(_taskDurationMinutesController.text.trim()) ?? 0;
      final mins = minsRaw < 0
          ? 0
          : (minsRaw > 24 * 60
              ? 24 * 60
              : minsRaw);
      context.read<RoutineBloc>().add(
            UpdateSelectedTask(
              name: name.isEmpty ? model.tasks[currentIndex].name : name,
              estimatedDurationSeconds: mins * 60,
            ),
          );
    }

    // Update settings
    final int rawBreakMins = int.tryParse(_breakDurationMinutesController.text.trim()) ??
        (model.settings.defaultBreakDuration / 60).round();
    final int breakMins = rawBreakMins < 0
        ? 0
        : (rawBreakMins > 24 * 60
            ? 24 * 60
            : rawBreakMins);

    final currentStart = DateTime.fromMillisecondsSinceEpoch(model.settings.startTime);
    final TimeOfDay tod = _startTimeOfDay ?? TimeOfDay(hour: currentStart.hour, minute: currentStart.minute);
    final normalizedStart = DateTime(
      currentStart.year,
      currentStart.month,
      currentStart.day,
      tod.hour,
      tod.minute,
    ).millisecondsSinceEpoch;

    final newSettings = model.settings.copyWith(
      startTime: normalizedStart,
      breaksEnabledByDefault: _breaksEnabled,
      defaultBreakDuration: breakMins * 60,
    );
    context.read<RoutineBloc>().add(UpdateSettings(newSettings));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      buildWhen: (p, n) => p.model != n.model || p.loading != n.loading,
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        // Ensure local controllers reflect latest state
        _syncFromState(model);

        final currentIndex = model.currentTaskIndex;
        final hasSelection = currentIndex >= 0 && currentIndex < model.tasks.length;
        final selectedTask = hasSelection ? model.tasks[currentIndex] : null;

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
                    child: InkWell(
                      onTap: () => _pickStartTime(context),
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Routine Start Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startTimeOfDay == null
                              ? '--:--'
                              : '${_startTimeOfDay!.hour.toString().padLeft(2, '0')}:${_startTimeOfDay!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Enable Breaks by Default'),
                value: _breaksEnabled,
                onChanged: (v) => setState(() => _breaksEnabled = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _breakDurationMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Break Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // Reset local fields to current state
                      _syncFromState(model);
                      setState(() {});
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _onSave(model),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text('Task Details', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taskNameController,
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
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
                  OutlinedButton.icon(
                    onPressed: hasSelection
                        ? () => context.read<RoutineBloc>().add(const DuplicateSelectedTask())
                        : null,
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    onPressed: hasSelection
                        ? () => context.read<RoutineBloc>().add(const DeleteSelectedTask())
                        : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Task'),
                  ),
                ],
              ),
              if (selectedTask == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'No task selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
