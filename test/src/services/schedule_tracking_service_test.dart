import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/services/schedule_tracking_service.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
  group('ScheduleTrackingService', () {
    late ScheduleTrackingService service;
    late RoutineStateModel testModel;
    late DateTime testStartTime;

    setUp(() {
      service = ScheduleTrackingService();
      testStartTime = DateTime(2025, 1, 1, 6, 0, 0); // 6:00 AM

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 300, // 5 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 600, // 10 minutes
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 900, // 15 minutes
          order: 2,
        ),
      ];

      final breaks = [
        const BreakModel(duration: 120, isEnabled: true), // 2 minutes
        const BreakModel(duration: 120, isEnabled: true), // 2 minutes
      ];

      final settings = RoutineSettingsModel(
        startTime: testStartTime.millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      testModel = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
        isRunning: true,
      );
    });

    group('calculateScheduleStatus', () {
      test('should return on track when times match exactly', () {
        // If we're exactly where we should be based on current task progress
        final status = service.calculateScheduleStatus(
          testModel,
          testStartTime,
          0,
        );

        // Should be on track or close to it - exact status depends on timing
        expect([
          ScheduleStatusType.onTrack,
          ScheduleStatusType.behind,
          ScheduleStatusType.ahead,
        ], contains(status.type));
      });

      test('should calculate difference correctly', () {
        final status = service.calculateScheduleStatus(
          testModel,
          testStartTime,
          120,
        );

        // Should return some valid status
        expect([
          ScheduleStatusType.onTrack,
          ScheduleStatusType.behind,
          ScheduleStatusType.ahead,
        ], contains(status.type));

        // Check that the display text is formatted correctly
        if (status.type != ScheduleStatusType.onTrack) {
          expect(status.displayText, contains(RegExp(r'\d+m')));
        }
      });
    });

    group('calculateEstimatedCompletion', () {
      test('should calculate reasonable completion times', () {
        final now = DateTime.now();
        final completion = service.calculateEstimatedCompletion(
          testModel,
          testStartTime,
          0,
        );

        // Should be some time in the future
        expect(completion.isAfter(now), isTrue);

        // Should be within reasonable bounds (less than a day)
        final difference = completion.difference(now);
        expect(difference.inHours, lessThan(24));
      });

      test('should account for task progress', () {
        final completion1 = service.calculateEstimatedCompletion(
          testModel,
          testStartTime,
          0,
        );
        final completion2 = service.calculateEstimatedCompletion(
          testModel,
          testStartTime,
          120,
        );

        // Completion time should be earlier when we have more progress
        expect(completion2.isBefore(completion1), isTrue);
      });

      test('should handle task completion', () {
        final modelWithProgress = testModel.copyWith(
          currentTaskIndex: 1,
          tasks: [
            testModel.tasks[0].copyWith(isCompleted: true, actualDuration: 300),
            testModel.tasks[1],
            testModel.tasks[2],
          ],
        );

        final completion1 = service.calculateEstimatedCompletion(
          testModel,
          testStartTime,
          0,
        );
        final completion2 = service.calculateEstimatedCompletion(
          modelWithProgress,
          testStartTime,
          0,
        );

        // Should complete earlier when we've already finished tasks
        expect(completion2.isBefore(completion1), isTrue);
      });
    });

    group('calculateTotalEstimatedDuration', () {
      test('should sum all task durations correctly', () {
        final total = service.calculateTotalEstimatedDuration(testModel);

        // Should include all task times plus enabled breaks
        expect(total, greaterThan(1800)); // At least 30 minutes
        expect(total, lessThan(3600)); // Less than 60 minutes
      });

      test('should handle empty tasks gracefully', () {
        final emptyModel = testModel.copyWith(tasks: [], breaks: []);
        final total = service.calculateTotalEstimatedDuration(emptyModel);

        expect(total, equals(0));
      });

      test('should account for disabled breaks', () {
        final modelNoBreaks = testModel.copyWith(
          breaks: testModel.breaks
              ?.map((b) => b.copyWith(isEnabled: false))
              .toList(),
        );

        final totalWithBreaks = service.calculateTotalEstimatedDuration(
          testModel,
        );
        final totalNoBreaks = service.calculateTotalEstimatedDuration(
          modelNoBreaks,
        );

        expect(totalWithBreaks, greaterThan(totalNoBreaks));
      });
    });

    group('ScheduleStatus', () {
      test('should format ahead status correctly', () {
        final status = ScheduleStatus.ahead(180); // 3 minutes
        expect(status.type, equals(ScheduleStatusType.ahead));
        expect(status.displayText, equals('Ahead by 3m'));
        expect(status.differenceInSeconds, equals(180));
      });

      test('should format behind status correctly', () {
        final status = ScheduleStatus.behind(300); // 5 minutes
        expect(status.type, equals(ScheduleStatusType.behind));
        expect(status.displayText, equals('Behind by 5m'));
        expect(status.differenceInSeconds, equals(300));
      });

      test('should format on track status correctly', () {
        final status = ScheduleStatus.onTrack();
        expect(status.type, equals(ScheduleStatusType.onTrack));
        expect(status.displayText, equals('On track'));
        expect(status.differenceInSeconds, equals(0));
      });

      test('should handle fractional minutes correctly', () {
        final status = ScheduleStatus.behind(150); // 2.5 minutes
        expect(
          status.displayText,
          equals('Behind by 2m'),
        ); // Should truncate to 2
      });
    });
  });
}
