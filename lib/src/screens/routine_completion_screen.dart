import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../router/app_router.dart';

class RoutineCompletionScreen extends StatelessWidget {
  const RoutineCompletionScreen({super.key});

  String _formatDuration(int seconds) {
    final isNegative = seconds < 0;
    final absSeconds = seconds.abs();
    final hours = absSeconds ~/ 3600;
    final minutes = (absSeconds % 3600) ~/ 60;
    final secs = absSeconds % 60;

    final sign = isNegative ? '-' : '';
    if (hours > 0) {
      return '$sign${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '$sign${minutes}m ${secs}s';
    } else {
      return '$sign${secs}s';
    }
  }

  String _getScheduleStatus(int variance) {
    if (variance == 0) {
      return 'Right on schedule!';
    } else if (variance < 0) {
      return 'Ahead of schedule';
    } else {
      return 'Behind schedule';
    }
  }

  Color _getScheduleColor(int variance) {
    if (variance == 0) {
      return AppTheme.green;
    } else if (variance < 0) {
      return AppTheme.green;
    } else {
      return AppTheme.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;

        if (model == null) {
          return Scaffold(
            backgroundColor: AppTheme.green,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final completedTasks = model.completedTasksCount;
        final totalTasks = model.tasks.length;
        final totalTimeSpent = model.totalTimeSpent;
        final scheduleVariance = model.scheduleVariance;

        return Scaffold(
          backgroundColor: AppTheme.green,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Top spacing
                    const SizedBox(height: 32),

                    // Celebration icon
                    const Icon(
                      Icons.celebration,
                      size: 120,
                      color: Colors.white,
                    ),

                    const SizedBox(height: 32),

                    // Completion message
                    const Text(
                      'Morning Accomplished!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Great job completing your routine!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 64),

                    // Statistics cards
                    _StatCard(
                      icon: Icons.timer,
                      label: 'Total Time',
                      value: _formatDuration(totalTimeSpent),
                    ),

                    const SizedBox(height: 16),

                    _StatCard(
                      icon: Icons.checklist,
                      label: 'Tasks Completed',
                      value: '$completedTasks of $totalTasks',
                    ),

                    const SizedBox(height: 16),

                    _StatCard(
                      icon: Icons.schedule,
                      label: 'Schedule Status',
                      value: _getScheduleStatus(scheduleVariance),
                      valueColor: _getScheduleColor(scheduleVariance),
                      subtitle: scheduleVariance != 0
                          ? _formatDuration(scheduleVariance.abs())
                          : null,
                    ),

                    const SizedBox(height: 64),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<RoutineBloc>().add(const ResetRoutine());
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.main,
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.green,
                        ),
                        child: const Text('Start New Routine'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.tasks,
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                        ),
                        child: const Text('Manage Tasks'),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
