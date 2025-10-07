import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../router/app_router.dart';
import '../bloc/routine_bloc.dart';

class MainRoutineScreen extends StatefulWidget {
  const MainRoutineScreen({super.key});

  @override
  State<MainRoutineScreen> createState() => _MainRoutineScreenState();
}

class _MainRoutineScreenState extends State<MainRoutineScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  int _estimatedDuration = 0;
  int? _lastTaskIndex;

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
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds--;
        _elapsedSeconds++;
      });
    });
  }

  void _initializeTimerIfNeeded(int currentTaskIndex, int estimatedDuration) {
    if (_lastTaskIndex != currentTaskIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _estimatedDuration = estimatedDuration;
            _remainingSeconds = estimatedDuration;
            _elapsedSeconds = 0;
            _lastTaskIndex = currentTaskIndex;
          });
        }
      });
    }
  }

  void _resetTimer(int currentTaskIndex, int estimatedDuration) {
    setState(() {
      _estimatedDuration = estimatedDuration;
      _remainingSeconds = estimatedDuration;
      _elapsedSeconds = 0;
      _lastTaskIndex = currentTaskIndex;
    });
  }

  String _formatTime(int seconds) {
    final isNegative = seconds < 0;
    final absSeconds = seconds.abs();
    final minutes = absSeconds ~/ 60;
    final secs = absSeconds % 60;
    final sign = isNegative ? '-' : '';
    return '$sign${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    if (_estimatedDuration == 0) return 0.0;
    final progress = _elapsedSeconds / _estimatedDuration;
    return progress.clamp(0.0, 1.0);
  }

  Color _getBackgroundColor() {
    return _remainingSeconds < 0 ? AppTheme.red : AppTheme.green;
  }

  void _handleDone(BuildContext context) {
    final bloc = context.read<RoutineBloc>();
    final state = bloc.state;

    if (state.model == null) return;

    // Mark task as done with actual duration
    bloc.add(MarkTaskDone(actualDuration: _elapsedSeconds));

    // Reset timer for next task
    final nextIndex = (state.model!.currentTaskIndex + 1).clamp(
      0,
      state.model!.tasks.length - 1,
    );

    if (nextIndex < state.model!.tasks.length) {
      final nextTask = state.model!.tasks[nextIndex];
      _resetTimer(nextIndex, nextTask.estimatedDuration);
    }
  }

  void _handlePrevious(BuildContext context) {
    final bloc = context.read<RoutineBloc>();
    final state = bloc.state;

    if (state.model == null) return;

    bloc.add(const GoToPreviousTask());

    // Reset timer for previous task
    final prevIndex = (state.model!.currentTaskIndex - 1).clamp(
      0,
      state.model!.tasks.length - 1,
    );

    if (prevIndex >= 0 && prevIndex < state.model!.tasks.length) {
      final prevTask = state.model!.tasks[prevIndex];
      _resetTimer(prevIndex, prevTask.estimatedDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        if (state.loading) {
          return Scaffold(
            backgroundColor: AppTheme.green,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (state.model == null || state.model!.tasks.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.green,
            body: const Center(
              child: Text(
                'No tasks available',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            floatingActionButton: const _NavFab(),
          );
        }

        final currentIndex = state.model!.currentTaskIndex;
        final currentTask = state.model!.tasks[currentIndex];

        // Initialize timer when task changes
        _initializeTimerIfNeeded(currentIndex, currentTask.estimatedDuration);

        return Scaffold(
          backgroundColor: _getBackgroundColor(),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),

                  // Task name at top center
                  Text(
                    currentTask.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Massive countdown timer
                  Text(
                    _formatTime(_remainingSeconds),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 120,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 8,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Progress bar
                  Container(
                    height: 8,
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

                  const SizedBox(height: 60),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: currentIndex > 0
                              ? () => _handlePrevious(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.9,
                            ),
                            foregroundColor: _getBackgroundColor(),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            disabledForegroundColor: Colors.white.withValues(
                              alpha: 0.5,
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
                          onPressed: () => _handleDone(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _getBackgroundColor(),
                            padding: const EdgeInsets.symmetric(vertical: 20),
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
          floatingActionButton: const _NavFab(),
        );
      },
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
        if (selected != null) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushNamed(selected);
        }
      },
      label: const Text('Navigate'),
      icon: const Icon(Icons.navigation),
    );
  }
}
