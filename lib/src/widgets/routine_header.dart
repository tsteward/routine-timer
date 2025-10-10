import 'package:flutter/material.dart';
import '../services/schedule_tracking_service.dart';
import '../models/routine_state.dart';
import '../router/app_router.dart';

class RoutineHeader extends StatelessWidget {
  const RoutineHeader({
    super.key,
    required this.model,
    required this.routineStartTime,
    required this.currentTaskElapsedSeconds,
  });

  final RoutineStateModel model;
  final DateTime routineStartTime;
  final int currentTaskElapsedSeconds;

  @override
  Widget build(BuildContext context) {
    final scheduleService = ScheduleTrackingService();
    final scheduleStatus = scheduleService.calculateScheduleStatus(
      model,
      routineStartTime,
      currentTaskElapsedSeconds,
    );
    final estimatedCompletion = scheduleService.calculateEstimatedCompletion(
      model,
      routineStartTime,
      currentTaskElapsedSeconds,
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Schedule status card (left side)
          Expanded(
            child: _ScheduleStatusCard(
              scheduleStatus: scheduleStatus,
              estimatedCompletion: estimatedCompletion,
            ),
          ),

          const SizedBox(width: 16),

          // Settings icon (right side)
          _SettingsButton(),
        ],
      ),
    );
  }
}

class _ScheduleStatusCard extends StatelessWidget {
  const _ScheduleStatusCard({
    required this.scheduleStatus,
    required this.estimatedCompletion,
  });

  final ScheduleStatus scheduleStatus;
  final DateTime estimatedCompletion;

  Color _getStatusColor() {
    switch (scheduleStatus.type) {
      case ScheduleStatusType.ahead:
        return Colors.green;
      case ScheduleStatusType.behind:
        return Colors.red;
      case ScheduleStatusType.onTrack:
        return Colors.blue;
    }
  }

  String _formatEstimatedCompletion() {
    final hour = estimatedCompletion.hour;
    final minute = estimatedCompletion.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Schedule status
          Row(
            children: [
              Icon(_getStatusIcon(), color: _getStatusColor(), size: 20),
              const SizedBox(width: 8),
              Text(
                scheduleStatus.displayText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Estimated completion time
          Text(
            'Est. Completion: ${_formatEstimatedCompletion()}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

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

class _SettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: IconButton(
        icon: const Icon(Icons.settings),
        color: Colors.grey[700],
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.tasks);
        },
      ),
    );
  }
}
