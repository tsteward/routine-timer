import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/break.dart';
import '../models/routine_state.dart';
import 'task_card.dart';
import 'completed_task_card.dart';

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

  /// Gets the upcoming items (tasks and breaks) after the current position.
  /// Returns a list of objects that are either TaskModel or BreakModel.
  List<dynamic> get _upcomingItems {
    final currentIndex = routineState.currentTaskIndex;
    final totalTasks = routineState.tasks.length;

    if (currentIndex >= totalTasks - 1) {
      return []; // No upcoming tasks
    }

    final items = <dynamic>[];
    final startIndex = currentIndex + 1;
    final endIndex = isExpanded
        ? totalTasks
        : (currentIndex + 4).clamp(0, totalTasks);

    for (int i = startIndex; i < endIndex; i++) {
      // Add break before this task if exists and is enabled
      final breakIndex = i - 1;
      if (routineState.breaks != null &&
          breakIndex >= 0 &&
          breakIndex < routineState.breaks!.length) {
        final breakModel = routineState.breaks![breakIndex];
        if (breakModel.isEnabled) {
          items.add(breakModel);
        }
      }

      // Add the task
      items.add(routineState.tasks[i]);
    }

    return items;
  }

  List<TaskModel> get _completedTasks {
    return routineState.tasks.where((task) => task.isCompleted).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final upcomingItems = _upcomingItems;
    final completedTasks = _completedTasks;

    // Don't show drawer if no upcoming items and not expanded
    if (upcomingItems.isEmpty && !isExpanded) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Semi-transparent background when expanded
        if (isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggleExpanded,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),

        // Drawer content
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () {}, // Prevent taps from passing through to background
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
                    // Header with toggle link
                    _buildHeader(theme, colorScheme),

                    // Content based on state
                    if (isExpanded)
                      Expanded(
                        child: _buildExpandedContent(
                          theme,
                          colorScheme,
                          upcomingItems,
                          completedTasks,
                        ),
                      )
                    else
                      _buildCollapsedContent(upcomingItems),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
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
    );
  }

  Widget _buildCollapsedContent(List<dynamic> upcomingItems) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
        scrollDirection: Axis.horizontal,
        itemCount: upcomingItems.length,
        itemBuilder: (context, index) {
          final item = upcomingItems[index];
          if (item is TaskModel) {
            return TaskCard(task: item, width: 140);
          } else if (item is BreakModel) {
            return _BreakCard(breakModel: item, width: 100);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    ColorScheme colorScheme,
    List<dynamic> upcomingItems,
    List<TaskModel> completedTasks,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upcoming Items Section (tasks and breaks)
          if (upcomingItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Up Next',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                scrollDirection: Axis.horizontal,
                itemCount: upcomingItems.length,
                itemBuilder: (context, index) {
                  final item = upcomingItems[index];
                  if (item is TaskModel) {
                    return TaskCard(task: item, width: 140);
                  } else if (item is BreakModel) {
                    return _BreakCard(breakModel: item, width: 100);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],

          // Completed Tasks Section
          if (completedTasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Completed Tasks',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                scrollDirection: Axis.horizontal,
                itemCount: completedTasks.length,
                itemBuilder: (context, index) {
                  final task = completedTasks[index];
                  return CompletedTaskCard(task: task, width: 140);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A card displaying a break between tasks
class _BreakCard extends StatelessWidget {
  const _BreakCard({required this.breakModel, required this.width});

  final BreakModel breakModel;
  final double width;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m';
    }
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.coffee, color: colorScheme.primary, size: 18),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              'Break',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              _formatDuration(breakModel.duration),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
