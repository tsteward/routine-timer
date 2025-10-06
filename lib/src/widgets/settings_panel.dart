import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/routine_bloc.dart';
import '../dialogs/duration_picker_dialog.dart';
import '../models/routine_state.dart';
import '../utils/time_formatter.dart';

/// A panel for displaying and editing routine settings
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({required this.model, super.key});

  final RoutineStateModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Routine Start Time
            InkWell(
              onTap: () => _pickStartTime(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Routine Start Time',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            TimeFormatter.formatTimeOfDay(
                              TimeOfDay.fromDateTime(
                                DateTime.fromMillisecondsSinceEpoch(
                                  model.settings.startTime,
                                ),
                              ),
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.access_time, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
            const Divider(),
            // Enable Breaks by Default
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Breaks by Default'),
              value: model.settings.breaksEnabledByDefault,
              onChanged: (value) {
                _updateBreaksEnabledByDefault(context, value);
              },
            ),
            const Divider(),
            // Break Duration
            InkWell(
              onTap: () => _pickBreakDuration(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Break Duration',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            TimeFormatter.formatDuration(
                              model.settings.defaultBreakDuration,
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.timer_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final currentTime = TimeOfDay.fromDateTime(
      DateTime.fromMillisecondsSinceEpoch(model.settings.startTime),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null && context.mounted) {
      // Create a DateTime from the selected time
      final now = DateTime.now();
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      final updatedSettings = model.settings.copyWith(
        startTime: startTime.millisecondsSinceEpoch,
      );

      context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));
    }
  }

  Future<void> _pickBreakDuration(BuildContext context) async {
    final currentDuration = model.settings.defaultBreakDuration;
    final hours = currentDuration ~/ 3600;
    final minutes = (currentDuration % 3600) ~/ 60;

    final picked = await DurationPickerDialog.show(
      context: context,
      initialHours: hours,
      initialMinutes: minutes,
      title: 'Break Duration',
    );

    if (picked != null && context.mounted) {
      final durationInSeconds = picked;

      if (durationInSeconds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duration must be greater than 0')),
        );
        return;
      }

      final updatedSettings = model.settings.copyWith(
        defaultBreakDuration: durationInSeconds,
      );

      context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));
    }
  }

  void _updateBreaksEnabledByDefault(BuildContext context, bool value) {
    final updatedSettings = model.settings.copyWith(
      breaksEnabledByDefault: value,
    );

    context.read<RoutineBloc>().add(UpdateSettings(updatedSettings));
  }
}
