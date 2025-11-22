import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/routine_bloc.dart';
import '../models/library_task.dart';
import '../utils/time_formatter.dart';

/// Screen for viewing and managing the task library.
///
/// This screen is view-only with deletion capability. All task editing
/// happens in the routine context on the Task Management screen.
class TaskLibraryScreen extends StatelessWidget {
  const TaskLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Library'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<RoutineBloc, RoutineBlocState>(
        builder: (context, state) {
          final model = state.model;

          if (model == null) {
            return const Center(child: Text('No routine loaded'));
          }

          if (model.libraryTasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your task library is empty',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tasks you create will appear here automatically.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: model.libraryTasks.length,
            itemBuilder: (context, index) {
              final libraryTask = model.libraryTasks[index];
              // Check if this task is currently in the routine
              final isInRoutine = model.tasks.any(
                (task) => task.libraryTaskId == libraryTask.id,
              );

              return _LibraryTaskCard(
                task: libraryTask,
                isInRoutine: isInRoutine,
                onDelete: () =>
                    _showDeleteConfirmation(context, libraryTask, isInRoutine),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    LibraryTask task,
    bool isInRoutine,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          isInRoutine
              ? 'This task will be removed from your library. Any instances in your routine will remain but won\'t be linked to the library anymore.'
              : 'Are you sure you want to delete "${task.name}" from your library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<RoutineBloc>().add(
                DeleteLibraryTask(libraryTaskId: task.id),
              );
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying a library task in the library screen.
class _LibraryTaskCard extends StatelessWidget {
  const _LibraryTaskCard({
    required this.task,
    required this.isInRoutine,
    required this.onDelete,
  });

  final LibraryTask task;
  final bool isInRoutine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TimeFormatter.formatDuration(task.defaultDuration),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Delete task',
                  color: theme.colorScheme.error,
                ),
              ],
            ),
            if (isInRoutine) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'In current routine',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
