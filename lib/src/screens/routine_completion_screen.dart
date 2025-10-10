import 'dart:math' as math;

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
    return BlocConsumer<RoutineBloc, RoutineBlocState>(
      listener: (context, state) {
        // If we've reset the routine, navigate back to pre-start
        if (!state.isCompleted && state.completionData == null) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.preStart,
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final completionData = state.completionData;
        
        if (completionData == null) {
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
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.preStart,
                          (route) => false,
                        );
                      },
                      child: const Text('Return to Start'),
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Celebration header
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Celebration icon/animation
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 80,
                            color: AppTheme.green,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Main completion message
                        const Text(
                          'Morning Accomplished!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Subtitle with completion status
                        Text(
                          completionData.isFullyCompleted
                              ? 'All ${completionData.totalTasks} tasks completed!'
                              : '${completionData.tasksCompleted} of ${completionData.totalTasks} tasks completed',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Statistics section
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Summary Statistics',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Stats grid
                          Expanded(
                            child: _buildStatsGrid(completionData),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Ahead/behind status
                          _buildAheadBehindStatus(completionData),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      // Task management button
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(AppRoutes.tasks);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.green,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Manage Tasks'),
                          ),
                        ),
                      ),

                      // Reset routine button  
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<RoutineBloc>().add(const ResetRoutine());
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.green,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Start Fresh'),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Save indicator (if saving)
                  if (state.saving)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Saving completion data...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
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

  Widget _buildStatsGrid(RoutineCompletionModel completion) {
    return Column(
      children: [
        // First row: Total time and Tasks completed
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Time',
                _formatDuration(completion.totalTimeSpent),
                Icons.access_time,
                AppTheme.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Tasks Done',
                '${completion.tasksCompleted}/${completion.totalTasks}',
                Icons.check_circle_outline,
                AppTheme.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Second row: Completion rate and Performance
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Completion',
                '${((completion.tasksCompleted / completion.totalTasks) * 100).round()}%',
                Icons.pie_chart,
                completion.isFullyCompleted ? AppTheme.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                'Performance',
                completion.finalAheadBehindStatus == 0 
                    ? 'On Time' 
                    : completion.finalAheadBehindStatus > 0 
                        ? 'Ahead' 
                        : 'Behind',
                completion.finalAheadBehindStatus >= 0 ? Icons.trending_up : Icons.trending_down,
                completion.finalAheadBehindStatus >= 0 ? AppTheme.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAheadBehindStatus(RoutineCompletionModel completion) {
    final isAhead = completion.finalAheadBehindStatus > 0;
    final isBehind = completion.finalAheadBehindStatus < 0;
    final isOnTime = completion.finalAheadBehindStatus == 0;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isOnTime) {
      statusColor = AppTheme.green;
      statusIcon = Icons.schedule;
      statusText = 'Perfect timing!';
    } else if (isAhead) {
      statusColor = AppTheme.green;
      statusIcon = Icons.flash_on;
      statusText = 'Great job finishing early!';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.watch_later;
      statusText = 'Room for improvement next time!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                completion.aheadBehindText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              color: statusColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}