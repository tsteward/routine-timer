import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A dialog for picking duration in minutes and seconds
class DurationPickerDialog extends StatefulWidget {
  const DurationPickerDialog({
    required this.initialMinutes,
    required this.initialSeconds,
    required this.title,
    super.key,
  });

  final int initialMinutes;
  final int initialSeconds;
  final String title;

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();

  /// Shows the duration picker dialog and returns the selected duration in seconds
  static Future<int?> show({
    required BuildContext context,
    required int initialMinutes,
    required int initialSeconds,
    required String title,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return DurationPickerDialog(
          initialMinutes: initialMinutes,
          initialSeconds: initialSeconds,
          title: title,
        );
      },
    );
  }
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int _minutes;
  late int _seconds;
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;
  late FocusNode _minutesFocusNode;
  late FocusNode _secondsFocusNode;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes;
    _seconds = widget.initialSeconds;
    _minutesController = TextEditingController(
      text: _minutes.toString().padLeft(2, '0'),
    );
    _secondsController = TextEditingController(
      text: _seconds.toString().padLeft(2, '0'),
    );
    _minutesFocusNode = FocusNode();
    _secondsFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _minutesFocusNode.dispose();
    _secondsFocusNode.dispose();
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
                _buildMinutesPicker(),
                const SizedBox(width: 16),
                Text(':', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(width: 16),
                _buildSecondsPicker(),
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
            final totalSeconds = (_minutes * 60) + _seconds;
            Navigator.of(context).pop(totalSeconds);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  void _updateMinutes(int value) {
    setState(() {
      _minutes = value.clamp(0, 999);
      _minutesController.text = _minutes.toString().padLeft(2, '0');
      _minutesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _minutesController.text.length),
      );
    });
  }

  void _updateSeconds(int value) {
    setState(() {
      _seconds = value.clamp(0, 59);
      _secondsController.text = _seconds.toString().padLeft(2, '0');
      _secondsController.selection = TextSelection.fromPosition(
        TextPosition(offset: _secondsController.text.length),
      );
    });
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
              LengthLimitingTextInputFormatter(3),
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
                _minutes = parsed.clamp(0, 999);
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
              // Move to seconds field
              _secondsFocusNode.requestFocus();
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

  Widget _buildSecondsPicker() {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_drop_up),
          onPressed: () {
            _updateSeconds(_seconds + 1);
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
            controller: _secondsController,
            focusNode: _secondsFocusNode,
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
              _secondsController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _secondsController.text.length,
              );
            },
            onChanged: (value) {
              if (value.isEmpty) return;
              final parsed = int.tryParse(value);
              if (parsed != null) {
                _seconds = parsed.clamp(0, 59);
              }
            },
            onSubmitted: (value) {
              if (value.isEmpty) {
                _updateSeconds(0);
              } else {
                final parsed = int.tryParse(value);
                if (parsed != null) {
                  _updateSeconds(parsed);
                }
              }
              // Unfocus to close keyboard
              _secondsFocusNode.unfocus();
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () {
            _updateSeconds(_seconds - 1);
          },
        ),
        const Text('seconds'),
      ],
    );
  }
}
