import 'package:flutter/material.dart';
import '../models/break.dart';
import '../models/task.dart';
import '../models/routine_state.dart';
import 'task_card.dart';
import 'completed_task_card.dart';

/// A bottom drawer showing upcoming tasks and breaks in a routine
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

  /// Represents tasks with their following breaks
  List<_TaskWithBreak> get _upcomingItems {
    final currentIndex = routineState.currentTaskIndex;
    final totalTasks = routineState.tasks.length;
    final items = <_TaskWithBreak>[];

    // Bug fix: During break, show next task (not the just-completed one)
    final startIndex = routineState.isOnBreak
        ? currentIndex + 1
        : currentIndex + 1;

    if (startIndex >= totalTasks) {
      return []; // No upcoming items
    }

    // Show all remaining tasks with their following breaks
    for (int i = startIndex; i < totalTasks; i++) {
      BreakModel? followingBreak;
      if (i < totalTasks - 1 &&
          routineState.breaks != null &&
          i < routineState.breaks!.length) {
        final breakItem = routineState.breaks![i];
        if (breakItem.isEnabled) {
          followingBreak = breakItem;
        }
      }
      items.add(_TaskWithBreak(routineState.tasks[i], followingBreak));
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
                    _buildHeader(
                      theme,
                      colorScheme,
                      showLabel: isExpanded || _completedTasks.isEmpty,
                    ),

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

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool showLabel,
  }) {
    return GestureDetector(
      onTap: onToggleExpanded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            showLabel
                ? Text(
                    'Up Next',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  )
                : const SizedBox.shrink(),
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

  Widget _buildCollapsedContent(List<_TaskWithBreak> upcomingItems) {
    const cardHeight = 80.0;
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
        scrollDirection: Axis.horizontal,
        itemCount: upcomingItems.length,
        itemBuilder: (context, index) {
          final item = upcomingItems[index];
          return TaskCard(
            task: item.task,
            width: 140,
            height: cardHeight,
            breakAfter: item.breakAfter,
          );
        },
      ),
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    ColorScheme colorScheme,
    List<_TaskWithBreak> upcomingItems,
    List<TaskModel> completedTasks,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upcoming Items Section (tasks with break info)
          if (upcomingItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: upcomingItems.map((item) {
                  return TaskCard(
                    task: item.task,
                    width: 140,
                    height: 80,
                    breakAfter: item.breakAfter,
                  );
                }).toList(),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: completedTasks.map((task) {
                  return CompletedTaskCard(task: task, width: 140, height: 80);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Represents a task with its optional following break
class _TaskWithBreak {
  const _TaskWithBreak(this.task, this.breakAfter);

  final TaskModel task;
  final BreakModel? breakAfter;
}
