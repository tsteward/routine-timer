import 'dart:convert';

/// Represents the summary data when a routine is completed.
class CompletionSummary {
  const CompletionSummary({
    required this.completedAt,
    required this.totalTimeSpent,
    required this.totalEstimatedTime,
    required this.tasksCompleted,
    required this.totalTasks,
    required this.tasks,
    this.routineName = 'Morning Routine',
  });

  /// When the routine was completed
  final DateTime completedAt;

  /// Total actual time spent in seconds across all tasks
  final int totalTimeSpent;

  /// Total estimated time in seconds across all tasks
  final int totalEstimatedTime;

  /// Number of tasks that were completed
  final int tasksCompleted;

  /// Total number of tasks in the routine
  final int totalTasks;

  /// Name of the routine (defaults to "Morning Routine")
  final String routineName;

  /// Individual task completion data
  final List<CompletedTaskSummary> tasks;

  /// Whether the routine was completed ahead of schedule
  bool get isAheadOfSchedule => totalTimeSpent < totalEstimatedTime;

  /// Time difference from estimated (positive = behind, negative = ahead)
  int get timeDifference => totalTimeSpent - totalEstimatedTime;

  /// Completion percentage (how many tasks were actually completed)
  double get completionPercentage =>
      totalTasks > 0 ? tasksCompleted / totalTasks : 0.0;

  CompletionSummary copyWith({
    DateTime? completedAt,
    int? totalTimeSpent,
    int? totalEstimatedTime,
    int? tasksCompleted,
    int? totalTasks,
    String? routineName,
    List<CompletedTaskSummary>? tasks,
  }) {
    return CompletionSummary(
      completedAt: completedAt ?? this.completedAt,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      totalEstimatedTime: totalEstimatedTime ?? this.totalEstimatedTime,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      totalTasks: totalTasks ?? this.totalTasks,
      routineName: routineName ?? this.routineName,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completedAt': completedAt.millisecondsSinceEpoch,
      'totalTimeSpent': totalTimeSpent,
      'totalEstimatedTime': totalEstimatedTime,
      'tasksCompleted': tasksCompleted,
      'totalTasks': totalTasks,
      'routineName': routineName,
      'tasks': tasks.map((e) => e.toMap()).toList(),
    };
  }

  factory CompletionSummary.fromMap(Map<String, dynamic> map) {
    return CompletionSummary(
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map['completedAt'] as int,
      ),
      totalTimeSpent: map['totalTimeSpent'] as int,
      totalEstimatedTime: map['totalEstimatedTime'] as int,
      tasksCompleted: map['tasksCompleted'] as int,
      totalTasks: map['totalTasks'] as int,
      routineName: map['routineName'] as String? ?? 'Morning Routine',
      tasks: (map['tasks'] as List<dynamic>)
          .map((e) => CompletedTaskSummary.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CompletionSummary.fromJson(String source) =>
      CompletionSummary.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Summary data for an individual completed task
class CompletedTaskSummary {
  const CompletedTaskSummary({
    required this.name,
    required this.estimatedDuration,
    required this.actualDuration,
    required this.wasCompleted,
    required this.order,
  });

  /// Task name
  final String name;

  /// Estimated duration in seconds
  final int estimatedDuration;

  /// Actual duration in seconds (0 if not completed)
  final int actualDuration;

  /// Whether this task was marked as completed
  final bool wasCompleted;

  /// Original order in the routine
  final int order;

  /// Time difference for this task (positive = over, negative = under)
  int get timeDifference => actualDuration - estimatedDuration;

  /// Whether this task was completed faster than estimated
  bool get wasFaster => actualDuration < estimatedDuration;

  CompletedTaskSummary copyWith({
    String? name,
    int? estimatedDuration,
    int? actualDuration,
    bool? wasCompleted,
    int? order,
  }) {
    return CompletedTaskSummary(
      name: name ?? this.name,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'wasCompleted': wasCompleted,
      'order': order,
    };
  }

  factory CompletedTaskSummary.fromMap(Map<String, dynamic> map) {
    return CompletedTaskSummary(
      name: map['name'] as String,
      estimatedDuration: map['estimatedDuration'] as int,
      actualDuration: map['actualDuration'] as int,
      wasCompleted: map['wasCompleted'] as bool,
      order: map['order'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory CompletedTaskSummary.fromJson(String source) =>
      CompletedTaskSummary.fromMap(json.decode(source) as Map<String, dynamic>);
}
