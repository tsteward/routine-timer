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

    if (isExpanded) {
      // Return all upcoming tasks in expanded state
      return routineState.tasks.sublist(currentIndex + 1);
    } else {
      // Return next 2-3 tasks for collapsed state
      final endIndex = (currentIndex + 4).clamp(0, totalTasks);
      return routineState.tasks.sublist(currentIndex + 1, endIndex);
    }
  }

  List<TaskModel> get _completedTasks {
    return routineState.tasks.where((task) => task.isCompleted).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final upcomingTasks = _upcomingTasks;
    final completedTasks = _completedTasks;

    // Don't show drawer if no upcoming tasks
    if (upcomingTasks.isEmpty && completedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Semi-transparent overlay when expanded - positioned to fill entire screen
        if (isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggleExpanded,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),

        // Drawer content at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            // Prevent taps on drawer from propagating to overlay
            onTap: () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: isExpanded
                  ? MediaQuery.of(context).size.height * 0.6
                  : null,
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
                    // Header with "Show More" / "Show Less" link
                    GestureDetector(
                      onTap: onToggleExpanded,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isExpanded ? 'Tasks' : 'Up Next',
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

                    if (isExpanded)
                      // Expanded state with scrollable sections
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Upcoming Tasks Section
                              if (upcomingTasks.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    8,
                                  ),
                                  child: Text(
                                    'Upcoming Tasks',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      8,
                                      8,
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: upcomingTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = upcomingTasks[index];
                                      return TaskCard(task: task, width: 140);
                                    },
                                  ),
                                ),
                              ],

                              // Completed Tasks Section
                              if (completedTasks.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    8,
                                  ),
                                  child: Text(
                                    'Completed Tasks',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 80,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      8,
                                      8,
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: completedTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = completedTasks[index];
                                      return _CompletedTaskCard(
                                        task: task,
                                        width: 160,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      // Collapsed state - show only upcoming tasks
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
          ),
        ),
      ],
    );
  }
}

/// A card displaying completed task information with actual time taken
class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({required this.task, this.width});

  final TaskModel task;
  final double? width;

  String _formatActualDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    if (minutes > 0) {
      return 'Took: $minutes min $secs sec';
    } else {
      return 'Took: $secs sec';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width ?? 160,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    decoration: TextDecoration.lineThrough,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          if (task.actualDuration != null)
            Text(
              _formatActualDuration(task.actualDuration!),
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
