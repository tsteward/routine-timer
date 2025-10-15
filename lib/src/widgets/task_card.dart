import 'package:flutter/material.dart';
import '../models/break.dart';
import '../models/task.dart';
import '../utils/time_formatter.dart';

/// A card displaying task information for use in the task drawer
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.width,
    this.height,
    this.breakAfter,
  });

  final TaskModel task;
  final double? width;
  final double? height;
  final BreakModel? breakAfter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width ?? 140,
      height: height,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              task.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.timer,
                size: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  TimeFormatter.formatDuration(task.estimatedDuration),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (breakAfter != null) ...[
            const SizedBox(height: 1),
            Row(
              children: [
                Icon(Icons.coffee, size: 11, color: Colors.green.shade700),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    'Break: ${TimeFormatter.formatDuration(breakAfter!.duration)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green.shade700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
