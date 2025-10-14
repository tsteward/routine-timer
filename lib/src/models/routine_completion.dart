import 'dart:convert';

/// Represents a completed routine session with summary statistics.
/// Used for displaying completion screen and saving completion history to Firebase.
class RoutineCompletion {
  const RoutineCompletion({
    required this.completedAt,
    required this.totalTimeSpent,
    required this.tasksCompleted,
    required this.scheduleVariance,
    required this.routineStartTime,
    this.completionId,
  });

  /// Unique identifier for this completion record (optional)
  final String? completionId;

  /// Timestamp when routine was completed
  final DateTime completedAt;

  /// Total time spent on the routine in seconds
  final int totalTimeSpent;

  /// Number of tasks completed
  final int tasksCompleted;

  /// How much ahead or behind schedule (in seconds)
  /// Positive = ahead, Negative = behind
  final int scheduleVariance;

  /// When the routine started
  final DateTime routineStartTime;

  /// Human-readable status text
  String get statusText {
    if (scheduleVariance == 0) {
      return 'On track';
    } else if (scheduleVariance > 0) {
      final minutes = scheduleVariance ~/ 60;
      final seconds = scheduleVariance % 60;
      if (minutes > 0) {
        return 'Ahead by $minutes min ${seconds > 0 ? "$seconds sec" : ""}';
      } else {
        return 'Ahead by $seconds sec';
      }
    } else {
      final absVariance = scheduleVariance.abs();
      final minutes = absVariance ~/ 60;
      final seconds = absVariance % 60;
      if (minutes > 0) {
        return 'Behind by $minutes min ${seconds > 0 ? "$seconds sec" : ""}';
      } else {
        return 'Behind by $seconds sec';
      }
    }
  }

  /// Format total time spent as MM:SS
  String get formattedTotalTime {
    final minutes = totalTimeSpent ~/ 60;
    final seconds = totalTimeSpent % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  RoutineCompletion copyWith({
    String? completionId,
    DateTime? completedAt,
    int? totalTimeSpent,
    int? tasksCompleted,
    int? scheduleVariance,
    DateTime? routineStartTime,
  }) {
    return RoutineCompletion(
      completionId: completionId ?? this.completionId,
      completedAt: completedAt ?? this.completedAt,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      scheduleVariance: scheduleVariance ?? this.scheduleVariance,
      routineStartTime: routineStartTime ?? this.routineStartTime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completionId': completionId,
      'completedAt': completedAt.millisecondsSinceEpoch,
      'totalTimeSpent': totalTimeSpent,
      'tasksCompleted': tasksCompleted,
      'scheduleVariance': scheduleVariance,
      'routineStartTime': routineStartTime.millisecondsSinceEpoch,
    };
  }

  factory RoutineCompletion.fromMap(Map<String, dynamic> map) {
    return RoutineCompletion(
      completionId: map['completionId'] as String?,
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map['completedAt'] as int,
      ),
      totalTimeSpent: map['totalTimeSpent'] as int,
      tasksCompleted: map['tasksCompleted'] as int,
      scheduleVariance: map['scheduleVariance'] as int,
      routineStartTime: DateTime.fromMillisecondsSinceEpoch(
        map['routineStartTime'] as int,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineCompletion.fromJson(String source) =>
      RoutineCompletion.fromMap(json.decode(source) as Map<String, dynamic>);
}
