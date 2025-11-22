import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/routine_bloc.dart';
import '../widgets/settings_panel.dart';
import '../widgets/task_details_panel.dart';
import '../widgets/task_list_column.dart';
import '../widgets/task_management_bottom_bar.dart';
import 'task_library_screen.dart';

class TaskManagementScreen extends StatelessWidget {
  const TaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TaskLibraryScreen(),
                ),
              );
            },
            tooltip: 'Task Library',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left column (task list with breaks)
                Expanded(
                  flex: 3,
                  child: Container(color: color, child: const TaskListColumn()),
                ),
                // Right column (settings & details)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: color.withValues(alpha: 0.6),
                    child: const _SettingsAndDetailsColumn(),
                  ),
                ),
              ],
            ),
          ),
          const TaskManagementBottomBar(),
        ],
      ),
    );
  }
}

class _SettingsAndDetailsColumn extends StatelessWidget {
  const _SettingsAndDetailsColumn();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineBlocState>(
      builder: (context, state) {
        final model = state.model;
        if (model == null) {
          return const Center(child: Text('No routine loaded'));
        }

        final selectedTask = model.selectedTask;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsPanel(model: model),
              const SizedBox(height: 32),
              if (selectedTask != null)
                TaskDetailsPanel(model: model, task: selectedTask),
            ],
          ),
        );
      },
    );
  }
}
