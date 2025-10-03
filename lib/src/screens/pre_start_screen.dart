import 'package:flutter/material.dart';
import '../router/app_router.dart';

class PreStartScreen extends StatelessWidget {
  const PreStartScreen({super.key});

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
                'Pre-Start',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Countdown placeholder',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _NavFab(current: AppRoutes.preStart),
    );
  }
}

class _NavFab extends StatelessWidget {
  const _NavFab({required this.current});

  final String current;

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
