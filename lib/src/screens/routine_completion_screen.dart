import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_completion.dart';
import '../router/app_router.dart';

class RoutineCompletionScreen extends StatelessWidget {
  const RoutineCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final completion = state.model?.completion;

        if (completion == null) {
          // If no completion data, redirect to main screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.preStart);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.green,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Celebration message
                  const Spacer(flex: 1),
                  const Text(
                    'Routine Accomplished! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Summary statistics card
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Summary',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Tasks completed
                            _SummaryRow(
                              icon: Icons.check_circle_outline,
                              label: 'Tasks Completed',
                              value: '${completion.tasksCompleted}',
                              color: AppTheme.green,
                            ),
                            const SizedBox(height: 16),

                            // Total time spent
                            _SummaryRow(
                              icon: Icons.timer_outlined,
                              label: 'Total Time Spent',
                              value: _formatDuration(completion.totalTimeSpent),
                              color: AppTheme.green,
                            ),
                            const SizedBox(height: 16),

                            // Estimated time
                            _SummaryRow(
                              icon: Icons.schedule_outlined,
                              label: 'Estimated Time',
                              value: _formatDuration(
                                completion.totalEstimatedTime,
                              ),
                              color: Colors.grey[700]!,
                            ),
                            const SizedBox(height: 16),

                            // Ahead/Behind status
                            _SummaryRow(
                              icon: completion.isAheadOfSchedule
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              label: completion.isAheadOfSchedule
                                  ? 'Ahead of Schedule'
                                  : 'Behind Schedule',
                              value: _formatDuration(
                                completion.timeDifference.abs(),
                              ),
                              color: completion.isAheadOfSchedule
                                  ? AppTheme.green
                                  : AppTheme.red,
                            ),
                            const SizedBox(height: 24),

                            // Task details
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'Task Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...completion.taskDetails.map(
                              (task) => _TaskDetailRow(task: task),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<RoutineBloc>().add(
                              const ResetRoutine(),
                            );
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.preStart);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.green,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Back to Start'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.tasks);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.9,
                            ),
                            foregroundColor: AppTheme.green,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Task Management'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TaskDetailRow extends StatelessWidget {
  const _TaskDetailRow({required this.task});

  final TaskCompletionDetail task;

  @override
  Widget build(BuildContext context) {
    final difference = task.timeDifference;
    final isFaster = difference < 0;
    final color = isFaster ? AppTheme.green : AppTheme.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              task.taskName,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              _formatDuration(task.actualDuration),
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isFaster ? Icons.arrow_downward : Icons.arrow_upward,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 60,
            child: Text(
              _formatDuration(difference.abs()),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}
