import 'package:flutter/material.dart';
import '../router/app_router.dart';

class TaskManagementScreen extends StatelessWidget {
  const TaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Scaffold(
      appBar: AppBar(title: const Text('Task Management')),
      body: Row(
        children: [
          // Left column placeholder (task list with breaks)
          Expanded(
            flex: 3,
            child: Container(
              color: color,
              child: const Center(child: Text('Left Column: Task List Placeholder')),
            ),
          ),
          // Right column placeholder (settings & details)
          Expanded(
            flex: 2,
            child: Container(
              color: color.withOpacity(0.6),
              child: const Center(child: Text('Right Column: Settings & Details Placeholder')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final selected = await showMenu<String>(
            context: context,
            position: const RelativeRect.fromLTRB(1000, 0, 16, 0),
            items: const [
              PopupMenuItem(value: AppRoutes.preStart, child: Text('Pre-Start')),
              PopupMenuItem(value: AppRoutes.main, child: Text('Main Routine')),
              PopupMenuItem(value: AppRoutes.tasks, child: Text('Task Management')),
            ],
          );
          if (selected != null) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushNamed(selected);
          }
        },
        child: const Icon(Icons.navigation),
      ),
    );
  }
}


