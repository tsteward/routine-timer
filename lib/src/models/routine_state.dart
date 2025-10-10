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
    this.isBreakActive = false,
    this.activeBreakIndex,
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

  /// Whether currently in break mode (between tasks).
  final bool isBreakActive;

  /// Index of the break currently active (if any).
  final int? activeBreakIndex;

  RoutineStateModel copyWith({
    List<TaskModel>? tasks,
    List<BreakModel>? breaks,
    RoutineSettingsModel? settings,
    int? currentTaskIndex,
    bool? isRunning,
    bool? isBreakActive,
    int? activeBreakIndex,
    bool clearActiveBreakIndex = false,
  }) {
    return RoutineStateModel(
      tasks: tasks ?? this.tasks,
      breaks: breaks ?? this.breaks,
      settings: settings ?? this.settings,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      isRunning: isRunning ?? this.isRunning,
      isBreakActive: isBreakActive ?? this.isBreakActive,
      activeBreakIndex: clearActiveBreakIndex
          ? null
          : (activeBreakIndex ?? this.activeBreakIndex),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tasks': tasks.map((e) => e.toMap()).toList(),
      'breaks': breaks?.map((e) => e.toMap()).toList(),
      'settings': settings.toMap(),
      'currentTaskIndex': currentTaskIndex,
      'isRunning': isRunning,
      'isBreakActive': isBreakActive,
      'activeBreakIndex': activeBreakIndex,
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
      isBreakActive: map['isBreakActive'] as bool? ?? false,
      activeBreakIndex: map['activeBreakIndex'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineStateModel.fromJson(String source) =>
      RoutineStateModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
