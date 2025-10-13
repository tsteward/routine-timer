import 'package:flutter/material.dart';
import '../models/break.dart';
import '../utils/time_formatter.dart';

/// A compact card showing a break with its duration
class BreakCard extends StatelessWidget {
  const BreakCard({super.key, required this.breakModel, this.width});

  final BreakModel breakModel;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.coffee,
                size: 16,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Break',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            TimeFormatter.formatDuration(breakModel.duration),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
