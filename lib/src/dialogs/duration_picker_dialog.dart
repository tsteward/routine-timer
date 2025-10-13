import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
    _hoursController = TextEditingController(text: _hours.toString());
    _minutesController = TextEditingController(text: _minutes.toString());
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
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
              _hoursController.text = _hours.toString();
            });
          },
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: _hoursController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MaxValueFormatter(maxValue: 23),
            ],
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              isDense: true,
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                _hours = 0;
              } else {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed >= 0 && parsed <= 23) {
                  _hours = parsed;
                }
              }
            },
            onSubmitted: (value) {
              // Format with leading zero after user submits
              setState(() {
                _hoursController.text = _hours.toString().padLeft(2, '0');
              });
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () {
            setState(() {
              _hours = (_hours - 1).clamp(0, 23);
              _hoursController.text = _hours.toString();
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
              _minutesController.text = _minutes.toString();
            });
          },
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MaxValueFormatter(maxValue: 59),
            ],
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              isDense: true,
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                _minutes = 0;
              } else {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed >= 0 && parsed <= 59) {
                  _minutes = parsed;
                }
              }
            },
            onSubmitted: (value) {
              // Format with leading zero after user submits
              setState(() {
                _minutesController.text = _minutes.toString().padLeft(2, '0');
              });
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () {
            setState(() {
              _minutes = (_minutes - 1).clamp(0, 59);
              _minutesController.text = _minutes.toString();
            });
          },
        ),
        const Text('minutes'),
      ],
    );
  }
}

/// Input formatter that limits the maximum value of the input
class _MaxValueFormatter extends TextInputFormatter {
  _MaxValueFormatter({required this.maxValue});

  final int maxValue;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    if (value > maxValue) {
      return oldValue;
    }

    return newValue;
  }
}
