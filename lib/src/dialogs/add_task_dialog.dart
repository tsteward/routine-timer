import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/routine_bloc.dart';
import '../models/library_task.dart';
import '../utils/time_formatter.dart';
import 'duration_picker_dialog.dart';

/// Dialog for adding a new task to the routine
///
/// Provides two tabs:
/// 1. "Create New" - Create a brand new task
/// 2. "Add Task" - Select from previously created tasks in the library
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Create New'),
                Tab(text: 'Add Task'),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: const [_CreateNewTaskTab(), _SelectTaskTab()],
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
      ],
    );
  }
}

/// Tab for creating a new task
class _CreateNewTaskTab extends StatefulWidget {
  const _CreateNewTaskTab();

  @override
  State<_CreateNewTaskTab> createState() => _CreateNewTaskTabState();
}

class _CreateNewTaskTabState extends State<_CreateNewTaskTab> {
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

  void _addTask() {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
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
              child: Text(_formatDuration(), style: theme.textTheme.bodyLarge),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab for selecting a task from the library
class _SelectTaskTab extends StatelessWidget {
  const _SelectTaskTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        // Filter library tasks to exclude those already in the routine
        final availableTasks = model.libraryTasks.where((libTask) {
          return !model.tasks.any((task) => task.libraryTaskId == libTask.id);
        }).toList();

        if (availableTasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No tasks available. Create your first task in the "Create New" tab!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: availableTasks.length,
          itemBuilder: (context, index) {
            final task = availableTasks[index];
            return _TaskSelectionCard(
              task: task,
              onTap: () {
                context.read<RoutineBloc>().add(
                  AddTaskFromLibrary(libraryTaskId: task.id),
                );
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }
}

/// Card widget for displaying a library task in the selection list
class _TaskSelectionCard extends StatelessWidget {
  const _TaskSelectionCard({required this.task, required this.onTap});

  final LibraryTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.task_alt, color: theme.colorScheme.primary),
        title: Text(task.name),
        subtitle: Text(TimeFormatter.formatDuration(task.defaultDuration)),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle),
          onPressed: onTap,
          tooltip: 'Add to routine',
        ),
        onTap: onTap,
      ),
    );
  }
}
