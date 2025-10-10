import 'dart:convert';

/// Represents the schedule tracking status (ahead/behind/on-track)
enum ScheduleStatusType { ahead, behind, onTrack }

/// Model for schedule tracking calculations
class ScheduleStatus {
  const ScheduleStatus({
    required this.type,
    required this.minutesDifference,
    required this.estimatedCompletionTime,
    required this.totalExpectedDuration,
    required this.totalActualDuration,
    required this.totalRemainingDuration,
  });

  /// Whether the routine is ahead, behind, or on track
  final ScheduleStatusType type;

  /// Number of minutes ahead/behind (positive = ahead, negative = behind)
  final int minutesDifference;

  /// Estimated time of completion based on current progress
  final DateTime estimatedCompletionTime;

  /// Total expected duration for all tasks in seconds
  final int totalExpectedDuration;

  /// Total actual duration for completed tasks in seconds
  final int totalActualDuration;

  /// Total remaining duration for incomplete tasks in seconds
  final int totalRemainingDuration;

  ScheduleStatus copyWith({
    ScheduleStatusType? type,
    int? minutesDifference,
    DateTime? estimatedCompletionTime,
    int? totalExpectedDuration,
    int? totalActualDuration,
    int? totalRemainingDuration,
  }) {
    return ScheduleStatus(
      type: type ?? this.type,
      minutesDifference: minutesDifference ?? this.minutesDifference,
      estimatedCompletionTime:
          estimatedCompletionTime ?? this.estimatedCompletionTime,
      totalExpectedDuration:
          totalExpectedDuration ?? this.totalExpectedDuration,
      totalActualDuration: totalActualDuration ?? this.totalActualDuration,
      totalRemainingDuration:
          totalRemainingDuration ?? this.totalRemainingDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'minutesDifference': minutesDifference,
      'estimatedCompletionTime': estimatedCompletionTime.millisecondsSinceEpoch,
      'totalExpectedDuration': totalExpectedDuration,
      'totalActualDuration': totalActualDuration,
      'totalRemainingDuration': totalRemainingDuration,
    };
  }

  factory ScheduleStatus.fromMap(Map<String, dynamic> map) {
    return ScheduleStatus(
      type: ScheduleStatusType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ScheduleStatusType.onTrack,
      ),
      minutesDifference: map['minutesDifference'] as int,
      estimatedCompletionTime: DateTime.fromMillisecondsSinceEpoch(
        map['estimatedCompletionTime'] as int,
      ),
      totalExpectedDuration: map['totalExpectedDuration'] as int,
      totalActualDuration: map['totalActualDuration'] as int,
      totalRemainingDuration: map['totalRemainingDuration'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleStatus.fromJson(String source) =>
      ScheduleStatus.fromMap(json.decode(source) as Map<String, dynamic>);
}
