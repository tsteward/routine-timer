import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/routine_state.dart';
import 'task_card.dart';
import 'completed_task_card.dart';

/// A bottom drawer showing upcoming and completed tasks in a routine
class TaskDrawer extends StatefulWidget {
  const TaskDrawer({
    super.key,
    required this.routineState,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final RoutineStateModel routineState;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  State<TaskDrawer> createState() => _TaskDrawerState();
}

class _TaskDrawerState extends State<TaskDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TaskDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<TaskModel> get _upcomingTasks {
    final currentIndex = widget.routineState.currentTaskIndex;
    final totalTasks = widget.routineState.tasks.length;

    if (currentIndex >= totalTasks - 1) {
      return []; // No upcoming tasks
    }

    if (widget.isExpanded) {
      // Return all upcoming tasks for expanded state
      return widget.routineState.tasks.sublist(currentIndex + 1);
    } else {
      // Return next 2-3 tasks for collapsed state
      final endIndex = (currentIndex + 4).clamp(0, totalTasks);
      return widget.routineState.tasks.sublist(currentIndex + 1, endIndex);
    }
  }

  List<TaskModel> get _completedTasks {
    return widget.routineState.tasks.where((task) => task.isCompleted).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final upcomingTasks = _upcomingTasks;
    final completedTasks = _completedTasks;

    // Don't show drawer if no upcoming tasks and no completed tasks
    if (upcomingTasks.isEmpty && completedTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: widget.isExpanded ? widget.onToggleExpanded : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
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
            child: widget.isExpanded
                ? _buildExpandedContent(
                    theme,
                    colorScheme,
                    upcomingTasks,
                    completedTasks,
                  )
                : _buildCollapsedContent(theme, colorScheme, upcomingTasks),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(
    ThemeData theme,
    ColorScheme colorScheme,
    List<TaskModel> upcomingTasks,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with "Show More" link
        GestureDetector(
          onTap: widget.onToggleExpanded,
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
    );
  }

  Widget _buildExpandedContent(
    ThemeData theme,
    ColorScheme colorScheme,
    List<TaskModel> upcomingTasks,
    List<TaskModel> completedTasks,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with "Show Less" link
        GestureDetector(
          onTap: widget.onToggleExpanded,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks Overview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Show Less',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Upcoming Tasks Section
        if (upcomingTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Upcoming Tasks',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Completed Tasks',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
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

        // Show message if no completed tasks yet
        if (completedTasks.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'No completed tasks yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
