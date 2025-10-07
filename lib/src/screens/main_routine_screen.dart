import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../router/app_router.dart';
import '../utils/time_formatter.dart';

class MainRoutineScreen extends StatefulWidget {
  const MainRoutineScreen({super.key});

  @override
  State<MainRoutineScreen> createState() => _MainRoutineScreenState();
}

class _MainRoutineScreenState extends State<MainRoutineScreen> {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _initialDuration = 0;
  bool _isInitialized = false;

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _loadTaskDuration(int duration) {
    if (!_isInitialized || _initialDuration != duration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _remainingSeconds = duration;
            _initialDuration = duration;
            _isInitialized = true;
          });
        }
      });
    }
  }

  void _resetTimerForTask(int duration) {
    setState(() {
      _remainingSeconds = duration;
      _initialDuration = duration;
      _isInitialized = true;
    });
  }

  double _getProgress() {
    if (_initialDuration == 0) return 0.0;
    // Calculate progress based on elapsed time
    final elapsed = _initialDuration - _remainingSeconds;
    final progress = elapsed / _initialDuration;
    return progress.clamp(0.0, 1.0);
  }

  Color _getBackgroundColor() {
    return _remainingSeconds < 0 ? AppTheme.red : AppTheme.green;
  }

  void _handleDonePressed(BuildContext context, RoutineBlocState state) {
    if (state.model == null || state.model!.tasks.isEmpty) return;

    final actualDuration = _initialDuration - _remainingSeconds;
    context.read<RoutineBloc>().add(MarkTaskDone(actualDuration: actualDuration));

    // Reset timer for next task
    if (state.model!.currentTaskIndex < state.model!.tasks.length - 1) {
      final nextTask = state.model!.tasks[state.model!.currentTaskIndex + 1];
      _resetTimerForTask(nextTask.estimatedDuration);
    }
  }

  void _handlePreviousPressed(BuildContext context, RoutineBlocState state) {
    if (state.model == null || state.model!.currentTaskIndex == 0) return;

    context.read<RoutineBloc>().add(const GoToPreviousTask());

    // Reset timer for previous task
    final prevTask = state.model!.tasks[state.model!.currentTaskIndex - 1];
    _resetTimerForTask(prevTask.estimatedDuration);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        
        // Show loading or empty state
        if (model == null || model.tasks.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.green,
            body: const SafeArea(
              child: Center(
                child: Text(
                  'No tasks available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            floatingActionButton: const _NavFab(),
          );
        }

        final currentTask = model.tasks[model.currentTaskIndex];
        
        // Initialize timer with current task duration
        _loadTaskDuration(currentTask.estimatedDuration);

        return Scaffold(
          backgroundColor: _getBackgroundColor(),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  
                  // Task Name Display
                  Text(
                    currentTask.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.0,
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Massive Countdown Timer
                  Text(
                    TimeFormatter.formatTimerMMSS(_remainingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -4.0,
                      height: 1.0,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Slim Progress Bar
                  SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _getProgress(),
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Previous and Done Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous Button
                      ElevatedButton(
                        onPressed: model.currentTaskIndex > 0
                            ? () => _handlePreviousPressed(context, state)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _getBackgroundColor(),
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                          disabledForegroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
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
                      
                      const SizedBox(width: 24),
                      
                      // Done Button
                      ElevatedButton(
                        onPressed: () => _handleDonePressed(context, state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _getBackgroundColor(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 20,
                          ),
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
                    ],
                  ),
                  
                  const Spacer(flex: 3),
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
