import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/routine_state.dart';
import '../models/break.dart';
import 'task_card.dart';
import 'completed_task_card.dart';
import 'break_card.dart';

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

  /// Returns a list of upcoming items (tasks and breaks) as a mixed list.
  /// Each item is either a TaskModel or a BreakModel.
  List<dynamic> get _upcomingItems {
    final currentIndex = routineState.currentTaskIndex;
    final totalTasks = routineState.tasks.length;
    final breaks = routineState.breaks;

    // If we're on a break, start from the current task
    // Otherwise, start from the next task
    final startIndex = routineState.isOnBreak ? currentIndex : currentIndex + 1;

    if (startIndex >= totalTasks) {
      return []; // No upcoming items
    }

    final items = <dynamic>[];
    final maxItems = isExpanded
        ? totalTasks
        : 6; // Show up to 6 items when collapsed

    for (int i = startIndex; i < totalTasks && items.length < maxItems; i++) {
      // If we're on a break and this is the current task, add the break first
      if (routineState.isOnBreak && i == currentIndex && breaks != null) {
        if (routineState.currentBreakIndex != null &&
            routineState.currentBreakIndex! < breaks.length) {
          final breakModel = breaks[routineState.currentBreakIndex!];
          if (breakModel.isEnabled) {
            items.add(breakModel);
          }
        }
      }

      // Add the task
      items.add(routineState.tasks[i]);

      // Add break after this task if it exists and is enabled
      if (breaks != null && i < breaks.length) {
        final breakModel = breaks[i];
        if (breakModel.isEnabled && i < totalTasks - 1) {
          // Don't show break if we're currently on it
          if (!routineState.isOnBreak || routineState.currentBreakIndex != i) {
            items.add(breakModel);
          }
        }
      }
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
            return BreakCard(breakModel: item, width: 140);
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
          // Upcoming Items Section (Tasks and Breaks)
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
                    return BreakCard(breakModel: item, width: 140);
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
