import 'dart:convert';

/// Represents a break (gap) between tasks.
class BreakModel {
  const BreakModel({
    required this.duration,
    this.isEnabled = true,
    this.isCustomized = false,
  });

  /// Break duration in seconds.
  final int duration;

  /// Whether this break is active. Disabled breaks have zero effect on timing.
  final bool isEnabled;

  /// Whether this break's duration has been customized by the user.
  /// If false, it will use the default break duration from settings.
  final bool isCustomized;

  BreakModel copyWith({int? duration, bool? isEnabled, bool? isCustomized}) {
    return BreakModel(
      duration: duration ?? this.duration,
      isEnabled: isEnabled ?? this.isEnabled,
      isCustomized: isCustomized ?? this.isCustomized,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'duration': duration,
      'isEnabled': isEnabled,
      'isCustomized': isCustomized,
    };
  }

  factory BreakModel.fromMap(Map<String, dynamic> map) {
    return BreakModel(
      duration: map['duration'] as int,
      isEnabled: map['isEnabled'] as bool? ?? true,
      isCustomized: map['isCustomized'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory BreakModel.fromJson(String source) =>
      BreakModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
