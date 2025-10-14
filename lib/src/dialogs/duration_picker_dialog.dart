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
  late FocusNode _hoursFocusNode;
  late FocusNode _minutesFocusNode;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
    _hoursController = TextEditingController(
      text: _hours.toString().padLeft(2, '0'),
    );
    _minutesController = TextEditingController(
      text: _minutes.toString().padLeft(2, '0'),
    );
    _hoursFocusNode = FocusNode();
    _minutesFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _hoursFocusNode.dispose();
    _minutesFocusNode.dispose();
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

  void _updateHours(int value) {
    setState(() {
      _hours = value.clamp(0, 23);
      _hoursController.text = _hours.toString().padLeft(2, '0');
      _hoursController.selection = TextSelection.fromPosition(
        TextPosition(offset: _hoursController.text.length),
      );
    });
  }

  void _updateMinutes(int value) {
    setState(() {
      _minutes = value.clamp(0, 59);
      _minutesController.text = _minutes.toString().padLeft(2, '0');
      _minutesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _minutesController.text.length),
      );
    });
  }

  Widget _buildHoursPicker() {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_drop_up),
          onPressed: () {
            _updateHours(_hours + 1);
          },
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
            onTap: () {
              // Select all text on tap for easy editing
              _hoursController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _hoursController.text.length,
              );
            },
            onChanged: (value) {
              if (value.isEmpty) return;
              final parsed = int.tryParse(value);
              if (parsed != null) {
                _hours = parsed.clamp(0, 23);
              }
            },
            onSubmitted: (value) {
              if (value.isEmpty) {
                _updateHours(0);
              } else {
                final parsed = int.tryParse(value);
                if (parsed != null) {
                  _updateHours(parsed);
                }
              }
              // Move to minutes field
              _minutesFocusNode.requestFocus();
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () {
            _updateHours(_hours - 1);
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
            _updateMinutes(_minutes + 1);
          },
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
            onTap: () {
              // Select all text on tap for easy editing
              _minutesController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _minutesController.text.length,
              );
            },
            onChanged: (value) {
              if (value.isEmpty) return;
              final parsed = int.tryParse(value);
              if (parsed != null) {
                _minutes = parsed.clamp(0, 59);
              }
            },
            onSubmitted: (value) {
              if (value.isEmpty) {
                _updateMinutes(0);
              } else {
                final parsed = int.tryParse(value);
                if (parsed != null) {
                  _updateMinutes(parsed);
                }
              }
              // Unfocus to close keyboard
              _minutesFocusNode.unfocus();
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () {
            _updateMinutes(_minutes - 1);
          },
        ),
        const Text('minutes'),
      ],
    );
  }
}
