import 'dart:convert';

/// Represents completion data for a finished routine
class RoutineCompletion {
  const RoutineCompletion({
    required this.completedAt,
    required this.totalTimeSpent,
    required this.tasksCompleted,
    required this.scheduleStatus,
    required this.scheduleVarianceSeconds,
  });

  /// Timestamp when the routine was completed
  final DateTime completedAt;

  /// Total time spent on the routine in seconds
  final int totalTimeSpent;

  /// Number of tasks completed
  final int tasksCompleted;

  /// Final schedule status: 'ahead', 'behind', or 'on-track'
  final String scheduleStatus;

  /// How many seconds ahead or behind schedule (positive = ahead, negative = behind)
  final int scheduleVarianceSeconds;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completedAt': completedAt.millisecondsSinceEpoch,
      'totalTimeSpent': totalTimeSpent,
      'tasksCompleted': tasksCompleted,
      'scheduleStatus': scheduleStatus,
      'scheduleVarianceSeconds': scheduleVarianceSeconds,
    };
  }

  factory RoutineCompletion.fromMap(Map<String, dynamic> map) {
    return RoutineCompletion(
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map['completedAt'] as int,
      ),
      totalTimeSpent: map['totalTimeSpent'] as int,
      tasksCompleted: map['tasksCompleted'] as int,
      scheduleStatus: map['scheduleStatus'] as String,
      scheduleVarianceSeconds: map['scheduleVarianceSeconds'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineCompletion.fromJson(String source) =>
      RoutineCompletion.fromMap(json.decode(source) as Map<String, dynamic>);
}
