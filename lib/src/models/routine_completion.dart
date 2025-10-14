import 'dart:convert';

/// Represents a completed routine session with summary statistics.
class RoutineCompletion {
  const RoutineCompletion({
    required this.completedAt,
    required this.totalTimeSpent,
    required this.tasksCompleted,
    required this.totalEstimatedTime,
    required this.taskDetails,
  });

  /// Timestamp when routine was completed (milliseconds since epoch).
  final int completedAt;

  /// Total actual time spent on all tasks in seconds.
  final int totalTimeSpent;

  /// Number of tasks completed.
  final int tasksCompleted;

  /// Total estimated time for all tasks in seconds.
  final int totalEstimatedTime;

  /// List of individual task completion details.
  final List<TaskCompletionDetail> taskDetails;

  /// Calculate how many seconds ahead or behind schedule.
  /// Positive means ahead of schedule, negative means behind.
  int get timeDifference => totalEstimatedTime - totalTimeSpent;

  /// Whether the routine was completed ahead of schedule.
  bool get isAheadOfSchedule => timeDifference > 0;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completedAt': completedAt,
      'totalTimeSpent': totalTimeSpent,
      'tasksCompleted': tasksCompleted,
      'totalEstimatedTime': totalEstimatedTime,
      'taskDetails': taskDetails.map((e) => e.toMap()).toList(),
    };
  }

  factory RoutineCompletion.fromMap(Map<String, dynamic> map) {
    return RoutineCompletion(
      completedAt: map['completedAt'] as int,
      totalTimeSpent: map['totalTimeSpent'] as int,
      tasksCompleted: map['tasksCompleted'] as int,
      totalEstimatedTime: map['totalEstimatedTime'] as int,
      taskDetails: (map['taskDetails'] as List<dynamic>)
          .map((e) => TaskCompletionDetail.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineCompletion.fromJson(String source) =>
      RoutineCompletion.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Details about a single completed task.
class TaskCompletionDetail {
  const TaskCompletionDetail({
    required this.taskId,
    required this.taskName,
    required this.estimatedDuration,
    required this.actualDuration,
  });

  final String taskId;
  final String taskName;
  final int estimatedDuration;
  final int actualDuration;

  /// Calculate difference between actual and estimated duration.
  /// Positive means task took longer than expected, negative means faster.
  int get timeDifference => actualDuration - estimatedDuration;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'taskId': taskId,
      'taskName': taskName,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
    };
  }

  factory TaskCompletionDetail.fromMap(Map<String, dynamic> map) {
    return TaskCompletionDetail(
      taskId: map['taskId'] as String,
      taskName: map['taskName'] as String,
      estimatedDuration: map['estimatedDuration'] as int,
      actualDuration: map['actualDuration'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskCompletionDetail.fromJson(String source) =>
      TaskCompletionDetail.fromMap(json.decode(source) as Map<String, dynamic>);
}
