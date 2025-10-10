import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_theme.dart';
import '../bloc/routine_bloc.dart';
import '../models/routine_state.dart';
import '../router/app_router.dart';
import '../widgets/upcoming_tasks_drawer.dart';

class MainRoutineScreen extends StatefulWidget {
  const MainRoutineScreen({super.key});

  @override
  State<MainRoutineScreen> createState() => _MainRoutineScreenState();
}

class _MainRoutineScreenState extends State<MainRoutineScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  DateTime? _startTime;
  int? _previousTaskIndex;
  bool? _wasOnBreak;

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
    _startTime = DateTime.now();
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
      _startTime = DateTime.now();
    });
  }

  int _calculateActualDuration() {
    if (_startTime == null) return _elapsedSeconds;
    return DateTime.now().difference(_startTime!).inSeconds;
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
        // Reset timer when task index changes or break state changes
        final currentIndex = state.model?.currentTaskIndex;
        final isOnBreak = state.model?.isOnBreak ?? false;
        
        if ((currentIndex != null && _previousTaskIndex != currentIndex) ||
            (_wasOnBreak != null && _wasOnBreak != isOnBreak)) {
          _resetTimer();
          _previousTaskIndex = currentIndex;
          _wasOnBreak = isOnBreak;
        }
      },
      builder: (context, state) {
        final model = state.model;

        if (model == null || model.tasks.isEmpty) {
          return _buildNoTasksScreen(context);
        }

        // Handle break state
        if (model.isOnBreak && model.currentBreakIndex != null) {
          return _buildBreakScreen(context, model);
        }

        // Handle regular task state
        return _buildTaskScreen(context, model);
      },
    );
  }

  Widget _buildNoTasksScreen(BuildContext context) {
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

  Widget _buildBreakScreen(BuildContext context, RoutineStateModel model) {
    final breakIndex = model.currentBreakIndex!;
    final currentBreak = model.breaks![breakIndex];
    final remainingSeconds = currentBreak.duration - _elapsedSeconds;
    
    // Auto-complete break when timer reaches zero
    if (remainingSeconds <= 0 && _elapsedSeconds > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<RoutineBloc>().add(const CompleteBreak());
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.green, // Keep background green during break
      endDrawer: UpcomingTasksDrawer(model: model),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Break message at top center
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Break Time!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Get ready for: ${_getNextTaskName(model)}',
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

              // Skip break button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SizedBox(
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
              ),

              const SizedBox(height: 32),

              // Break counter
              Text(
                'Break ${breakIndex + 1} of ${model.breaks?.length ?? 0}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const _NavFab(),
    );
  }

  String _getNextTaskName(RoutineStateModel model) {
    final nextIndex = model.currentTaskIndex + 1;
    if (nextIndex < model.tasks.length) {
      return model.tasks[nextIndex].name;
    }
    return 'Routine Complete';
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
      endDrawer: UpcomingTasksDrawer(model: model),
      body: SafeArea(
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drawer button
        FloatingActionButton(
          heroTag: "drawer_fab",
          mini: true,
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
          child: const Icon(Icons.list),
        ),
        const SizedBox(width: 8),
        // Navigation menu button
        FloatingActionButton.extended(
          heroTag: "nav_fab",
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
        ),
      ],
    );
  }
}
