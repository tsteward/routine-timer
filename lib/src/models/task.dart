import 'dart:convert';

/// Represents a single task within a morning routine.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.name,
    required this.estimatedDuration,
    this.actualDuration,
    this.isCompleted = false,
    required this.order,
  });

  /// Unique identifier for this task.
  final String id;

  /// Human friendly task name, e.g. "Shower".
  final String name;

  /// Estimated duration in seconds.
  final int estimatedDuration;

  /// Actual duration in seconds once completed. Null until completed.
  final int? actualDuration;

  /// Whether the task has been completed for the current session.
  final bool isCompleted;

  /// Ordering index within the routine. Lower appears earlier.
  final int order;

  TaskModel copyWith({
    String? id,
    String? name,
    int? estimatedDuration,
    int? actualDuration,
    bool? isCompleted,
    int? order,
  }) {
    return TaskModel(
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

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      name: map['name'] as String,
      estimatedDuration: map['estimatedDuration'] as int,
      actualDuration: map['actualDuration'] as int?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      order: map['order'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskModel.fromJson(String source) => TaskModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}


