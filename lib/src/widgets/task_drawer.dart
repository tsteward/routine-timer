import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/routine_state.dart';
import 'task_card.dart';

/// A bottom drawer showing upcoming and completed tasks in a routine
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

    if (isExpanded) {
      // Return all upcoming tasks when expanded
      return routineState.tasks.sublist(currentIndex + 1);
    } else {
      // Return next 2-3 tasks for collapsed state
      final endIndex = (currentIndex + 4).clamp(0, totalTasks);
      return routineState.tasks.sublist(currentIndex + 1, endIndex);
    }
  }

  List<TaskModel> get _completedTasks {
    final currentIndex = routineState.currentTaskIndex;

    if (currentIndex <= 0) {
      return []; // No completed tasks
    }

    // Return all completed tasks (tasks before current index)
    return routineState.tasks.sublist(0, currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final upcomingTasks = _upcomingTasks;
    final completedTasks = _completedTasks;

    // Don't show drawer if no upcoming or completed tasks
    if (upcomingTasks.isEmpty && completedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Background overlay when expanded
        if (isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggleExpanded,
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),

        // Drawer content
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            constraints: BoxConstraints(
              maxHeight: isExpanded
                  ? MediaQuery.of(context).size.height * 0.6
                  : 160,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                  // Header with "Show More" or "Show Less" link
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
                            isExpanded ? 'Show Less' : 'Show More',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content based on expanded state
                  if (isExpanded)
                    _buildExpandedContent(
                      context,
                      upcomingTasks,
                      completedTasks,
                    )
                  else
                    _buildCollapsedContent(context, upcomingTasks),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedContent(
    BuildContext context,
    List<TaskModel> upcomingTasks,
  ) {
    return SizedBox(
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
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    List<TaskModel> upcomingTasks,
    List<TaskModel> completedTasks,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upcoming Tasks Section
            if (upcomingTasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Upcoming Tasks',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingTasks.length,
                  itemBuilder: (context, index) {
                    final task = upcomingTasks[index];
                    return TaskCard(task: task, width: 160);
                  },
                ),
              ),
            ],

            // Completed Tasks Section
            if (completedTasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Completed Tasks',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: completedTasks.length,
                  itemBuilder: (context, index) {
                    final task = completedTasks[index];
                    return _CompletedTaskCard(task: task, width: 180);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A card displaying completed task information with strike-through styling
class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({required this.task, this.width});

  final TaskModel task;
  final double? width;

  String _formatActualTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    if (minutes > 0 && secs > 0) {
      return 'Took: $minutes min $secs sec';
    } else if (minutes > 0) {
      return 'Took: $minutes min';
    } else {
      return 'Took: $secs sec';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width ?? 180,
      height: 90, // Fixed height to match container
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task name with checkmark and strike-through
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: colorScheme.onSurface.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Actual time taken
          Text(
            _formatActualTime(task.actualDuration ?? task.estimatedDuration),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
