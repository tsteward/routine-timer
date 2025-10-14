import 'dart:convert';

/// Represents a completed routine session with statistics.
class RoutineCompletionModel {
  const RoutineCompletionModel({
    required this.completedAt,
    required this.totalTasksCompleted,
    required this.totalTimeSpent,
    required this.totalEstimatedTime,
    required this.routineName,
    this.tasksDetails,
  });

  /// Timestamp when routine was completed (milliseconds since epoch).
  final int completedAt;

  /// Number of tasks completed in this session.
  final int totalTasksCompleted;

  /// Total actual time spent in seconds.
  final int totalTimeSpent;

  /// Total estimated time in seconds.
  final int totalEstimatedTime;

  /// Name of the routine (e.g., "Morning Routine").
  final String routineName;

  /// Optional details about each task completed.
  final List<TaskCompletionDetail>? tasksDetails;

  /// Calculate if the routine was completed ahead or behind schedule.
  /// Returns positive if ahead, negative if behind (in seconds).
  int get timeDifference => totalEstimatedTime - totalTimeSpent;

  /// Whether the routine was completed ahead of schedule.
  bool get isAhead => timeDifference > 0;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completedAt': completedAt,
      'totalTasksCompleted': totalTasksCompleted,
      'totalTimeSpent': totalTimeSpent,
      'totalEstimatedTime': totalEstimatedTime,
      'routineName': routineName,
      'tasksDetails': tasksDetails?.map((e) => e.toMap()).toList(),
    };
  }

  factory RoutineCompletionModel.fromMap(Map<String, dynamic> map) {
    return RoutineCompletionModel(
      completedAt: map['completedAt'] as int,
      totalTasksCompleted: map['totalTasksCompleted'] as int,
      totalTimeSpent: map['totalTimeSpent'] as int,
      totalEstimatedTime: map['totalEstimatedTime'] as int,
      routineName: map['routineName'] as String,
      tasksDetails: (map['tasksDetails'] as List<dynamic>?)
          ?.map((e) => TaskCompletionDetail.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineCompletionModel.fromJson(String source) =>
      RoutineCompletionModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}

/// Details about a single completed task.
class TaskCompletionDetail {
  const TaskCompletionDetail({
    required this.taskName,
    required this.estimatedDuration,
    required this.actualDuration,
  });

  final String taskName;
  final int estimatedDuration;
  final int actualDuration;

  /// Time difference (positive if faster, negative if slower).
  int get timeDifference => estimatedDuration - actualDuration;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'taskName': taskName,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
    };
  }

  factory TaskCompletionDetail.fromMap(Map<String, dynamic> map) {
    return TaskCompletionDetail(
      taskName: map['taskName'] as String,
      estimatedDuration: map['estimatedDuration'] as int,
      actualDuration: map['actualDuration'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskCompletionDetail.fromJson(String source) =>
      TaskCompletionDetail.fromMap(json.decode(source) as Map<String, dynamic>);
}
