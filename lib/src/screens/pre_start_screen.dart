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
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeCountdown();
    }
  }

  void _initializeCountdown() {
    final routineBloc = context.read<RoutineBloc>();
    final model = routineBloc.state.model;

    if (model == null) {
      // If no model, navigate to main screen immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToMainScreen();
      });
      return;
    }

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
    if (targetDateTime.isBefore(now) || targetDateTime.isAtSameMomentAs(now)) {
      targetDateTime = targetDateTime.add(const Duration(days: 1));
    }

    final difference = targetDateTime.difference(now);

    // Start countdown
    setState(() {
      _remainingSeconds = difference.inSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          timer.cancel();
          _navigateToMainScreen();
        }
      } else {
        timer.cancel();
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
