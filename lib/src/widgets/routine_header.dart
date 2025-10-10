import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_status.dart';

/// Header widget that displays schedule status and estimated completion time
class RoutineHeader extends StatelessWidget {
  const RoutineHeader({
    super.key,
    required this.scheduleStatus,
    required this.onSettingsTap,
  });

  final ScheduleStatus scheduleStatus;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Left side: Schedule status card
          Expanded(child: _ScheduleStatusCard(scheduleStatus: scheduleStatus)),

          const SizedBox(width: 16),

          // Right side: Settings gear icon
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Card widget that displays the current schedule status
class _ScheduleStatusCard extends StatelessWidget {
  const _ScheduleStatusCard({required this.scheduleStatus});

  final ScheduleStatus scheduleStatus;

  @override
  Widget build(BuildContext context) {
    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();
    final completionTime = DateFormat(
      'h:mm a',
    ).format(scheduleStatus.estimatedCompletionTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status text with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Estimated completion time
          Text(
            'Est. Completion: $completionTime',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get the appropriate status text based on schedule status
  String _getStatusText() {
    switch (scheduleStatus.type) {
      case ScheduleStatusType.ahead:
        if (scheduleStatus.minutesDifference == 1) {
          return 'Ahead by 1 min';
        }
        return 'Ahead by ${scheduleStatus.minutesDifference} min';
      case ScheduleStatusType.behind:
        if (scheduleStatus.minutesDifference == 1) {
          return 'Behind by 1 min';
        }
        return 'Behind by ${scheduleStatus.minutesDifference} min';
      case ScheduleStatusType.onTrack:
        return 'On track';
    }
  }

  /// Get the appropriate icon based on schedule status
  IconData _getStatusIcon() {
    switch (scheduleStatus.type) {
      case ScheduleStatusType.ahead:
        return Icons.trending_up;
      case ScheduleStatusType.behind:
        return Icons.trending_down;
      case ScheduleStatusType.onTrack:
        return Icons.track_changes;
    }
  }
}
