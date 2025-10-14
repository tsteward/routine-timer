import 'dart:convert';

/// Represents the completion data for a routine session.
/// This is saved to Firebase for analytics and history tracking.
class RoutineCompletionData {
  const RoutineCompletionData({
    required this.completedAt,
    required this.totalDurationSeconds,
    required this.tasksCompleted,
    required this.totalEstimatedDuration,
    required this.totalActualDuration,
    required this.routineName,
  });

  /// Timestamp when the routine was completed
  final int completedAt;

  /// Total duration from start to finish (wall clock time)
  final int totalDurationSeconds;

  /// Number of tasks completed
  final int tasksCompleted;

  /// Sum of all estimated task durations
  final int totalEstimatedDuration;

  /// Sum of all actual task durations
  final int totalActualDuration;

  /// Name of the routine (e.g., "Morning Routine")
  final String routineName;

  /// Calculate if user was ahead or behind schedule
  int get timeDifference => totalActualDuration - totalEstimatedDuration;

  /// Returns true if user finished ahead of schedule
  bool get isAheadOfSchedule => timeDifference < 0;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completedAt': completedAt,
      'totalDurationSeconds': totalDurationSeconds,
      'tasksCompleted': tasksCompleted,
      'totalEstimatedDuration': totalEstimatedDuration,
      'totalActualDuration': totalActualDuration,
      'routineName': routineName,
    };
  }

  factory RoutineCompletionData.fromMap(Map<String, dynamic> map) {
    return RoutineCompletionData(
      completedAt: map['completedAt'] as int,
      totalDurationSeconds: map['totalDurationSeconds'] as int,
      tasksCompleted: map['tasksCompleted'] as int,
      totalEstimatedDuration: map['totalEstimatedDuration'] as int,
      totalActualDuration: map['totalActualDuration'] as int,
      routineName: map['routineName'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineCompletionData.fromJson(String source) =>
      RoutineCompletionData.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
