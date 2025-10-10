import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/completion_summary.dart';
import '../router/app_router.dart';
import '../utils/time_formatter.dart';

class CompletionScreen extends StatelessWidget {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final summary = state.completionSummary;

        if (summary == null) {
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
                      child: const Text('Return to Tasks'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: summary.isAheadOfSchedule
              ? AppTheme.green
              : AppTheme.red,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Celebration header
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.celebration,
                            color: Colors.white,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${summary.routineName} Accomplished!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getStatusMessage(summary),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Summary statistics
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _SummaryCard(
                            title: 'Time Summary',
                            children: [
                              _StatRow(
                                label: 'Total Time Spent',
                                value: TimeFormatter.formatDuration(
                                  summary.totalTimeSpent,
                                ),
                              ),
                              _StatRow(
                                label: 'Estimated Time',
                                value: TimeFormatter.formatDuration(
                                  summary.totalEstimatedTime,
                                ),
                              ),
                              _StatRow(
                                label: 'Difference',
                                value: _formatTimeDifference(
                                  summary.timeDifference,
                                ),
                                valueColor: summary.isAheadOfSchedule
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _SummaryCard(
                            title: 'Task Summary',
                            children: [
                              _StatRow(
                                label: 'Tasks Completed',
                                value:
                                    '${summary.tasksCompleted}/${summary.totalTasks}',
                              ),
                              _StatRow(
                                label: 'Completion Rate',
                                value:
                                    '${(summary.completionPercentage * 100).toInt()}%',
                              ),
                              _StatRow(
                                label: 'Completed At',
                                value: _formatCompletionTime(
                                  summary.completedAt,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _TaskBreakdownCard(summary: summary),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Reset routine button
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<RoutineBloc>().add(
                                      const ResetRoutine(),
                                    );
                                    Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.main);
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Start Over'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: Colors.white,
                                    foregroundColor: summary.isAheadOfSchedule
                                        ? AppTheme.green
                                        : AppTheme.red,
                                  ),
                                ),
                              ),
                            ),

                            // Return to tasks button
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<RoutineBloc>().add(
                                      const ReturnToTaskManagement(),
                                    );
                                    Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.tasks);
                                  },
                                  icon: const Icon(Icons.list_alt),
                                  label: const Text('Manage Tasks'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    backgroundColor: Colors.white,
                                    foregroundColor: summary.isAheadOfSchedule
                                        ? AppTheme.green
                                        : AppTheme.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusMessage(CompletionSummary summary) {
    if (summary.isAheadOfSchedule) {
      final minutes = (summary.timeDifference.abs() / 60).floor();
      return 'Finished $minutes minutes ahead of schedule!';
    } else {
      final minutes = (summary.timeDifference / 60).floor();
      return 'Finished $minutes minutes behind schedule';
    }
  }

  String _formatTimeDifference(int timeDifference) {
    final isNegative = timeDifference < 0;
    final absTime = timeDifference.abs();
    final formatted = TimeFormatter.formatDuration(absTime);
    return isNegative ? '-$formatted' : '+$formatted';
  }

  String _formatCompletionTime(DateTime completedAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completionDate = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
    );

    final timeStr =
        '${completedAt.hour.toString().padLeft(2, '0')}:'
        '${completedAt.minute.toString().padLeft(2, '0')}';

    if (completionDate == today) {
      return 'Today at $timeStr';
    } else {
      return '${completedAt.day}/${completedAt.month}/${completedAt.year} at $timeStr';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskBreakdownCard extends StatelessWidget {
  const _TaskBreakdownCard({required this.summary});

  final CompletionSummary summary;

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      title: 'Task Breakdown',
      children: [
        ...summary.tasks.map(
          (task) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Icon(
                  task.wasCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: task.wasCompleted ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: task.wasCompleted ? Colors.black87 : Colors.grey,
                      decoration: task.wasCompleted
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                if (task.wasCompleted) ...[
                  Text(
                    TimeFormatter.formatDuration(task.actualDuration),
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.wasFaster ? '↓' : '↑',
                    style: TextStyle(
                      fontSize: 14,
                      color: task.wasFaster ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
