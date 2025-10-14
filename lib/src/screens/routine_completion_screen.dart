import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_completion.dart';
import '../router/app_router.dart';

class RoutineCompletionScreen extends StatelessWidget {
  const RoutineCompletionScreen({required this.completion, super.key});

  final RoutineCompletion completion;

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

  String _formatVariance(int seconds) {
    final absSeconds = seconds.abs();
    final minutes = absSeconds ~/ 60;
    final secs = absSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  String _getScheduleStatusMessage() {
    switch (completion.scheduleStatus) {
      case 'ahead':
        return 'Ahead by ${_formatVariance(completion.scheduleVarianceSeconds)}';
      case 'behind':
        return 'Behind by ${_formatVariance(completion.scheduleVarianceSeconds.abs())}';
      case 'on-track':
        return 'Right on schedule!';
      default:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.green,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success message
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 120,
                ),
                const SizedBox(height: 24),
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
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Total time spent
                      _buildStatRow(
                        'Total Time',
                        _formatDuration(completion.totalTimeSpent),
                        Icons.timer,
                      ),
                      const SizedBox(height: 24),

                      // Tasks completed
                      _buildStatRow(
                        'Tasks Completed',
                        '${completion.tasksCompleted}',
                        Icons.task_alt,
                      ),
                      const SizedBox(height: 24),

                      // Schedule status
                      _buildStatRow(
                        'Schedule Status',
                        _getScheduleStatusMessage(),
                        completion.scheduleStatus == 'ahead'
                            ? Icons.trending_up
                            : completion.scheduleStatus == 'behind'
                            ? Icons.trending_down
                            : Icons.check_circle,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Action buttons
                ElevatedButton(
                  onPressed: () {
                    // Reset routine and go back to task management
                    context.read<RoutineBloc>().add(const ResetRoutine());
                    Navigator.of(context).pushReplacementNamed(AppRoutes.tasks);
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
                  child: const Text('Return to Task Management'),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () {
                    // Reset routine and go to main screen to start over
                    context.read<RoutineBloc>().add(const ResetRoutine());
                    Navigator.of(context).pushReplacementNamed(AppRoutes.main);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Another Routine'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
