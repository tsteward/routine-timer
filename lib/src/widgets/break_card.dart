import 'package:flutter/material.dart';
import '../models/break.dart';
import '../utils/time_formatter.dart';

/// A compact card showing break information for the task drawer
class BreakCard extends StatelessWidget {
  const BreakCard({super.key, required this.breakModel, this.width = 100});

  final BreakModel breakModel;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.coffee, size: 18, color: colorScheme.onSecondaryContainer),
          const SizedBox(height: 2),
          Text(
            'Break',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            TimeFormatter.formatDuration(breakModel.duration),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
