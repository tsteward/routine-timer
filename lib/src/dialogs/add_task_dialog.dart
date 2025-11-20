import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/routine_bloc.dart';
import 'duration_picker_dialog.dart';

/// Dialog for adding a new task to the routine
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _durationInSeconds = 10 * 60; // Default: 10 minutes
  String? _durationError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDuration() async {
    final minutes = _durationInSeconds ~/ 60;
    final seconds = _durationInSeconds % 60;

    final picked = await DurationPickerDialog.show(
      context: context,
      initialMinutes: minutes,
      initialSeconds: seconds,
      title: 'Task Duration',
    );

    if (picked != null) {
      setState(() {
        _durationInSeconds = picked;
        _durationError = null;
      });
    }
  }

  String _formatDuration() {
    final minutes = _durationInSeconds ~/ 60;
    final seconds = _durationInSeconds % 60;
    if (minutes == 0 && seconds == 0) {
      return 'Tap to select duration';
    }
    if (minutes > 0 && seconds > 0) {
      return '${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add New Task'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                hintText: 'e.g., Morning Stretch',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDuration,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Duration',
                  border: const OutlineInputBorder(),
                  errorText: _durationError,
                  suffixIcon: const Icon(Icons.timer_outlined),
                ),
                child: Text(
                  _formatDuration(),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Validate that duration is greater than 0
              if (_durationInSeconds <= 0) {
                setState(() {
                  _durationError = 'Please select a duration greater than 0';
                });
                return;
              }

              final name = _nameController.text.trim();

              context.read<RoutineBloc>().add(
                AddTask(name: name, durationSeconds: _durationInSeconds),
              );
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: const Text('Add Task'),
        ),
      ],
    );
  }
}
