import 'dart:convert';

/// Represents a break (gap) between tasks.
class BreakModel {
  const BreakModel({
    required this.duration,
    this.isEnabled = true,
  });

  /// Break duration in seconds.
  final int duration;

  /// Whether this break is active. Disabled breaks have zero effect on timing.
  final bool isEnabled;

  BreakModel copyWith({int? duration, bool? isEnabled}) {
    return BreakModel(
      duration: duration ?? this.duration,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'duration': duration,
      'isEnabled': isEnabled,
    };
  }

  factory BreakModel.fromMap(Map<String, dynamic> map) {
    return BreakModel(
      duration: map['duration'] as int,
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory BreakModel.fromJson(String source) => BreakModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}


