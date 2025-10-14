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

  /// ID of the currently selected/active task. If null, defaults to the first task.
  final String? selectedTaskId;

  /// Whether the routine is actively running a timer.
  final bool isRunning;

  /// Whether the user is currently on a break.
  final bool isOnBreak;

  /// Index of the current break being taken. Only relevant when isOnBreak is true.
  final int? currentBreakIndex;

  RoutineStateModel copyWith({
    List<TaskModel>? tasks,
    List<BreakModel>? breaks,
    RoutineSettingsModel? settings,
    String? selectedTaskId,
    bool? isRunning,
    bool? isOnBreak,
    int? currentBreakIndex,
  }) {
    return RoutineStateModel(
      tasks: tasks ?? this.tasks,
      breaks: breaks ?? this.breaks,
      settings: settings ?? this.settings,
      selectedTaskId: selectedTaskId ?? this.selectedTaskId,
      isRunning: isRunning ?? this.isRunning,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      currentBreakIndex: currentBreakIndex ?? this.currentBreakIndex,
    );
  }

  /// Gets the currently selected task. If no task is selected or the selected task
  /// doesn't exist, returns the first task (or null if no tasks).
  TaskModel? get selectedTask {
    if (tasks.isEmpty) return null;

    if (selectedTaskId == null) {
      return tasks.first;
    }

    try {
      return tasks.firstWhere((task) => task.id == selectedTaskId);
    } catch (e) {
      // If selected task doesn't exist, fall back to first task
      return tasks.first;
    }
  }

  /// Gets the index of the currently selected task. If no task is selected or the
  /// selected task doesn't exist, returns 0 (or -1 if no tasks).
  int get currentTaskIndex {
    if (tasks.isEmpty) return -1;

    if (selectedTaskId == null) {
      return 0;
    }

    for (int i = 0; i < tasks.length; i++) {
      if (tasks[i].id == selectedTaskId) {
        return i;
      }
    }

    // If selected task doesn't exist, fall back to first task
    return 0;
  }

  /// Gets the currently active break model, if any.
  BreakModel? get currentBreak {
    if (!isOnBreak || currentBreakIndex == null || breaks == null) {
      return null;
    }
    if (currentBreakIndex! < 0 || currentBreakIndex! >= breaks!.length) {
      return null;
    }
    return breaks![currentBreakIndex!];
  }

  /// Returns true if all tasks have been completed.
  bool get isRoutineCompleted {
    if (tasks.isEmpty) return false;
    return tasks.every((task) => task.isCompleted);
  }

  /// Returns the number of completed tasks.
  int get completedTasksCount {
    return tasks.where((task) => task.isCompleted).length;
  }

  /// Calculates total time spent on completed tasks in seconds.
  int get totalTimeSpent {
    return tasks
        .where((task) => task.isCompleted)
        .fold<int>(0, (sum, task) => sum + (task.actualDuration ?? 0));
  }

  /// Calculates total estimated time for all tasks in seconds.
  int get totalEstimatedTime {
    return tasks.fold<int>(0, (sum, task) => sum + task.estimatedDuration);
  }

  /// Calculates schedule variance in seconds (positive = behind schedule).
  int get scheduleVariance {
    return totalTimeSpent - totalEstimatedTime;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tasks': tasks.map((e) => e.toMap()).toList(),
      'breaks': breaks?.map((e) => e.toMap()).toList(),
      'settings': settings.toMap(),
      'selectedTaskId': selectedTaskId,
      'isRunning': isRunning,
      'isOnBreak': isOnBreak,
      'currentBreakIndex': currentBreakIndex,
    };
  }

  factory RoutineStateModel.fromMap(Map<String, dynamic> map) {
    final tasks = (map['tasks'] as List<dynamic>)
        .map((e) => TaskModel.fromMap(e as Map<String, dynamic>))
        .toList();

    // Handle migration from old currentTaskIndex to new selectedTaskId
    String? selectedTaskId = map['selectedTaskId'] as String?;
    if (selectedTaskId == null && map.containsKey('currentTaskIndex')) {
      final oldIndex = map['currentTaskIndex'] as int? ?? 0;
      if (tasks.isNotEmpty && oldIndex >= 0 && oldIndex < tasks.length) {
        selectedTaskId = tasks[oldIndex].id;
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
      isOnBreak: map['isOnBreak'] as bool? ?? false,
      currentBreakIndex: map['currentBreakIndex'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineStateModel.fromJson(String source) =>
      RoutineStateModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
