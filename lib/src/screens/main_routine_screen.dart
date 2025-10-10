import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/task.dart';
import '../router/app_router.dart';

class MainRoutineScreen extends StatefulWidget {
  const MainRoutineScreen({super.key});

  @override
  State<MainRoutineScreen> createState() => _MainRoutineScreenState();
}

class _MainRoutineScreenState extends State<MainRoutineScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _originalDuration = 0;
  DateTime? _taskStartTime;
  bool _isTimerNegative = false;

  @override
  void initState() {
    super.initState();
    // Load routine from Firebase when screen initializes
    context.read<RoutineBloc>().add(const LoadRoutineFromFirebase());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(TaskModel task) {
    _timer?.cancel();
    _taskStartTime = DateTime.now();
    _remainingSeconds = task.estimatedDuration;
    _originalDuration = task.estimatedDuration;
    _isTimerNegative = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds < 0 && !_isTimerNegative) {
            _isTimerNegative = true;
          }
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  int _getActualDuration() {
    if (_taskStartTime == null) return 0;
    return DateTime.now().difference(_taskStartTime!).inSeconds;
  }

  String _formatTimer(int seconds) {
    final isNegative = seconds < 0;
    final absoluteSeconds = seconds.abs();
    final minutes = absoluteSeconds ~/ 60;
    final secs = absoluteSeconds % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');

    return isNegative ? '-$mm:$ss' : '$mm:$ss';
  }

  double _getProgress() {
    if (_originalDuration == 0) return 0.0;
    final elapsed = _originalDuration - _remainingSeconds;
    return (elapsed / _originalDuration).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutineBloc, RoutineBlocState>(
      listener: (context, state) {
        // Start timer when routine loads or current task changes
        if (state.model != null && !state.loading) {
          final currentTask = _getCurrentTask(state);
          if (currentTask != null && !currentTask.isCompleted) {
            _startTimer(currentTask);
          } else {
            _stopTimer();
          }
        }
      },
      builder: (context, state) {
        if (state.loading) {
          return const Scaffold(
            backgroundColor: AppTheme.green,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (state.model == null || state.model!.tasks.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.green,
            body: const SafeArea(
              child: Center(
                child: Text(
                  'No tasks available.\nGo to Task Management to add tasks.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tasks),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.green,
              child: const Icon(Icons.settings),
            ),
          );
        }

        final currentTask = _getCurrentTask(state);
        if (currentTask == null) {
          return const Scaffold(
            backgroundColor: AppTheme.green,
            body: Center(
              child: Text(
                'All tasks completed!',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          );
        }

        final backgroundColor = _isTimerNegative
            ? AppTheme.red
            : AppTheme.green;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header with settings icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.tasks),
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Task name
                  Text(
                    currentTask.name,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Massive countdown timer
                  Text(
                    _formatTimer(_remainingSeconds),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -4,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Progress bar
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _getProgress(),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Action buttons
                  Row(
                    children: [
                      // Previous button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.model!.currentTaskIndex > 0
                              ? () {
                                  context.read<RoutineBloc>().add(
                                    const GoToPreviousTask(),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: backgroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Previous',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Done button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final actualDuration = _getActualDuration();
                            context.read<RoutineBloc>().add(
                              MarkTaskDone(actualDuration: actualDuration),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: backgroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  TaskModel? _getCurrentTask(RoutineBlocState state) {
    if (state.model == null ||
        state.model!.tasks.isEmpty ||
        state.model!.currentTaskIndex >= state.model!.tasks.length) {
      return null;
    }
    return state.model!.tasks[state.model!.currentTaskIndex];
  }
}
