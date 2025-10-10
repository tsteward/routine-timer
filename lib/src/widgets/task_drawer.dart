import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/task.dart';

/// A bottom drawer that shows upcoming tasks in a collapsed state.
/// Can be expanded to show more tasks by tapping "Show More".
class TaskDrawer extends StatefulWidget {
  const TaskDrawer({
    super.key,
    required this.upcomingTasks,
    this.isExpanded = false,
    this.onExpandChanged,
  });

  /// List of upcoming tasks to display
  final List<TaskModel> upcomingTasks;

  /// Whether the drawer is currently expanded
  final bool isExpanded;

  /// Callback when expansion state changes
  final ValueChanged<bool>? onExpandChanged;

  @override
  State<TaskDrawer> createState() => _TaskDrawerState();
}

class _TaskDrawerState extends State<TaskDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: widget.isExpanded
          ? 1.0
          : 0.0, // Set initial value based on isExpanded
    );
    _heightAnimation =
        Tween<double>(
          begin: 0.15, // Collapsed state shows ~15% of screen
          end: 0.6, // Expanded state shows ~60% of screen
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _toggleExpanded() {
    widget.onExpandChanged?.call(!widget.isExpanded);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.upcomingTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: MediaQuery.of(context).size.height * _heightAnimation.value,
          child: _buildDrawerContent(),
        );
      },
    );
  }

  Widget _buildDrawerContent() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle and Show More button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // Show More button
                GestureDetector(
                  onTap: _toggleExpanded,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Up Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            widget.isExpanded ? 'Show Less' : 'Show More',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            widget.isExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            color: AppTheme.green,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Task cards
          Expanded(child: _buildTaskCards()),
        ],
      ),
    );
  }

  Widget _buildTaskCards() {
    if (widget.isExpanded) {
      // Expanded view: vertical scrollable list
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
          itemCount: widget.upcomingTasks.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExpandedTaskCard(widget.upcomingTasks[index], index),
            );
          },
        ),
      );
    } else {
      // Collapsed view: horizontal scrollable row (next 2-3 tasks)
      final tasksToShow = widget.upcomingTasks.take(3).toList();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tasksToShow.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < tasksToShow.length - 1 ? 16 : 0,
                ),
                child: _buildCollapsedTaskCard(task, index),
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  Widget _buildCollapsedTaskCard(TaskModel task, int index) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Task order indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Next ${index + 1}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Task name
          Text(
            task.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Duration
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDuration(task.estimatedDuration),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedTaskCard(TaskModel task, int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          // Task order indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Task details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(task.estimatedDuration),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
