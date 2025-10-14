import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_completion.dart';
import '../router/app_router.dart';
import '../utils/time_formatter.dart';

class RoutineCompletionScreen extends StatelessWidget {
  const RoutineCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final completionData = state.completionData;

        if (completionData == null) {
          // Shouldn't happen, but handle gracefully
          return Scaffold(
            backgroundColor: AppTheme.green,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No completion data available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.tasks);
                      },
                      child: const Text('Go to Task Management'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _CompletionContent(completionData: completionData);
      },
    );
  }
}

class _CompletionContent extends StatelessWidget {
  const _CompletionContent({required this.completionData});

  final RoutineCompletionModel completionData;

  String _formatDuration(int seconds) {
    return TimeFormatter.formatDuration(seconds);
  }

  String _formatTimeDifference(int seconds) {
    final isAhead = seconds > 0;
    final absSeconds = seconds.abs();
    final formatted = _formatDuration(absSeconds);
    return isAhead ? '$formatted ahead' : '$formatted behind';
  }

  @override
  Widget build(BuildContext context) {
    final timeDiff = completionData.timeDifference;
    final isAhead = completionData.isAhead;
    final backgroundColor = isAhead ? AppTheme.green : AppTheme.red;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Success icon
              const Icon(
                Icons.check_circle_outline,
                size: 120,
                color: Colors.white,
              ),

              const SizedBox(height: 24),

              // "Morning Accomplished!" message
              const Text(
                'Morning Accomplished!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Summary statistics card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Total time spent
                    _StatRow(
                      icon: Icons.timer,
                      label: 'Total Time',
                      value: _formatDuration(completionData.totalTimeSpent),
                      color: backgroundColor,
                    ),

                    const SizedBox(height: 16),

                    // Tasks completed
                    _StatRow(
                      icon: Icons.check_box,
                      label: 'Tasks Completed',
                      value: '${completionData.totalTasksCompleted}',
                      color: backgroundColor,
                    ),

                    const SizedBox(height: 16),

                    // Estimated time
                    _StatRow(
                      icon: Icons.schedule,
                      label: 'Estimated Time',
                      value: _formatDuration(completionData.totalEstimatedTime),
                      color: backgroundColor,
                    ),

                    const SizedBox(height: 16),

                    // Ahead/Behind status
                    _StatRow(
                      icon: isAhead ? Icons.trending_up : Icons.trending_down,
                      label: 'Performance',
                      value: _formatTimeDifference(timeDiff),
                      color: backgroundColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Task details (if available)
              if (completionData.tasksDetails != null &&
                  completionData.tasksDetails!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Breakdown',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...completionData.tasksDetails!.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _TaskDetailRow(
                            task: task,
                            accentColor: backgroundColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
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
                        backgroundColor: Colors.white,
                        foregroundColor: backgroundColor,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Start New Session'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.tasks,
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: Colors.white,
                        foregroundColor: backgroundColor,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Manage Tasks'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskDetailRow extends StatelessWidget {
  const _TaskDetailRow({required this.task, required this.accentColor});

  final TaskCompletionDetail task;
  final Color accentColor;

  String _formatDuration(int seconds) {
    return TimeFormatter.formatDuration(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final diff = task.timeDifference;
    final isFaster = diff > 0;
    final diffText = isFaster
        ? '-${_formatDuration(diff.abs())}'
        : '+${_formatDuration(diff.abs())}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.taskName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(task.actualDuration)} / ${_formatDuration(task.estimatedDuration)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFaster
                  ? AppTheme.green.withValues(alpha: 0.2)
                  : AppTheme.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              diffText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isFaster ? AppTheme.green : AppTheme.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
