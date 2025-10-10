import 'package:flutter/material.dart';
import '../models/task.dart';

/// A card displaying completed task information with special styling
class CompletedTaskCard extends StatelessWidget {
  const CompletedTaskCard({super.key, required this.task, this.width});

  final TaskModel task;
  final double? width;

  /// Formats actual duration to "Took: X min Y sec" format
  String _formatActualDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0 && remainingSeconds > 0) {
      return 'Took: ${minutes}m ${remainingSeconds}s';
    } else if (minutes > 0) {
      return 'Took: ${minutes}m';
    } else {
      return 'Took: ${remainingSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width ?? 140,
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
          // Task name with checkmark and strike-through
          Flexible(
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Actual time taken
          if (task.actualDuration != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatActualDuration(task.actualDuration!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
