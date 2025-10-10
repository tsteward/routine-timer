import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/services/schedule_service.dart';
import 'package:routine_timer/src/models/schedule_status.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';

void main() {
  group('ScheduleService', () {
    late RoutineStateModel routine;
    late DateTime routineStartTime;

    setUp(() {
      routineStartTime = DateTime(2025, 1, 1, 6, 0); // 6:00 AM

      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600, // 10 minutes
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 900, // 15 minutes
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 300, // 5 minutes
          order: 2,
        ),
      ];

      final breaks = [
        const BreakModel(
          duration: 120,
          isEnabled: true,
        ), // 2 minutes after task 1
        const BreakModel(
          duration: 180,
          isEnabled: true,
        ), // 3 minutes after task 2
      ];

      final settings = RoutineSettingsModel(
        startTime: routineStartTime.millisecondsSinceEpoch,
        breaksEnabledByDefault: true,
        defaultBreakDuration: 120,
      );

      routine = RoutineStateModel(
        tasks: tasks,
        breaks: breaks,
        settings: settings,
        currentTaskIndex: 0,
        isRunning: true,
      );
    });

    group('calculateScheduleStatus', () {
      test(
        'should calculate "on track" status when timing matches expectations',
        () {
          // Currently 5 minutes into first task (half way through)
          final status = ScheduleService.calculateScheduleStatus(
            routine: routine,
            currentTaskElapsedSeconds: 300, // 5 minutes
            routineStartTime: routineStartTime,
          );

          expect(status.type, equals(ScheduleStatusType.onTrack));
          expect(status.minutesDifference, equals(0));
        },
      );

      test('should calculate "ahead" status when completing tasks faster', () {
        // Completed first task in 8 minutes (2 minutes faster), now in second task
        final completedFirstTask = routine.tasks[0].copyWith(
          isCompleted: true,
          actualDuration: 480, // 8 minutes instead of 10
        );

        final routineWithProgress = routine.copyWith(
          tasks: [completedFirstTask, routine.tasks[1], routine.tasks[2]],
          currentTaskIndex: 1,
        );

        final status = ScheduleService.calculateScheduleStatus(
          routine: routineWithProgress,
          currentTaskElapsedSeconds: 300, // 5 minutes into second task
          routineStartTime: routineStartTime,
        );

        expect(status.type, equals(ScheduleStatusType.ahead));
        expect(status.minutesDifference, greaterThan(0));
      });

      test(
        'should calculate "behind" status when taking longer than expected',
        () {
          // Taking 15 minutes to complete 10-minute first task
          final status = ScheduleService.calculateScheduleStatus(
            routine: routine,
            currentTaskElapsedSeconds: 900, // 15 minutes
            routineStartTime: routineStartTime,
          );

          expect(status.type, equals(ScheduleStatusType.behind));
          expect(status.minutesDifference, greaterThan(0));
        },
      );

      test(
        'should calculate correct estimated completion time when on track',
        () {
          final status = ScheduleService.calculateScheduleStatus(
            routine: routine,
            currentTaskElapsedSeconds: 300, // 5 minutes
            routineStartTime: routineStartTime,
          );

          // The estimated completion time should be after the current time
          final now = DateTime.now();
          expect(status.estimatedCompletionTime.isAfter(now), isTrue);

          // And it should be reasonable (not too far in the future)
          final differenceHours = status.estimatedCompletionTime
              .difference(now)
              .inHours;
          expect(differenceHours, lessThan(24)); // Should complete within a day
        },
      );

      test('should handle routine without breaks', () {
        final routineWithoutBreaks = routine.copyWith(breaks: null);

        final status = ScheduleService.calculateScheduleStatus(
          routine: routineWithoutBreaks,
          currentTaskElapsedSeconds: 300, // 5 minutes
          routineStartTime: routineStartTime,
        );

        expect(
          status.type,
          isIn([
            ScheduleStatusType.onTrack,
            ScheduleStatusType.ahead,
            ScheduleStatusType.behind,
          ]),
        );
      });

      test('should handle disabled breaks', () {
        final disabledBreaks = [
          const BreakModel(duration: 120, isEnabled: false),
          const BreakModel(duration: 180, isEnabled: false),
        ];

        final routineWithDisabledBreaks = routine.copyWith(
          breaks: disabledBreaks,
        );

        final status = ScheduleService.calculateScheduleStatus(
          routine: routineWithDisabledBreaks,
          currentTaskElapsedSeconds: 300,
          routineStartTime: routineStartTime,
        );

        expect(
          status.type,
          isIn([
            ScheduleStatusType.onTrack,
            ScheduleStatusType.ahead,
            ScheduleStatusType.behind,
          ]),
        );
      });

      test('should calculate correct totals', () {
        final status = ScheduleService.calculateScheduleStatus(
          routine: routine,
          currentTaskElapsedSeconds: 300,
          routineStartTime: routineStartTime,
        );

        // Total expected: 600 + 900 + 300 + 120 + 180 = 2100 seconds
        expect(status.totalExpectedDuration, equals(2100));

        // Total actual so far: 300 seconds (current task progress)
        expect(status.totalActualDuration, equals(300));

        // Total remaining: (600-300) + 120 + 900 + 180 + 300 = 1800 seconds
        expect(status.totalRemainingDuration, equals(1800));
      });

      test(
        'should handle edge case when current task elapsed exceeds estimated duration',
        () {
          // Spent 20 minutes on a 10-minute task
          final status = ScheduleService.calculateScheduleStatus(
            routine: routine,
            currentTaskElapsedSeconds: 1200, // 20 minutes
            routineStartTime: routineStartTime,
          );

          expect(status.type, equals(ScheduleStatusType.behind));
          expect(status.totalActualDuration, equals(1200));
        },
      );

      test('should handle completed tasks with actual durations', () {
        final completedTask1 = routine.tasks[0].copyWith(
          isCompleted: true,
          actualDuration: 480, // 8 minutes
        );

        final completedTask2 = routine.tasks[1].copyWith(
          isCompleted: true,
          actualDuration: 1080, // 18 minutes
        );

        final routineWithCompletedTasks = routine.copyWith(
          tasks: [completedTask1, completedTask2, routine.tasks[2]],
          currentTaskIndex: 2,
        );

        final status = ScheduleService.calculateScheduleStatus(
          routine: routineWithCompletedTasks,
          currentTaskElapsedSeconds: 150, // 2.5 minutes into third task
          routineStartTime: routineStartTime,
        );

        // Total actual: 480 + 120 + 1080 + 180 + 150 = 2010 seconds
        expect(status.totalActualDuration, equals(2010));
      });

      test('should handle last task completion', () {
        final allTasksCompleted = [
          routine.tasks[0].copyWith(isCompleted: true, actualDuration: 600),
          routine.tasks[1].copyWith(isCompleted: true, actualDuration: 900),
          routine.tasks[2].copyWith(isCompleted: true, actualDuration: 300),
        ];

        final completedRoutine = routine.copyWith(
          tasks: allTasksCompleted,
          currentTaskIndex: 2, // Still on last task
        );

        final status = ScheduleService.calculateScheduleStatus(
          routine: completedRoutine,
          currentTaskElapsedSeconds: 300, // Completed the last task
          routineStartTime: routineStartTime,
        );

        expect(status.totalRemainingDuration, equals(0));
      });
    });
  });
}
