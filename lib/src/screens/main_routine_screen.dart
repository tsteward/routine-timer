import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_state.dart';
import '../router/app_router.dart';
import '../widgets/task_drawer.dart';

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
  bool _isOnBreak = false;
  bool _isDrawerExpanded = false;

  @override
  void initState() {
    super.initState();
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

        // Check if break time is complete
        _checkBreakCompletion();
      }
    });
  }

  void _checkBreakCompletion() {
    // Access the current bloc state
    final model = context.read<RoutineBloc>().state.model;
    if (model == null || !model.isOnBreak) return;

    final currentBreak = model.currentBreak;
    if (currentBreak == null) return;

    // If break duration has elapsed, automatically complete the break
    if (_elapsedSeconds >= currentBreak.duration) {
      context.read<RoutineBloc>().add(const CompleteBreak());
    }
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
        // Reset timer when task index changes or when entering/exiting break
        final currentIndex = state.model?.currentTaskIndex;
        final isOnBreak = state.model?.isOnBreak ?? false;

        if (currentIndex != null &&
            (_previousTaskIndex != currentIndex || isOnBreak != _isOnBreak)) {
          _resetTimer();
          _previousTaskIndex = currentIndex;
          _isOnBreak = isOnBreak;
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

        // Check if we're on a break
        if (model.isOnBreak) {
          return _buildBreakScreen(context, model);
        }

        // Normal task screen
        return _buildTaskScreen(context, model);
      },
    );
  }

  Widget _buildTaskScreen(BuildContext context, RoutineStateModel model) {
    final currentTask = model.tasks[model.currentTaskIndex];
    final remainingSeconds = currentTask.estimatedDuration - _elapsedSeconds;
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
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
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
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: backgroundColor,
                              disabledBackgroundColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              disabledForegroundColor: Colors.white.withValues(
                                alpha: 0.5,
                              ),
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
                              final actualDuration = _calculateActualDuration();
                              context.read<RoutineBloc>().add(
                                MarkTaskDone(actualDuration: actualDuration),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
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
  }

  Widget _buildBreakScreen(BuildContext context, RoutineStateModel model) {
    final currentBreak = model.currentBreak;
    if (currentBreak == null) {
      // Shouldn't happen, but fall back to task screen
      return _buildTaskScreen(context, model);
    }

    final remainingSeconds = currentBreak.duration - _elapsedSeconds;

    return Scaffold(
      backgroundColor: AppTheme.green,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Break message at top
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.coffee, color: Colors.white, size: 80),
                      const SizedBox(height: 16),
                      const Text(
                        'Break Time',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Break countdown timer
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
                    value: currentBreak.duration > 0
                        ? (_elapsedSeconds / currentBreak.duration).clamp(
                            0.0,
                            1.0,
                          )
                        : 0.0,
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

              const SizedBox(height: 16),

              // Next task info
              if (model.currentTaskIndex + 1 < model.tasks.length)
                Text(
                  'Up Next: ${model.tasks[model.currentTaskIndex + 1].name}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 120),
            ],
          ),
        ),
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
