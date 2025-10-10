import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_completion.dart';

void main() {
  group('RoutineCompletionModel', () {
    late DateTime testCompletedAt;
    late RoutineCompletionModel testCompletion;

    setUp(() {
      testCompletedAt = DateTime(2025, 1, 10, 8, 30);
      testCompletion = RoutineCompletionModel(
        completedAt: testCompletedAt,
        totalTimeSpent: 3600, // 1 hour
        tasksCompleted: 3,
        totalTasks: 4,
        finalAheadBehindStatus: -300, // 5 minutes behind
        tasks: [
          const CompletedTaskModel(
            id: '1',
            name: 'Morning Workout',
            estimatedDuration: 1200, // 20 minutes
            actualDuration: 1500, // 25 minutes (5 minutes over)
            isCompleted: true,
            order: 0,
          ),
          const CompletedTaskModel(
            id: '2',
            name: 'Shower',
            estimatedDuration: 600, // 10 minutes
            actualDuration: 600, // exactly 10 minutes
            isCompleted: true,
            order: 1,
          ),
          const CompletedTaskModel(
            id: '3',
            name: 'Breakfast',
            estimatedDuration: 900, // 15 minutes
            actualDuration: 800, // 13 minutes and 20 seconds (100 seconds under)
            isCompleted: true,
            order: 2,
          ),
          const CompletedTaskModel(
            id: '4',
            name: 'Review Plan',
            estimatedDuration: 300, // 5 minutes
            actualDuration: 0, // not completed
            isCompleted: false,
            order: 3,
          ),
        ],
        routineStartTime: DateTime(2025, 1, 10, 7, 30),
      );
    });

    test('should create a valid RoutineCompletionModel', () {
      expect(testCompletion.completedAt, equals(testCompletedAt));
      expect(testCompletion.totalTimeSpent, equals(3600));
      expect(testCompletion.tasksCompleted, equals(3));
      expect(testCompletion.totalTasks, equals(4));
      expect(testCompletion.finalAheadBehindStatus, equals(-300));
      expect(testCompletion.tasks.length, equals(4));
    });

    test('should correctly determine if fully completed', () {
      expect(testCompletion.isFullyCompleted, isFalse);

      final fullyCompleted = testCompletion.copyWith(
        tasksCompleted: 4,
        tasks: testCompletion.tasks
            .map((task) => task.copyWith(isCompleted: true))
            .toList(),
      );
      expect(fullyCompleted.isFullyCompleted, isTrue);
    });

    test('should format ahead/behind status correctly', () {
      // Test behind status
      expect(testCompletion.aheadBehindText, equals('5m 0s behind'));

      // Test ahead status
      final aheadCompletion = testCompletion.copyWith(
        finalAheadBehindStatus: 120, // 2 minutes ahead
      );
      expect(aheadCompletion.aheadBehindText, equals('2m 0s ahead'));

      // Test on time
      final onTimeCompletion = testCompletion.copyWith(
        finalAheadBehindStatus: 0,
      );
      expect(onTimeCompletion.aheadBehindText, equals('On time'));

      // Test seconds only
      final secondsCompletion = testCompletion.copyWith(
        finalAheadBehindStatus: 45, // 45 seconds ahead
      );
      expect(secondsCompletion.aheadBehindText, equals('45s ahead'));
    });

    test('should serialize to and from JSON correctly', () {
      final json = testCompletion.toJson();
      final fromJson = RoutineCompletionModel.fromJson(json);

      expect(fromJson.completedAt, equals(testCompletion.completedAt));
      expect(fromJson.totalTimeSpent, equals(testCompletion.totalTimeSpent));
      expect(fromJson.tasksCompleted, equals(testCompletion.tasksCompleted));
      expect(fromJson.totalTasks, equals(testCompletion.totalTasks));
      expect(fromJson.finalAheadBehindStatus, equals(testCompletion.finalAheadBehindStatus));
      expect(fromJson.tasks.length, equals(testCompletion.tasks.length));
      expect(fromJson.routineStartTime, equals(testCompletion.routineStartTime));
    });

    test('should serialize to and from Map correctly', () {
      final map = testCompletion.toMap();
      final fromMap = RoutineCompletionModel.fromMap(map);

      expect(fromMap.completedAt, equals(testCompletion.completedAt));
      expect(fromMap.totalTimeSpent, equals(testCompletion.totalTimeSpent));
      expect(fromMap.tasksCompleted, equals(testCompletion.tasksCompleted));
      expect(fromMap.totalTasks, equals(testCompletion.totalTasks));
      expect(fromMap.finalAheadBehindStatus, equals(testCompletion.finalAheadBehindStatus));
      expect(fromMap.tasks.length, equals(testCompletion.tasks.length));
      expect(fromMap.routineStartTime, equals(testCompletion.routineStartTime));
    });

    test('should handle null routineStartTime correctly', () {
      final completion = testCompletion.copyWith(routineStartTime: null);
      final map = completion.toMap();
      final fromMap = RoutineCompletionModel.fromMap(map);

      expect(fromMap.routineStartTime, isNull);
    });
  });

  group('CompletedTaskModel', () {
    late CompletedTaskModel testTask;

    setUp(() {
      testTask = const CompletedTaskModel(
        id: '1',
        name: 'Test Task',
        estimatedDuration: 600, // 10 minutes
        actualDuration: 720, // 12 minutes
        isCompleted: true,
        order: 0,
      );
    });

    test('should create a valid CompletedTaskModel', () {
      expect(testTask.id, equals('1'));
      expect(testTask.name, equals('Test Task'));
      expect(testTask.estimatedDuration, equals(600));
      expect(testTask.actualDuration, equals(720));
      expect(testTask.isCompleted, isTrue);
      expect(testTask.order, equals(0));
    });

    test('should calculate duration difference correctly', () {
      expect(testTask.durationDifference, equals(120)); // 2 minutes over

      final aheadTask = testTask.copyWith(actualDuration: 480); // 8 minutes
      expect(aheadTask.durationDifference, equals(-120)); // 2 minutes under
    });

    test('should determine if ahead or behind correctly', () {
      expect(testTask.isAhead, isFalse);
      expect(testTask.isBehind, isTrue);

      final aheadTask = testTask.copyWith(actualDuration: 480);
      expect(aheadTask.isAhead, isTrue);
      expect(aheadTask.isBehind, isFalse);

      final onTimeTask = testTask.copyWith(actualDuration: 600);
      expect(onTimeTask.isAhead, isFalse);
      expect(onTimeTask.isBehind, isFalse);
    });

    test('should serialize to and from JSON correctly', () {
      final json = testTask.toJson();
      final fromJson = CompletedTaskModel.fromJson(json);

      expect(fromJson.id, equals(testTask.id));
      expect(fromJson.name, equals(testTask.name));
      expect(fromJson.estimatedDuration, equals(testTask.estimatedDuration));
      expect(fromJson.actualDuration, equals(testTask.actualDuration));
      expect(fromJson.isCompleted, equals(testTask.isCompleted));
      expect(fromJson.order, equals(testTask.order));
    });

    test('should serialize to and from Map correctly', () {
      final map = testTask.toMap();
      final fromMap = CompletedTaskModel.fromMap(map);

      expect(fromMap.id, equals(testTask.id));
      expect(fromMap.name, equals(testTask.name));
      expect(fromMap.estimatedDuration, equals(testTask.estimatedDuration));
      expect(fromMap.actualDuration, equals(testTask.actualDuration));
      expect(fromMap.isCompleted, equals(testTask.isCompleted));
      expect(fromMap.order, equals(testTask.order));
    });
  });
}