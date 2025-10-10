import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/routine_state.dart';
import 'task_card.dart';

/// A bottom drawer showing upcoming tasks in a routine
class TaskDrawer extends StatelessWidget {
  const TaskDrawer({
    super.key,
    required this.routineState,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final RoutineStateModel routineState;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  List<TaskModel> get _upcomingTasks {
    final currentIndex = routineState.currentTaskIndex;
    final totalTasks = routineState.tasks.length;

    if (currentIndex >= totalTasks - 1) {
      return []; // No upcoming tasks
    }

    // Return next 2-3 tasks for collapsed state
    final endIndex = (currentIndex + 4).clamp(0, totalTasks);
    return routineState.tasks.sublist(currentIndex + 1, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final upcomingTasks = _upcomingTasks;

    // Don't show drawer if no upcoming tasks
    if (upcomingTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with "Show More" link
              GestureDetector(
                onTap: onToggleExpanded,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Up Next',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Show More',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal scrollable task cards
              SizedBox(
                height: 80,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingTasks.length,
                  itemBuilder: (context, index) {
                    final task = upcomingTasks[index];
                    return TaskCard(task: task, width: 140);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
