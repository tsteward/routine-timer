import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_completion.dart';

void main() {
  group('RoutineCompletion', () {
    test('should create a completion with required fields', () {
      final completedAt = DateTime(2025, 10, 14, 9, 30);
      final completion = RoutineCompletion(
        completedAt: completedAt,
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -120,
      );

      expect(completion.completedAt, equals(completedAt));
      expect(completion.totalTimeSpent, equals(3600));
      expect(completion.tasksCompleted, equals(5));
      expect(completion.scheduleStatus, equals('ahead'));
      expect(completion.scheduleVarianceSeconds, equals(-120));
    });

    test('should serialize to map correctly', () {
      final completedAt = DateTime(2025, 10, 14, 9, 30);
      final completion = RoutineCompletion(
        completedAt: completedAt,
        totalTimeSpent: 3600,
        tasksCompleted: 5,
        scheduleStatus: 'behind',
        scheduleVarianceSeconds: 180,
      );

      final map = completion.toMap();

      expect(map['completedAt'], equals(completedAt.millisecondsSinceEpoch));
      expect(map['totalTimeSpent'], equals(3600));
      expect(map['tasksCompleted'], equals(5));
      expect(map['scheduleStatus'], equals('behind'));
      expect(map['scheduleVarianceSeconds'], equals(180));
    });

    test('should deserialize from map correctly', () {
      final completedAt = DateTime(2025, 10, 14, 9, 30);
      final map = {
        'completedAt': completedAt.millisecondsSinceEpoch,
        'totalTimeSpent': 2400,
        'tasksCompleted': 3,
        'scheduleStatus': 'on-track',
        'scheduleVarianceSeconds': 30,
      };

      final completion = RoutineCompletion.fromMap(map);

      expect(completion.completedAt, equals(completedAt));
      expect(completion.totalTimeSpent, equals(2400));
      expect(completion.tasksCompleted, equals(3));
      expect(completion.scheduleStatus, equals('on-track'));
      expect(completion.scheduleVarianceSeconds, equals(30));
    });

    test('should serialize to JSON and back correctly', () {
      final completedAt = DateTime(2025, 10, 14, 9, 30);
      final original = RoutineCompletion(
        completedAt: completedAt,
        totalTimeSpent: 1800,
        tasksCompleted: 4,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -90,
      );

      final json = original.toJson();
      final deserialized = RoutineCompletion.fromJson(json);

      expect(deserialized.completedAt, equals(original.completedAt));
      expect(deserialized.totalTimeSpent, equals(original.totalTimeSpent));
      expect(deserialized.tasksCompleted, equals(original.tasksCompleted));
      expect(deserialized.scheduleStatus, equals(original.scheduleStatus));
      expect(
        deserialized.scheduleVarianceSeconds,
        equals(original.scheduleVarianceSeconds),
      );
    });

    test('should handle different schedule statuses', () {
      final completedAt = DateTime.now();

      final ahead = RoutineCompletion(
        completedAt: completedAt,
        totalTimeSpent: 1000,
        tasksCompleted: 3,
        scheduleStatus: 'ahead',
        scheduleVarianceSeconds: -120,
      );
      expect(ahead.scheduleStatus, equals('ahead'));

      final behind = RoutineCompletion(
        completedAt: completedAt,
        totalTimeSpent: 1000,
        tasksCompleted: 3,
        scheduleStatus: 'behind',
        scheduleVarianceSeconds: 120,
      );
      expect(behind.scheduleStatus, equals('behind'));

      final onTrack = RoutineCompletion(
        completedAt: completedAt,
        totalTimeSpent: 1000,
        tasksCompleted: 3,
        scheduleStatus: 'on-track',
        scheduleVarianceSeconds: 0,
      );
      expect(onTrack.scheduleStatus, equals('on-track'));
    });
  });
}
