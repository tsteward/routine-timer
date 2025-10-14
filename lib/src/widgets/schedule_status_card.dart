import 'package:flutter/material.dart';
import '../services/schedule_tracker.dart';
import '../app_theme.dart';

/// Card widget that displays the current schedule status.
class ScheduleStatusCard extends StatelessWidget {
  const ScheduleStatusCard({required this.scheduleStatus, super.key});

  final ScheduleStatus scheduleStatus;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(scheduleStatus.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status text
          Row(
            children: [
              Icon(
                _getStatusIcon(scheduleStatus.status),
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                scheduleStatus.statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Estimated completion time
          Text(
            'Est. Completion: ${scheduleStatus.completionTimeString}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ScheduleStatusType status) {
    switch (status) {
      case ScheduleStatusType.ahead:
        return AppTheme.green;
      case ScheduleStatusType.onTrack:
        return Colors.blue;
      case ScheduleStatusType.behind:
        return AppTheme.red;
    }
  }

  IconData _getStatusIcon(ScheduleStatusType status) {
    switch (status) {
      case ScheduleStatusType.ahead:
        return Icons.trending_up;
      case ScheduleStatusType.onTrack:
        return Icons.check_circle_outline;
      case ScheduleStatusType.behind:
        return Icons.trending_down;
    }
  }
}
