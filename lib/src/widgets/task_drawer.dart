import 'package:flutter/material.dart';
import '../models/break.dart';
import '../models/task.dart';
import '../models/routine_state.dart';
import '../utils/time_formatter.dart';
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

  /// Represents an item in the upcoming list (either a task or a break)
  List<_UpcomingItem> get _upcomingItems {
    final currentIndex = routineState.currentTaskIndex;
    final totalTasks = routineState.tasks.length;
    final items = <_UpcomingItem>[];

    // If on break, the next item is the task we're breaking before
    final startIndex = routineState.isOnBreak ? currentIndex : currentIndex + 1;

    if (startIndex >= totalTasks) {
      return []; // No upcoming items
    }

    if (isExpanded) {
      // Expanded: show all remaining tasks and interleave enabled breaks
      for (int i = startIndex; i < totalTasks; i++) {
        items.add(_UpcomingItem.task(routineState.tasks[i]));
        if (i < totalTasks - 1 &&
            routineState.breaks != null &&
            i < routineState.breaks!.length) {
          final breakItem = routineState.breaks![i];
          if (breakItem.isEnabled) {
            items.add(_UpcomingItem.breakItem(breakItem));
          }
        }
      }
    } else {
      // Collapsed: show only the next 3 tasks (no breaks)
      int shown = 0;
      for (int i = startIndex; i < totalTasks && shown < 3; i++) {
        items.add(_UpcomingItem.task(routineState.tasks[i]));
        shown++;
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

  Widget _buildCollapsedContent(List<_UpcomingItem> upcomingItems) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
        scrollDirection: Axis.horizontal,
        itemCount: upcomingItems.length,
        itemBuilder: (context, index) {
          final item = upcomingItems[index];
          return item.when(
            task: (task) => TaskCard(task: task, width: 140),
            breakItem: (breakModel) => _buildBreakCard(breakModel, width: 140),
          );
        },
      ),
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    ColorScheme colorScheme,
    List<_UpcomingItem> upcomingItems,
    List<TaskModel> completedTasks,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upcoming Items Section (tasks + breaks)
          if (upcomingItems.isNotEmpty) ...[
            SizedBox(
              height: 80,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                scrollDirection: Axis.horizontal,
                itemCount: upcomingItems.length,
                itemBuilder: (context, index) {
                  final item = upcomingItems[index];
                  return item.when(
                    task: (task) => TaskCard(task: task, width: 140),
                    breakItem: (breakModel) =>
                        _buildBreakCard(breakModel, width: 140),
                  );
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

  Widget _buildBreakCard(BreakModel breakModel, {required double width}) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.coffee, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  'Break',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              TimeFormatter.formatDuration(breakModel.duration),
              style: TextStyle(fontSize: 12, color: Colors.green.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents either a task or a break in the upcoming list
class _UpcomingItem {
  _UpcomingItem.task(this.taskModel) : breakModel = null, isTask = true;

  _UpcomingItem.breakItem(this.breakModel) : taskModel = null, isTask = false;

  final TaskModel? taskModel;
  final BreakModel? breakModel;
  final bool isTask;

  T when<T>({
    required T Function(TaskModel) task,
    required T Function(BreakModel) breakItem,
  }) {
    if (isTask) {
      return task(taskModel!);
    } else {
      return breakItem(breakModel!);
    }
  }
}
