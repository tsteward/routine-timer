import 'dart:convert';

/// Represents a reusable task template in the task library.
///
/// Library tasks serve as templates that can be added to routines multiple times.
/// When a user creates a new task, it's automatically saved as a library task.
/// Library tasks maintain their own identity separate from routine tasks.
class LibraryTask {
  const LibraryTask({
    required this.id,
    required this.name,
    required this.defaultDuration,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// Unique identifier for this library task.
  final String id;

  /// Task name (e.g., "Morning Shower", "Breakfast").
  final String name;

  /// Default duration in seconds.
  final int defaultDuration;

  /// Timestamp when this task was first created.
  final DateTime createdAt;

  /// Timestamp when this task was last added to a routine.
  /// Null if the task has never been used.
  final DateTime? lastUsedAt;

  LibraryTask copyWith({
    String? id,
    String? name,
    int? defaultDuration,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return LibraryTask(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'defaultDuration': defaultDuration,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUsedAt': lastUsedAt?.millisecondsSinceEpoch,
    };
  }

  factory LibraryTask.fromMap(Map<String, dynamic> map) {
    return LibraryTask(
      id: map['id'] as String,
      name: map['name'] as String,
      defaultDuration: map['defaultDuration'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastUsedAt: map['lastUsedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUsedAt'] as int)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LibraryTask.fromJson(String source) =>
      LibraryTask.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LibraryTask &&
        other.id == id &&
        other.name == name &&
        other.defaultDuration == defaultDuration &&
        other.createdAt == createdAt &&
        other.lastUsedAt == lastUsedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        defaultDuration.hashCode ^
        createdAt.hashCode ^
        lastUsedAt.hashCode;
  }
}
