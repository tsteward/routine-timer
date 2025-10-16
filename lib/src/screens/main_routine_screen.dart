import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_state.dart';
import '../router/app_router.dart';
import '../widgets/task_drawer.dart';
import '../widgets/schedule_header.dart';

class MainRoutineScreen extends StatefulWidget {
  const MainRoutineScreen({super.key});

  @override
  State<MainRoutineScreen> createState() => _MainRoutineScreenState();
}

class _MainRoutineScreenState extends State<MainRoutineScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  DateTime? _taskStartTime;
  int? _previousTaskIndex;
  bool? _previousBreakState;
  bool _isDrawerExpanded = false;
  DateTime? _routineStartTime;

  @override
  void initState() {
    super.initState();
    _routineStartTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _taskStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _elapsedSeconds = 0;
      _taskStartTime = DateTime.now();
    });
  }

  int _calculateActualDuration() {
    if (_taskStartTime == null) return _elapsedSeconds;
    return DateTime.now().difference(_taskStartTime!).inSeconds;
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerExpanded = !_isDrawerExpanded;
    });
  }

  String _formatTime(int totalSeconds) {
    final isNegative = totalSeconds < 0;
    final absSeconds = totalSeconds.abs();
    final minutes = absSeconds ~/ 60;
    final seconds = absSeconds % 60;
    final sign = isNegative ? '-' : '';
    return '$sign${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutineBloc, RoutineBlocState>(
      listener: (context, state) {
        // Navigate to completion screen if routine is completed
        if (state.model?.isCompleted == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.completion);
            }
          });
          return;
        }

        // Reset timer when task index changes or break state changes
        final currentIndex = state.model?.currentTaskIndex;
        final isOnBreak = state.model?.isOnBreak ?? false;

        if ((currentIndex != null && _previousTaskIndex != currentIndex) ||
            (_previousBreakState != null && _previousBreakState != isOnBreak)) {
          _resetTimer();
          _previousTaskIndex = currentIndex;
          _previousBreakState = isOnBreak;
        }
      },
      builder: (context, state) {
        final model = state.model;

        if (model == null || model.tasks.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.green,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No tasks available',
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
            floatingActionButton: const _NavFab(),
          );
        }

        // Check if on break
        if (model.isOnBreak) {
          return _buildBreakScreen(context, model);
        }

        final currentTask = model.tasks[model.currentTaskIndex];
        final remainingSeconds =
            currentTask.estimatedDuration - _elapsedSeconds;
        final isNegative = remainingSeconds < 0;
        final backgroundColor = isNegative ? AppTheme.red : AppTheme.green;

        // Calculate progress (0.0 to 1.0, clamped)
        final progress = currentTask.estimatedDuration > 0
            ? (_elapsedSeconds / currentTask.estimatedDuration).clamp(0.0, 1.0)
            : 0.0;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Header with schedule status and settings icon
                      ScheduleHeader(
                        routineState: model,
                        routineStartTime: _routineStartTime ?? DateTime.now(),
                        currentTaskElapsedSeconds: _elapsedSeconds,
                        onSettingsTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.tasks);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Task name at top center
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            currentTask.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Massive countdown timer
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            _formatTime(remainingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 300,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),

                      // Slim progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Previous and Done buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Previous button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton(
                                onPressed: model.currentTaskIndex > 0
                                    ? () {
                                        context.read<RoutineBloc>().add(
                                          const GoToPreviousTask(),
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: backgroundColor,
                                  disabledBackgroundColor: Colors.white
                                      .withValues(alpha: 0.3),
                                  disabledForegroundColor: Colors.white
                                      .withValues(alpha: 0.5),
                                ),
                                child: const Text('Previous'),
                              ),
                            ),
                          ),

                          // Done button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  final actualDuration =
                                      _calculateActualDuration();
                                  context.read<RoutineBloc>().add(
                                    MarkTaskDone(
                                      actualDuration: actualDuration,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: backgroundColor,
                                ),
                                child: const Text('Done'),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Task counter
                      Text(
                        'Task ${model.currentTaskIndex + 1} of ${model.tasks.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),

                      // Add some bottom padding to make room for drawer
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),

              // Task drawer overlay
              TaskDrawer(
                routineState: model,
                isExpanded: _isDrawerExpanded,
                onToggleExpanded: _toggleDrawer,
              ),
            ],
          ),
          floatingActionButton: const _NavFab(),
        );
      },
    );
  }

  Widget _buildBreakScreen(BuildContext context, RoutineStateModel model) {
    final currentBreak = model.currentBreak;
    if (currentBreak == null) {
      // Shouldn't happen, but handle gracefully
      return Scaffold(
        backgroundColor: AppTheme.green,
        body: const Center(child: CircularProgressIndicator()),
        floatingActionButton: const _NavFab(),
      );
    }

    final remainingSeconds = currentBreak.duration - _elapsedSeconds;
    final progress = currentBreak.duration > 0
        ? (_elapsedSeconds / currentBreak.duration).clamp(0.0, 1.0)
        : 0.0;

    // Automatically complete break when time runs out
    if (remainingSeconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RoutineBloc>().add(const CompleteBreak());
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.green, // Keep green during break
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header with schedule status and settings icon
                  ScheduleHeader(
                    routineState: model,
                    routineStartTime: _routineStartTime ?? DateTime.now(),
                    currentTaskElapsedSeconds: _elapsedSeconds,
                    onSettingsTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.tasks);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Break title at top
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Break Time',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Take a moment to relax',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Massive countdown timer
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        _formatTime(remainingSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 300,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Skip break button
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<RoutineBloc>().add(const SkipBreak());
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
                        child: const Text('Skip Break'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Break info text
                  Text(
                    'Break ${(model.currentBreakIndex ?? 0) + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // Task drawer overlay
          TaskDrawer(
            routineState: model,
            isExpanded: _isDrawerExpanded,
            onToggleExpanded: _toggleDrawer,
          ),
        ],
      ),
      floatingActionButton: const _NavFab(),
    );
  }
}

class _NavFab extends StatelessWidget {
  const _NavFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        final selected = await showMenu<String>(
          context: context,
          position: const RelativeRect.fromLTRB(1000, 0, 16, 0),
          items: const [
            PopupMenuItem(value: AppRoutes.preStart, child: Text('Pre-Start')),
            PopupMenuItem(value: AppRoutes.main, child: Text('Main Routine')),
            PopupMenuItem(
              value: AppRoutes.tasks,
              child: Text('Task Management'),
            ),
          ],
        );
        if (selected != null && context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushNamed(selected);
        }
      },
      label: const Text('Navigate'),
      icon: const Icon(Icons.navigation),
    );
  }
}
