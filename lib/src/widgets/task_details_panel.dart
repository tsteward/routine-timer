import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/routine_bloc.dart';
import '../dialogs/duration_picker_dialog.dart';
import '../models/routine_state.dart';
import '../models/task.dart';
import '../utils/time_formatter.dart';

/// A panel for displaying and editing task details
class TaskDetailsPanel extends StatefulWidget {
  const TaskDetailsPanel({required this.model, required this.task, super.key});

  final RoutineStateModel model;
  final TaskModel task;

  @override
  State<TaskDetailsPanel> createState() => _TaskDetailsPanelState();
}

class _TaskDetailsPanelState extends State<TaskDetailsPanel> {
  final _taskNameController = TextEditingController();

  // Track if we're currently updating from bloc to prevent feedback loops
  bool _isUpdatingFromBloc = false;

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TaskDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller when task changes
    if (widget.task.id != oldWidget.task.id ||
        widget.task.name != oldWidget.task.name) {
      if (!_isUpdatingFromBloc) {
        _isUpdatingFromBloc = true;
        _taskNameController.text = widget.task.name;
        _isUpdatingFromBloc = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _taskNameController.text = widget.task.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Task Name
            TextField(
              controller: _taskNameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (!_isUpdatingFromBloc) {
                  _updateTaskName(context, value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Estimated Duration
            InkWell(
              onTap: () => _pickTaskDuration(context),
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Estimated Duration',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.timer_outlined),
                ),
                child: Text(
                  TimeFormatter.formatDuration(widget.task.estimatedDuration),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Break After This Task (always show, disable if not available)
            if (!_isLastTask())
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: _isBreakEnabled() ? 1.0 : 0.5,
                    child: InkWell(
                      onTap: _isBreakEnabled()
                          ? () => _pickBreakDuration(context)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Break After This Task',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.coffee),
                          helperText: _getBreakHelperText(),
                          enabled: _isBreakEnabled(),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isBreakEnabled()
                                    ? TimeFormatter.formatDuration(
                                        _getBreakDuration(),
                                      )
                                    : 'Break disabled',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: _isBreakEnabled()
                                      ? null
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.38,
                                        ),
                                ),
                              ),
                            ),
                            if (_isBreakEnabled() && _isBreakCustomized())
                              TextButton.icon(
                                onPressed: () => _resetBreakToDefault(context),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Reset'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            // Duplicate and Delete buttons side by side
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _duplicateTask(context),
                    icon: const Icon(Icons.content_copy),
                    label: const Text('Duplicate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.model.tasks.length > 1
                        ? () => _deleteTask(context)
                        : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isLastTask() {
    final taskIndex = widget.model.currentTaskIndex;
    return taskIndex >= widget.model.tasks.length - 1;
  }

  bool _isBreakEnabled() {
    final taskIndex = widget.model.currentTaskIndex;
    return widget.model.breaks != null &&
        taskIndex < widget.model.breaks!.length &&
        widget.model.breaks![taskIndex].isEnabled;
  }

  bool _isBreakCustomized() {
    final taskIndex = widget.model.currentTaskIndex;
    return widget.model.breaks != null &&
        taskIndex < widget.model.breaks!.length &&
        widget.model.breaks![taskIndex].isCustomized;
  }

  int _getBreakDuration() {
    final taskIndex = widget.model.currentTaskIndex;
    if (widget.model.breaks != null &&
        taskIndex < widget.model.breaks!.length) {
      return widget.model.breaks![taskIndex].duration;
    }
    return widget.model.settings.defaultBreakDuration;
  }

  String _getBreakHelperText() {
    if (!_isBreakEnabled()) {
      return 'Tap the gap in the task list to enable';
    }
    final taskIndex = widget.model.currentTaskIndex;
    if (widget.model.breaks != null &&
        taskIndex < widget.model.breaks!.length) {
      final breakModel = widget.model.breaks![taskIndex];
      if (breakModel.isCustomized) {
        return 'Customized duration';
      }
    }
    return 'Using default break duration';
  }

  void _resetBreakToDefault(BuildContext context) {
    final taskIndex = widget.model.currentTaskIndex;
    context.read<RoutineBloc>().add(ResetBreakToDefault(index: taskIndex));
  }

  Future<void> _pickBreakDuration(BuildContext context) async {
    final taskIndex = widget.model.currentTaskIndex;
    if (widget.model.breaks == null ||
        taskIndex >= widget.model.breaks!.length) {
      return;
    }

    final currentBreak = widget.model.breaks![taskIndex];
    final currentDuration = currentBreak.duration;
    final hours = currentDuration ~/ 3600;
    final minutes = (currentDuration % 3600) ~/ 60;

    // Capture BuildContext values before async gap
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<RoutineBloc>();

    final picked = await DurationPickerDialog.show(
      context: context,
      initialHours: hours,
      initialMinutes: minutes,
      title: 'Break Duration',
    );

    if (picked != null && mounted) {
      if (picked <= 0) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Duration must be greater than 0')),
        );
        return;
      }

      if (!mounted) return;
      bloc.add(UpdateBreakDuration(index: taskIndex, duration: picked));
    }
  }

  void _updateTaskName(BuildContext context, String value) {
    final trimmedName = value.trim();
    if (trimmedName.isEmpty) {
      return; // Don't update with empty name
    }

    final updatedTask = widget.task.copyWith(name: value);

    context.read<RoutineBloc>().add(
      UpdateTask(index: widget.model.currentTaskIndex, task: updatedTask),
    );
  }

  Future<void> _pickTaskDuration(BuildContext context) async {
    final currentDuration = widget.task.estimatedDuration;
    final hours = currentDuration ~/ 3600;
    final minutes = (currentDuration % 3600) ~/ 60;

    // Capture BuildContext values before async gap
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<RoutineBloc>();

    final picked = await DurationPickerDialog.show(
      context: context,
      initialHours: hours,
      initialMinutes: minutes,
      title: 'Task Duration',
    );

    if (picked != null && mounted) {
      final durationInSeconds = picked;

      if (durationInSeconds <= 0) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Duration must be greater than 0')),
        );
        return;
      }

      if (!mounted) return;
      final updatedTask = widget.task.copyWith(
        estimatedDuration: durationInSeconds,
      );

      bloc.add(
        UpdateTask(index: widget.model.currentTaskIndex, task: updatedTask),
      );
    }
  }

  void _duplicateTask(BuildContext context) {
    context.read<RoutineBloc>().add(
      DuplicateTask(widget.model.currentTaskIndex),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task duplicated successfully')),
    );
  }

  Future<void> _deleteTask(BuildContext context) async {
    if (widget.model.tasks.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last task')),
      );
      return;
    }

    // Capture BuildContext values before async gap
    final bloc = context.read<RoutineBloc>();
    final messenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (!mounted) return;
      bloc.add(DeleteTask(widget.model.currentTaskIndex));
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Task deleted successfully')),
      );
    }
  }
}
