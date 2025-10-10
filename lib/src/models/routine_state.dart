import 'dart:convert';

import 'break.dart';
import 'routine_settings.dart';
import 'task.dart';

/// Represents the full routine state for configuration/runtime.
class RoutineStateModel {
  const RoutineStateModel({
    required this.tasks,
    required this.settings,
    this.currentTaskIndex = 0,
    this.isRunning = false,
    this.breaks,
    this.isOnBreak = false,
    this.currentBreakIndex,
  });

  /// Ordered list of tasks.
  final List<TaskModel> tasks;

  /// Optional list of gaps/breaks between tasks. The length is typically
  /// tasks.length - 1, but this is not strictly enforced here.
  final List<BreakModel>? breaks;

  /// Global routine settings.
  final RoutineSettingsModel settings;

  /// Index of the currently selected/active task.
  final int currentTaskIndex;

  /// Whether the routine is actively running a timer.
  final bool isRunning;

  /// Whether currently in a break state.
  final bool isOnBreak;

  /// Index of the current break (if on break).
  final int? currentBreakIndex;

  RoutineStateModel copyWith({
    List<TaskModel>? tasks,
    List<BreakModel>? breaks,
    RoutineSettingsModel? settings,
    int? currentTaskIndex,
    bool? isRunning,
    bool? isOnBreak,
    int? currentBreakIndex,
  }) {
    return RoutineStateModel(
      tasks: tasks ?? this.tasks,
      breaks: breaks ?? this.breaks,
      settings: settings ?? this.settings,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      isRunning: isRunning ?? this.isRunning,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      currentBreakIndex: currentBreakIndex ?? this.currentBreakIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tasks': tasks.map((e) => e.toMap()).toList(),
      'breaks': breaks?.map((e) => e.toMap()).toList(),
      'settings': settings.toMap(),
      'currentTaskIndex': currentTaskIndex,
      'isRunning': isRunning,
      'isOnBreak': isOnBreak,
      'currentBreakIndex': currentBreakIndex,
    };
  }

  factory RoutineStateModel.fromMap(Map<String, dynamic> map) {
    return RoutineStateModel(
      tasks: (map['tasks'] as List<dynamic>)
          .map((e) => TaskModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      breaks: (map['breaks'] as List<dynamic>?)
          ?.map((e) => BreakModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      settings: RoutineSettingsModel.fromMap(
        map['settings'] as Map<String, dynamic>,
      ),
      currentTaskIndex: map['currentTaskIndex'] as int? ?? 0,
      isRunning: map['isRunning'] as bool? ?? false,
      isOnBreak: map['isOnBreak'] as bool? ?? false,
      currentBreakIndex: map['currentBreakIndex'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineStateModel.fromJson(String source) =>
      RoutineStateModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
