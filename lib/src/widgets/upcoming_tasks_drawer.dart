import 'package:flutter/material.dart';
import '../models/routine_state.dart';
import '../utils/time_formatter.dart';

class UpcomingTasksDrawer extends StatelessWidget {
  const UpcomingTasksDrawer({
    super.key,
    required this.model,
  });

  final RoutineStateModel model;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Up Next',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _buildUpcomingItems(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUpcomingItems() {
    final items = <Widget>[];
    
    // Calculate start time for upcoming items
    var currentTime = DateTime.now();
    
    // If we're on a break, the next item is the task after the break
    // If we're not on a break, show upcoming tasks starting from the next task
    final startIndex = model.isOnBreak 
        ? model.currentTaskIndex + 1
        : model.currentTaskIndex + 1;  // Show upcoming tasks, not current task

    for (int i = startIndex; i < model.tasks.length; i++) {
      final task = model.tasks[i];
      final isNext = (i == startIndex);
      
      // Add task item
      items.add(
        _TaskItem(
          name: task.name,
          duration: task.estimatedDuration,
          estimatedStartTime: currentTime,
          isNext: isNext,
        ),
      );
      
      // Update current time for next item
      currentTime = currentTime.add(Duration(seconds: task.estimatedDuration));
      
      // Add break item if there's a break after this task
      final breakIndex = i;
      if (model.breaks != null && 
          breakIndex < model.breaks!.length && 
          model.breaks![breakIndex].isEnabled &&
          i < model.tasks.length - 1) { // Don't show break after last task
        
        items.add(
          _BreakItem(
            duration: model.breaks![breakIndex].duration,
            estimatedStartTime: currentTime,
          ),
        );
        
        // Update current time for break
        currentTime = currentTime.add(
          Duration(seconds: model.breaks![breakIndex].duration),
        );
      }
    }

    if (items.isEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'All tasks completed!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return items;
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.name,
    required this.duration,
    required this.estimatedStartTime,
    this.isNext = false,
  });

  final String name;
  final int duration;
  final DateTime estimatedStartTime;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isNext ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: isNext ? Theme.of(context).primaryColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                      fontSize: isNext ? 16 : 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Duration: ${TimeFormatter.formatDuration(duration)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              'Est. start: ${TimeFormatter.formatTime(estimatedStartTime)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakItem extends StatelessWidget {
  const _BreakItem({
    required this.duration,
    required this.estimatedStartTime,
  });

  final int duration;
  final DateTime estimatedStartTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.coffee,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Break',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Duration: ${TimeFormatter.formatDuration(duration)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              'Est. start: ${TimeFormatter.formatTime(estimatedStartTime)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}