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
  final Map<String, int> _elapsedByTaskId = <String, int>{};

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final state = context.read<RoutineBloc>().state;
      final model = state.model;
      if (model == null || model.tasks.isEmpty) return;
      final currentIndex = model.currentTaskIndex.clamp(
        0,
        model.tasks.length - 1,
      );
      final currentTask = model.tasks[currentIndex];
      final current = _elapsedByTaskId[currentTask.id] ?? 0;
      _elapsedByTaskId[currentTask.id] = current + 1;
      setState(() {});
    });
  }

  int _getElapsed(String taskId) => _elapsedByTaskId[taskId] ?? 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null || model.tasks.isEmpty) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        final currentIndex = model.currentTaskIndex.clamp(
          0,
          model.tasks.length - 1,
        );
        final task = model.tasks[currentIndex];
        final estimated = task.estimatedDuration;
        final elapsed = _getElapsed(task.id);
        final remaining = estimated - elapsed; // can go negative
        final isOver = remaining < 0;

        // Progress (0..1). If negative, keep advancing beyond 1.0
        final progress = elapsed / (estimated == 0 ? 1 : estimated);

        final bgColor = isOver ? AppTheme.red : AppTheme.green;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Task name at top center
                  Text(
                    task.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),

                  // Massive countdown timer
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      TimeFormatter.formatMinutesSecondsSigned(remaining),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 140,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Slim progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Previous / Done buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          onPressed: () {
                            context.read<RoutineBloc>().add(
                              const GoToPreviousTask(),
                            );
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: bgColor,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          onPressed: () {
                            final actual = _getElapsed(task.id);
                            // Reset next task's elapsed so it starts fresh
                            final nextIndex = (currentIndex + 1).clamp(
                              0,
                              model.tasks.length - 1,
                            );
                            if (nextIndex != currentIndex) {
                              final nextTask = model.tasks[nextIndex];
                              _elapsedByTaskId[nextTask.id] = 0;
                            }

                            context.read<RoutineBloc>().add(
                              MarkTaskDone(actualDuration: actual),
                            );
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Done'),
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
    return PopupMenuButton<String>(
      icon: const Icon(Icons.navigation, color: Colors.white),
      color: Colors.white,
      onSelected: (route) => Navigator.of(context).pushNamed(route),
      itemBuilder: (context) => const [
        PopupMenuItem(value: AppRoutes.preStart, child: Text('Pre-Start')),
        PopupMenuItem(value: AppRoutes.main, child: Text('Main Routine')),
        PopupMenuItem(value: AppRoutes.tasks, child: Text('Task Management')),
      ],
    );
  }
}
