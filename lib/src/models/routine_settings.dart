import 'dart:convert';

/// Routine-wide settings such as start time and default break configuration.
class RoutineSettingsModel {
  const RoutineSettingsModel({
    required this.startTime,
    this.breaksEnabledByDefault = true,
    required this.defaultBreakDuration,
  });

  /// Routine start time represented as milliseconds since epoch (UTC).
  /// Using int keeps the model JSON friendly without DateTime serialization concerns.
  final int startTime;

  /// If true, gaps between tasks are created as enabled breaks by default.
  final bool breaksEnabledByDefault;

  /// Default break duration in seconds when a gap is enabled.
  final int defaultBreakDuration;

  RoutineSettingsModel copyWith({
    int? startTime,
    bool? breaksEnabledByDefault,
    int? defaultBreakDuration,
  }) {
    return RoutineSettingsModel(
      startTime: startTime ?? this.startTime,
      breaksEnabledByDefault:
          breaksEnabledByDefault ?? this.breaksEnabledByDefault,
      defaultBreakDuration: defaultBreakDuration ?? this.defaultBreakDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startTime': startTime,
      'breaksEnabledByDefault': breaksEnabledByDefault,
      'defaultBreakDuration': defaultBreakDuration,
    };
  }

  factory RoutineSettingsModel.fromMap(Map<String, dynamic> map) {
    return RoutineSettingsModel(
      startTime: map['startTime'] as int,
      breaksEnabledByDefault: map['breaksEnabledByDefault'] as bool? ?? true,
      defaultBreakDuration: map['defaultBreakDuration'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory RoutineSettingsModel.fromJson(String source) =>
      RoutineSettingsModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
