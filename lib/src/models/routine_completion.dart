import 'dart:convert';

/// Represents the completion data for a routine session.
class RoutineCompletionModel {
  const RoutineCompletionModel({
    required this.completedAt,
    required this.totalTimeSpent,
    required this.tasksCompleted,
    required this.totalTasks,
    required this.finalAheadBehindStatus,
    required this.tasks,
    this.routineStartTime,
  });

  /// When the routine was completed.
  final DateTime completedAt;

  /// Total time spent on the routine in seconds.
  final int totalTimeSpent;

  /// Number of tasks actually completed.
  final int tasksCompleted;

  /// Total number of tasks in the routine.
  final int totalTasks;

  /// Final ahead/behind status in seconds (negative = behind, positive = ahead).
  final int finalAheadBehindStatus;

  /// List of completed tasks with their timing data.
  final List<CompletedTaskModel> tasks;

  /// When the routine was started (for calculating total duration).
  final DateTime? routineStartTime;

  /// Calculate if the routine was completed successfully (all tasks done).
  bool get isFullyCompleted => tasksCompleted == totalTasks;

  /// Get formatted ahead/behind status.
  String get aheadBehindText {
    if (finalAheadBehindStatus == 0) return 'On time';
    final minutes = (finalAheadBehindStatus.abs() / 60).floor();
    final seconds = finalAheadBehindStatus.abs() % 60;
    final timeText = minutes > 0 
        ? '${minutes}m ${seconds.toInt()}s' 
        : '${seconds.toInt()}s';
    return finalAheadBehindStatus > 0 
        ? '$timeText ahead' 
        : '$timeText behind';
  }

  RoutineCompletionModel copyWith({
    DateTime? completedAt,
    int? totalTimeSpent,
    int? tasksCompleted,
    int? totalTasks,
    int? finalAheadBehindStatus,
    List<CompletedTaskModel>? tasks,
    DateTime? routineStartTime,
  }) {
    return RoutineCompletionModel(
      completedAt: completedAt ?? this.completedAt,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      totalTasks: totalTasks ?? this.totalTasks,
      finalAheadBehindStatus: finalAheadBehindStatus ?? this.finalAheadBehindStatus,
      tasks: tasks ?? this.tasks,
      routineStartTime: routineStartTime ?? this.routineStartTime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completedAt': completedAt.millisecondsSinceEpoch,
      'totalTimeSpent': totalTimeSpent,
      'tasksCompleted': tasksCompleted,
      'totalTasks': totalTasks,
      'finalAheadBehindStatus': finalAheadBehindStatus,
      'tasks': tasks.map((e) => e.toMap()).toList(),
      'routineStartTime': routineStartTime?.millisecondsSinceEpoch,
    };
  }

  factory RoutineCompletionModel.fromMap(Map<String, dynamic> map) {
    return RoutineCompletionModel(
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map['completedAt'] as int,
      ),
      totalTimeSpent: map['totalTimeSpent'] as int,
      tasksCompleted: map['tasksCompleted'] as int,
      totalTasks: map['totalTasks'] as int,
      finalAheadBehindStatus: map['finalAheadBehindStatus'] as int,
      tasks: (map['tasks'] as List<dynamic>)
          .map((e) => CompletedTaskModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      routineStartTime: map['routineStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['routineStartTime'] as int,
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineCompletionModel.fromJson(String source) =>
      RoutineCompletionModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}

/// Represents a completed task with timing data.
class CompletedTaskModel {
  const CompletedTaskModel({
    required this.id,
    required this.name,
    required this.estimatedDuration,
    required this.actualDuration,
    required this.isCompleted,
    required this.order,
  });

  /// Task ID.
  final String id;

  /// Task name.
  final String name;

  /// Estimated duration in seconds.
  final int estimatedDuration;

  /// Actual duration in seconds.
  final int actualDuration;

  /// Whether the task was completed.
  final bool isCompleted;

  /// Task order in the routine.
  final int order;

  /// Get the difference between actual and estimated duration.
  int get durationDifference => actualDuration - estimatedDuration;

  /// Whether this task was completed ahead of schedule.
  bool get isAhead => durationDifference < 0;

  /// Whether this task was completed behind schedule.
  bool get isBehind => durationDifference > 0;

  CompletedTaskModel copyWith({
    String? id,
    String? name,
    int? estimatedDuration,
    int? actualDuration,
    bool? isCompleted,
    int? order,
  }) {
    return CompletedTaskModel(
      id: id ?? this.id,
      name: name ?? this.name,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'isCompleted': isCompleted,
      'order': order,
    };
  }

  factory CompletedTaskModel.fromMap(Map<String, dynamic> map) {
    return CompletedTaskModel(
      id: map['id'] as String,
      name: map['name'] as String,
      estimatedDuration: map['estimatedDuration'] as int,
      actualDuration: map['actualDuration'] as int,
      isCompleted: map['isCompleted'] as bool,
      order: map['order'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory CompletedTaskModel.fromJson(String source) =>
      CompletedTaskModel.fromMap(json.decode(source) as Map<String, dynamic>);
}