import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/services/schedule_tracker.dart';

void main() {
  group('ScheduleTracker', () {
    late ScheduleTracker tracker;

    setUp(() {
      tracker = const ScheduleTracker();
    });

    group('calculateScheduleStatus', () {
      test('returns on track status with no completed tasks', () {
        final routine = RoutineStateModel(
          tasks: [
            const TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 60,
              order: 0,
            ),
            const TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 60,
              order: 1,
            ),
          ],
          settings: RoutineSettingsModel(
            startTime: DateTime.now().millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '1',
        );

        final status = tracker.calculateScheduleStatus(routine);

        expect(status.status, ScheduleStatusType.onTrack);
        expect(status.varianceSeconds, 0);
      });

      test(
        'returns ahead status when tasks completed faster than estimated',
        () {
          final routine = RoutineStateModel(
            tasks: [
              const TaskModel(
                id: '1',
                name: 'Task 1',
                estimatedDuration: 120,
                actualDuration: 60, // 60 seconds faster
                isCompleted: true,
                order: 0,
              ),
              const TaskModel(
                id: '2',
                name: 'Task 2',
                estimatedDuration: 60,
                order: 1,
              ),
            ],
            settings: RoutineSettingsModel(
              startTime: DateTime.now().millisecondsSinceEpoch,
              defaultBreakDuration: 30,
            ),
            selectedTaskId: '2',
          );

          final status = tracker.calculateScheduleStatus(routine);

          expect(status.status, ScheduleStatusType.ahead);
          expect(status.varianceSeconds, -60); // Negative means ahead
          expect(status.absoluteVarianceSeconds, 60);
        },
      );

      test('returns behind status when tasks take longer than estimated', () {
        final routine = RoutineStateModel(
          tasks: [
            const TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 60,
              actualDuration: 120, // 60 seconds slower
              isCompleted: true,
              order: 0,
            ),
            const TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 60,
              order: 1,
            ),
          ],
          settings: RoutineSettingsModel(
            startTime: DateTime.now().millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '2',
        );

        final status = tracker.calculateScheduleStatus(routine);

        expect(status.status, ScheduleStatusType.behind);
        expect(status.varianceSeconds, 60); // Positive means behind
        expect(status.absoluteVarianceSeconds, 60);
      });

      test('includes break time in schedule calculation', () {
        final routine = RoutineStateModel(
          tasks: [
            const TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 60,
              actualDuration: 60,
              isCompleted: true,
              order: 0,
            ),
            const TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 60,
              order: 1,
            ),
          ],
          breaks: const [BreakModel(duration: 30, isEnabled: true)],
          settings: RoutineSettingsModel(
            startTime: DateTime.now().millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '2',
        );

        final status = tracker.calculateScheduleStatus(routine);

        // Expected: 60 (task) + 30 (break) = 90 seconds
        // Actual: 60 (task) + 30 (break) = 90 seconds
        expect(status.varianceSeconds, 0);
        expect(status.status, ScheduleStatusType.onTrack);
      });

      test('ignores disabled breaks in schedule calculation', () {
        final routine = RoutineStateModel(
          tasks: [
            const TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 60,
              actualDuration: 60,
              isCompleted: true,
              order: 0,
            ),
            const TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 60,
              order: 1,
            ),
          ],
          breaks: const [BreakModel(duration: 30, isEnabled: false)],
          settings: RoutineSettingsModel(
            startTime: DateTime.now().millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '2',
        );

        final status = tracker.calculateScheduleStatus(routine);

        // Expected: 60 (task) + 0 (break disabled) = 60 seconds
        // Actual: 60 (task) + 0 (break disabled) = 60 seconds
        expect(status.varianceSeconds, 0);
        expect(status.status, ScheduleStatusType.onTrack);
      });

      test('handles multiple completed tasks with varying times', () {
        final routine = RoutineStateModel(
          tasks: [
            const TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 100,
              actualDuration: 80, // 20 seconds faster
              isCompleted: true,
              order: 0,
            ),
            const TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 100,
              actualDuration: 130, // 30 seconds slower
              isCompleted: true,
              order: 1,
            ),
            const TaskModel(
              id: '3',
              name: 'Task 3',
              estimatedDuration: 100,
              order: 2,
            ),
          ],
          settings: RoutineSettingsModel(
            startTime: DateTime.now().millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '3',
        );

        final status = tracker.calculateScheduleStatus(routine);

        // Expected: 200 seconds
        // Actual: 210 seconds (80 + 130)
        // Variance: +10 seconds (behind)
        expect(status.varianceSeconds, 10);
        expect(status.status, ScheduleStatusType.onTrack); // Within threshold
      });

      test('calculates estimated completion time correctly', () {
        final now = DateTime.now();
        final routine = RoutineStateModel(
          tasks: [
            const TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 60,
              actualDuration: 60,
              isCompleted: true,
              order: 0,
            ),
            const TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 120, // 2 minutes remaining
              order: 1,
            ),
          ],
          settings: RoutineSettingsModel(
            startTime: now.millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '2',
        );

        final status = tracker.calculateScheduleStatus(routine);

        expect(status.estimatedCompletionTime, isNotNull);

        // Should be approximately now + 120 seconds
        final expectedCompletion = now.add(const Duration(seconds: 120));
        final actualCompletion = status.estimatedCompletionTime!;

        // Allow 5 second tolerance for test execution time
        final difference = actualCompletion
            .difference(expectedCompletion)
            .abs();
        expect(difference.inSeconds, lessThan(5));
      });

      test('adjusts estimated completion time based on variance', () {
        final now = DateTime.now();
        final routine = RoutineStateModel(
          tasks: [
            const TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 100,
              actualDuration: 150, // 50 seconds behind
              isCompleted: true,
              order: 0,
            ),
            const TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 100,
              order: 1,
            ),
          ],
          settings: RoutineSettingsModel(
            startTime: now.millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '2',
        );

        final status = tracker.calculateScheduleStatus(routine);

        // Remaining time: 100 seconds
        // Variance: +50 seconds (behind)
        // Adjusted remaining: 100 + 50 = 150 seconds
        final expectedCompletion = now.add(const Duration(seconds: 150));
        final actualCompletion = status.estimatedCompletionTime!;

        final difference = actualCompletion
            .difference(expectedCompletion)
            .abs();
        expect(difference.inSeconds, lessThan(5));
      });

      test('returns on track for variance within threshold', () {
        final routine = RoutineStateModel(
          tasks: [
            const TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 100,
              actualDuration: 115, // 15 seconds behind
              isCompleted: true,
              order: 0,
            ),
            const TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 60,
              order: 1,
            ),
          ],
          settings: RoutineSettingsModel(
            startTime: DateTime.now().millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '2',
        );

        final status = tracker.calculateScheduleStatus(routine);

        // Variance is 15 seconds, which is within the 30-second threshold
        expect(status.status, ScheduleStatusType.onTrack);
        expect(status.varianceSeconds, 15);
      });

      test('handles empty task list', () {
        final routine = RoutineStateModel(
          tasks: [],
          settings: RoutineSettingsModel(
            startTime: DateTime.now().millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
        );

        final status = tracker.calculateScheduleStatus(routine);

        expect(status.status, ScheduleStatusType.onTrack);
        expect(status.varianceSeconds, 0);
        expect(status.estimatedCompletionTime, isNull);
      });

      test('handles task with null actual duration', () {
        // This should use estimated duration as fallback
        final routine = RoutineStateModel(
          tasks: [
            const TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 100,
              actualDuration:
                  null, // Not completed yet but somehow selected away
              isCompleted: true,
              order: 0,
            ),
            const TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 60,
              order: 1,
            ),
          ],
          settings: RoutineSettingsModel(
            startTime: DateTime.now().millisecondsSinceEpoch,
            defaultBreakDuration: 30,
          ),
          selectedTaskId: '2',
        );

        final status = tracker.calculateScheduleStatus(routine);

        // Should use estimated duration (100) as fallback
        expect(status.varianceSeconds, 0);
        expect(status.status, ScheduleStatusType.onTrack);
      });
    });

    group('ScheduleStatus', () {
      test('formats variance string correctly for seconds', () {
        const status = ScheduleStatus(
          status: ScheduleStatusType.ahead,
          varianceSeconds: -45,
          estimatedCompletionTime: null,
        );

        expect(status.varianceString, '45 sec');
      });

      test('formats variance string correctly for minutes only', () {
        const status = ScheduleStatus(
          status: ScheduleStatusType.behind,
          varianceSeconds: 120,
          estimatedCompletionTime: null,
        );

        expect(status.varianceString, '2 min');
      });

      test('formats variance string correctly for minutes and seconds', () {
        const status = ScheduleStatus(
          status: ScheduleStatusType.behind,
          varianceSeconds: 135,
          estimatedCompletionTime: null,
        );

        expect(status.varianceString, '2 min 15 sec');
      });

      test('generates correct status text for ahead', () {
        const status = ScheduleStatus(
          status: ScheduleStatusType.ahead,
          varianceSeconds: -90,
          estimatedCompletionTime: null,
        );

        expect(status.statusText, 'Ahead by 1 min 30 sec');
      });

      test('generates correct status text for behind', () {
        const status = ScheduleStatus(
          status: ScheduleStatusType.behind,
          varianceSeconds: 75,
          estimatedCompletionTime: null,
        );

        expect(status.statusText, 'Behind by 1 min 15 sec');
      });

      test('generates correct status text for on track', () {
        const status = ScheduleStatus(
          status: ScheduleStatusType.onTrack,
          varianceSeconds: 10,
          estimatedCompletionTime: null,
        );

        expect(status.statusText, 'On Track');
      });

      test('formats completion time correctly for AM', () {
        final completionTime = DateTime(2025, 1, 1, 8, 30);
        final status = ScheduleStatus(
          status: ScheduleStatusType.onTrack,
          varianceSeconds: 0,
          estimatedCompletionTime: completionTime,
        );

        expect(status.completionTimeString, '8:30 AM');
      });

      test('formats completion time correctly for PM', () {
        final completionTime = DateTime(2025, 1, 1, 15, 45);
        final status = ScheduleStatus(
          status: ScheduleStatusType.onTrack,
          varianceSeconds: 0,
          estimatedCompletionTime: completionTime,
        );

        expect(status.completionTimeString, '3:45 PM');
      });

      test('formats completion time correctly for noon', () {
        final completionTime = DateTime(2025, 1, 1, 12, 0);
        final status = ScheduleStatus(
          status: ScheduleStatusType.onTrack,
          varianceSeconds: 0,
          estimatedCompletionTime: completionTime,
        );

        expect(status.completionTimeString, '12:00 PM');
      });

      test('formats completion time correctly for midnight', () {
        final completionTime = DateTime(2025, 1, 1, 0, 0);
        final status = ScheduleStatus(
          status: ScheduleStatusType.onTrack,
          varianceSeconds: 0,
          estimatedCompletionTime: completionTime,
        );

        expect(status.completionTimeString, '12:00 AM');
      });

      test('returns placeholder when completion time is null', () {
        const status = ScheduleStatus(
          status: ScheduleStatusType.onTrack,
          varianceSeconds: 0,
          estimatedCompletionTime: null,
        );

        expect(status.completionTimeString, '--:--');
      });
    });
  });
}
