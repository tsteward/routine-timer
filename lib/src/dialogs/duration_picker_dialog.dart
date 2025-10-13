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
  final FocusNode _hoursFocusNode = FocusNode();
  final FocusNode _minutesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
    _hoursController = TextEditingController(text: _hours.toString());
    _minutesController = TextEditingController(text: _minutes.toString());

    // Update internal state when text changes
    _hoursController.addListener(_onHoursTextChanged);
    _minutesController.addListener(_onMinutesTextChanged);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _hoursFocusNode.dispose();
    _minutesFocusNode.dispose();
    super.dispose();
  }

  void _onHoursTextChanged() {
    final text = _hoursController.text;
    if (text.isEmpty) {
      _hours = 0;
      return;
    }
    final value = int.tryParse(text);
    if (value != null && value >= 0 && value <= 23) {
      _hours = value;
    }
  }

  void _onMinutesTextChanged() {
    final text = _minutesController.text;
    if (text.isEmpty) {
      _minutes = 0;
      return;
    }
    final value = int.tryParse(text);
    if (value != null && value >= 0 && value <= 59) {
      _minutes = value;
    }
  }

  void _updateHours(int newValue) {
    setState(() {
      _hours = newValue.clamp(0, 23);
      _hoursController.text = _hours.toString();
    });
  }

  void _updateMinutes(int newValue) {
    setState(() {
      _minutes = newValue.clamp(0, 59);
      _minutesController.text = _minutes.toString();
    });
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
          onPressed: () => _updateHours(_hours + 1),
        ),
        Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _hoursController,
            focusNode: _hoursFocusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) {
              // Move focus to minutes field when done
              _minutesFocusNode.requestFocus();
            },
            onTap: () {
              // Select all text when tapped for easy replacement
              _hoursController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _hoursController.text.length,
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () => _updateHours(_hours - 1),
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
          onPressed: () => _updateMinutes(_minutes + 1),
        ),
        Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _minutesController,
            focusNode: _minutesFocusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) {
              // Unfocus when done with minutes
              _minutesFocusNode.unfocus();
            },
            onTap: () {
              // Select all text when tapped for easy replacement
              _minutesController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _minutesController.text.length,
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () => _updateMinutes(_minutes - 1),
        ),
        const Text('minutes'),
      ],
    );
  }
}
