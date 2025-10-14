import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_completion.dart';
import '../router/app_router.dart';

/// Screen displayed when all tasks in the routine are completed.
/// Shows completion summary with statistics and options to reset or return to task management.
class RoutineCompletionScreen extends StatelessWidget {
  const RoutineCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final completion = state.completion;

        if (completion == null) {
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

        return Scaffold(
          backgroundColor: AppTheme.green,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Celebration message
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 120,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Routine Accomplished!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Summary statistics card
                  _SummaryCard(completion: completion),

                  const SizedBox(height: 48),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reset and start again button
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
                              ).pushReplacementNamed(AppRoutes.main);
                            },
                            icon: const Icon(Icons.refresh, size: 28),
                            label: const Text('Start Again'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.green,
                            ),
                          ),
                        ),
                      ),

                      // Go to task management button
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.tasks);
                            },
                            icon: const Icon(Icons.settings, size: 28),
                            label: const Text('Manage Tasks'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.9,
                              ),
                              foregroundColor: AppTheme.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Card displaying completion summary statistics
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.completion});

  final RoutineCompletion completion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.green,
            ),
          ),
          const SizedBox(height: 24),

          // Total time spent
          _StatRow(
            icon: Icons.timer,
            label: 'Total Time',
            value: completion.formattedTotalTime,
          ),
          const SizedBox(height: 16),

          // Tasks completed
          _StatRow(
            icon: Icons.check_box,
            label: 'Tasks Completed',
            value: '${completion.tasksCompleted}',
          ),
          const SizedBox(height: 16),

          // Schedule status
          _StatRow(
            icon: completion.scheduleVariance >= 0
                ? Icons.trending_up
                : Icons.trending_down,
            label: 'Schedule',
            value: completion.statusText,
            valueColor: completion.scheduleVariance >= 0
                ? AppTheme.green
                : AppTheme.red,
          ),
        ],
      ),
    );
  }
}

/// Row displaying a single statistic
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 32, color: AppTheme.green),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 20, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
