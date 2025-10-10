import 'dart:convert';

import 'break.dart';
import 'routine_settings.dart';
import 'task.dart';

/// Represents the full routine state for configuration/runtime.
class RoutineStateModel {
  const RoutineStateModel({
    required this.tasks,
    required this.settings,
    this.selectedTaskId,
    this.isRunning = false,
    this.breaks,
  });

  /// Ordered list of tasks.
  final List<TaskModel> tasks;

  /// Optional list of gaps/breaks between tasks. The length is typically
  /// tasks.length - 1, but this is not strictly enforced here.
  final List<BreakModel>? breaks;

  /// Global routine settings.
  final RoutineSettingsModel settings;

  /// ID of the currently selected/active task. If null, no task is selected.
  final String? selectedTaskId;

  /// Whether the routine is actively running a timer.
  final bool isRunning;

  RoutineStateModel copyWith({
    List<TaskModel>? tasks,
    List<BreakModel>? breaks,
    RoutineSettingsModel? settings,
    String? selectedTaskId,
    bool? isRunning,
  }) {
    return RoutineStateModel(
      tasks: tasks ?? this.tasks,
      breaks: breaks ?? this.breaks,
      settings: settings ?? this.settings,
      selectedTaskId: selectedTaskId ?? this.selectedTaskId,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tasks': tasks.map((e) => e.toMap()).toList(),
      'breaks': breaks?.map((e) => e.toMap()).toList(),
      'settings': settings.toMap(),
      'selectedTaskId': selectedTaskId,
      'isRunning': isRunning,
    };
  }

  factory RoutineStateModel.fromMap(Map<String, dynamic> map) {
    final tasks = (map['tasks'] as List<dynamic>)
        .map((e) => TaskModel.fromMap(e as Map<String, dynamic>))
        .toList();

    // Handle backward compatibility: migrate from currentTaskIndex to selectedTaskId
    String? selectedTaskId = map['selectedTaskId'] as String?;
    if (selectedTaskId == null && map.containsKey('currentTaskIndex')) {
      final index = map['currentTaskIndex'] as int?;
      if (index != null && index >= 0 && index < tasks.length) {
        selectedTaskId = tasks[index].id;
      }
    }

    return RoutineStateModel(
      tasks: tasks,
      breaks: (map['breaks'] as List<dynamic>?)
          ?.map((e) => BreakModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      settings: RoutineSettingsModel.fromMap(
        map['settings'] as Map<String, dynamic>,
      ),
      selectedTaskId: selectedTaskId,
      isRunning: map['isRunning'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineStateModel.fromJson(String source) =>
      RoutineStateModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
