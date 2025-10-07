import 'dart:async';
import 'package:flutter/material.dart';

/// A dialog for picking duration in hours and minutes
class DurationPickerDialog extends StatefulWidget {
  const DurationPickerDialog({
    required this.initialHours,
    required this.initialMinutes,
    required this.title,
    super.key,
  });

  final int initialHours;
  final int initialMinutes;
  final String title;

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();

  /// Shows the duration picker dialog and returns the selected duration in seconds
  static Future<int?> show({
    required BuildContext context,
    required int initialHours,
    required int initialMinutes,
    required String title,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return DurationPickerDialog(
          initialHours: initialHours,
          initialMinutes: initialMinutes,
          title: title,
        );
      },
    );
  }
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHoursPicker(),
                const SizedBox(width: 16),
                Text(':', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(width: 16),
                _buildMinutesPicker(),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final totalSeconds = (_hours * 3600) + (_minutes * 60);
            Navigator.of(context).pop(totalSeconds);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildHoursPicker() {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_drop_up),
          onPressed: () {
            setState(() {
              _hours = (_hours + 1).clamp(0, 23);
            });
          },
        ),
        Container(
          width: 60,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _hours.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () {
            setState(() {
              _hours = (_hours - 1).clamp(0, 23);
            });
          },
        ),
        const Text('hours'),
      ],
    );
  }

  Widget _buildMinutesPicker() {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_drop_up),
          onPressed: () {
            setState(() {
              _minutes = (_minutes + 1).clamp(0, 59);
            });
          },
        ),
        Container(
          width: 60,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _minutes.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () {
            setState(() {
              _minutes = (_minutes - 1).clamp(0, 59);
            });
          },
        ),
        const Text('minutes'),
      ],
    );
  }
}
