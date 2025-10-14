import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../router/app_router.dart';
import '../utils/time_formatter.dart';

class CompletionScreen extends StatelessWidget {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;

        if (model == null ||
            !model.isCompleted ||
            model.completionData == null) {
          // If not completed, redirect to main screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.main);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final completion = model.completionData!;
        final timeDiff = completion.timeDifference;
        final isAhead = completion.isAheadOfSchedule;

        return Scaffold(
          backgroundColor: AppTheme.green,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 32),

                    // Completion message
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 72),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${completion.routineName} Accomplished!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Summary statistics
                    _SummaryCard(
                      children: [
                        _SummaryItem(
                          label: 'Tasks Completed',
                          value: '${completion.tasksCompleted}',
                          icon: Icons.check_circle,
                        ),
                        const Divider(height: 32, color: Colors.white24),
                        _SummaryItem(
                          label: 'Total Time',
                          value: TimeFormatter.formatDurationHoursMinutes(
                            completion.totalActualDuration,
                          ),
                          icon: Icons.timer,
                        ),
                        const Divider(height: 32, color: Colors.white24),
                        _SummaryItem(
                          label: 'Time Difference',
                          value:
                              '${isAhead ? '' : '+'}${TimeFormatter.formatDurationHoursMinutes(timeDiff.abs())}',
                          subtitle: isAhead
                              ? 'Ahead of schedule'
                              : 'Behind schedule',
                          icon: isAhead
                              ? Icons.trending_up
                              : Icons.trending_down,
                          valueColor: isAhead
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 64),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.tasks);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.green,
                        ),
                        child: const Text('Return to Task Management'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // Reset routine
                          context.read<RoutineBloc>().add(const ResetRoutine());
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.main);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                        ),
                        child: const Text('Start New Routine'),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: valueColor?.withValues(alpha: 0.8) ?? Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
