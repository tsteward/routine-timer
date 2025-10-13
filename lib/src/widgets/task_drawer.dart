import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/routine_state.dart';
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

  /// Gets the upcoming items (tasks and breaks) starting from the next item
  List<Widget> _buildUpcomingItems(ThemeData theme) {
    final items = <Widget>[];
    final currentIndex = routineState.currentTaskIndex;
    final totalTasks = routineState.tasks.length;

    // If we're in a break, the next item is the task after the break
    final startIndex = routineState.isInBreak
        ? currentIndex + 1
        : currentIndex + 1;

    // If we're currently in a break, show the break first
    if (routineState.isInBreak &&
        routineState.currentBreakIndex != null &&
        routineState.breaks != null &&
        routineState.currentBreakIndex! < routineState.breaks!.length) {
      final currentBreak =
          routineState.breaks![routineState.currentBreakIndex!];
      if (currentBreak.isEnabled) {
        items.add(BreakCard(breakModel: currentBreak, width: 140));
      }
    }

    if (startIndex >= totalTasks) {
      return items; // No more tasks
    }

    final maxItems = isExpanded
        ? totalTasks
        : (startIndex + 3).clamp(0, totalTasks);

    for (int i = startIndex; i < maxItems; i++) {
      // Add task
      items.add(TaskCard(task: routineState.tasks[i], width: 140));

      // Add break after task if it exists and is enabled
      if (routineState.breaks != null &&
          i < routineState.breaks!.length &&
          i < totalTasks - 1) {
        // Don't show break after last task
        final breakAfterTask = routineState.breaks![i];
        if (breakAfterTask.isEnabled) {
          items.add(BreakCard(breakModel: breakAfterTask, width: 140));
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
    final upcomingItems = _buildUpcomingItems(theme);
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

  Widget _buildCollapsedContent(List<Widget> upcomingItems) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
        scrollDirection: Axis.horizontal,
        itemCount: upcomingItems.length,
        itemBuilder: (context, index) {
          return upcomingItems[index];
        },
      ),
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    ColorScheme colorScheme,
    List<Widget> upcomingItems,
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
                  return upcomingItems[index];
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
