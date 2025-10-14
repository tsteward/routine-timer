import 'dart:convert';

/// Represents the completion data for a finished routine session.
class RoutineCompletion {
  const RoutineCompletion({
    required this.completedAt,
    required this.totalTimeSpent,
    required this.tasksCompleted,
    required this.totalTasks,
    required this.scheduleVariance,
    required this.taskCompletions,
  });

  /// Timestamp when the routine was completed.
  final DateTime completedAt;

  /// Total actual time spent on all tasks in seconds.
  final int totalTimeSpent;

  /// Number of tasks that were completed.
  final int tasksCompleted;

  /// Total number of tasks in the routine.
  final int totalTasks;

  /// Schedule variance in seconds (negative = ahead, positive = behind).
  final int scheduleVariance;

  /// List of individual task completion records.
  final List<TaskCompletion> taskCompletions;

  /// Returns true if all tasks were completed.
  bool get isFullyCompleted => tasksCompleted == totalTasks;

  /// Returns a human-readable schedule status.
  String get scheduleStatus {
    if (scheduleVariance == 0) {
      return 'On schedule';
    } else if (scheduleVariance < 0) {
      final minutes = (scheduleVariance.abs() / 60).floor();
      final seconds = scheduleVariance.abs() % 60;
      if (minutes > 0) {
        return 'Ahead by $minutes min ${seconds}s';
      }
      return 'Ahead by ${seconds}s';
    } else {
      final minutes = (scheduleVariance / 60).floor();
      final seconds = scheduleVariance % 60;
      if (minutes > 0) {
        return 'Behind by $minutes min ${seconds}s';
      }
      return 'Behind by ${seconds}s';
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completedAt': completedAt.millisecondsSinceEpoch,
      'totalTimeSpent': totalTimeSpent,
      'tasksCompleted': tasksCompleted,
      'totalTasks': totalTasks,
      'scheduleVariance': scheduleVariance,
      'taskCompletions': taskCompletions.map((e) => e.toMap()).toList(),
    };
  }

  factory RoutineCompletion.fromMap(Map<String, dynamic> map) {
    return RoutineCompletion(
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map['completedAt'] as int,
      ),
      totalTimeSpent: map['totalTimeSpent'] as int,
      tasksCompleted: map['tasksCompleted'] as int,
      totalTasks: map['totalTasks'] as int,
      scheduleVariance: map['scheduleVariance'] as int,
      taskCompletions: (map['taskCompletions'] as List<dynamic>)
          .map((e) => TaskCompletion.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineCompletion.fromJson(String source) =>
      RoutineCompletion.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Represents the completion data for a single task.
class TaskCompletion {
  const TaskCompletion({
    required this.taskId,
    required this.taskName,
    required this.estimatedDuration,
    required this.actualDuration,
    required this.completedAt,
  });

  /// Unique identifier for the task.
  final String taskId;

  /// Name of the task.
  final String taskName;

  /// Estimated duration in seconds.
  final int estimatedDuration;

  /// Actual duration taken in seconds.
  final int actualDuration;

  /// When this specific task was completed.
  final DateTime completedAt;

  /// Variance between estimated and actual duration (positive = over time).
  int get variance => actualDuration - estimatedDuration;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'taskId': taskId,
      'taskName': taskName,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'completedAt': completedAt.millisecondsSinceEpoch,
    };
  }

  factory TaskCompletion.fromMap(Map<String, dynamic> map) {
    return TaskCompletion(
      taskId: map['taskId'] as String,
      taskName: map['taskName'] as String,
      estimatedDuration: map['estimatedDuration'] as int,
      actualDuration: map['actualDuration'] as int,
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map['completedAt'] as int,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskCompletion.fromJson(String source) =>
      TaskCompletion.fromMap(json.decode(source) as Map<String, dynamic>);
}
