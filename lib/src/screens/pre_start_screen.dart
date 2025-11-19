import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/routine_bloc.dart';
import '../router/app_router.dart';
import '../utils/time_formatter.dart';

class PreStartScreen extends StatefulWidget {
  const PreStartScreen({super.key});

  @override
  State<PreStartScreen> createState() => _PreStartScreenState();
}

class _PreStartScreenState extends State<PreStartScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final routineBloc = context.read<RoutineBloc>();
      final model = routineBloc.state.model;

      // If no model loaded yet, just wait (don't navigate)
      if (model == null) {
        return;
      }

      // Calculate time until start
      final startTime = DateTime.fromMillisecondsSinceEpoch(
        model.settings.startTime,
      );
      final now = DateTime.now();

      // Extract the time-of-day from the stored startTime
      final targetHour = startTime.hour;
      final targetMinute = startTime.minute;
      final targetSecond = startTime.second;

      // Create target DateTime for today at the target time
      var targetDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        targetHour,
        targetMinute,
        targetSecond,
      );

      // If target time has already passed today, target tomorrow instead
      if (targetDateTime.isBefore(now)) {
        targetDateTime = targetDateTime.add(const Duration(days: 1));
      }

      final difference = targetDateTime.difference(now);
      final remainingSeconds = difference.inSeconds;

      setState(() {
        _remainingSeconds = remainingSeconds;
      });

      // Only auto-navigate when countdown reaches zero
      if (remainingSeconds <= 0) {
        timer.cancel();
        _navigateToMainScreen();
      }
    });
  }

  void _navigateToMainScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Routine Starts In:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                TimeFormatter.formatCountdown(_remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 48),
              // Start Early button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: _navigateToMainScreen,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Start Early'),
                ),
              ),
              const SizedBox(height: 16),
              // Manage Tasks button
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.tasks);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Manage Tasks'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
