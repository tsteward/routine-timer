import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';

class MockRoutineRepository extends Mock implements RoutineRepository {}

void main() {
  late MockRoutineRepository mockRepository;

  setUp(() {
    mockRepository = MockRoutineRepository();
    registerFallbackValue(
      RoutineStateModel(
        tasks: const [],
        settings: RoutineSettingsModel(
          startTime: 0,
          breaksEnabledByDefault: false,
          defaultBreakDuration: 120,
        ),
      ),
    );
    registerFallbackValue(
      RoutineCompletion(
        completedAt: DateTime.now(),
        totalTimeSpent: 0,
        tasksCompleted: 0,
        totalTasks: 0,
        scheduleVariance: 0,
        taskCompletions: const [],
      ),
    );
  });

  group('MarkTaskDone completion detection', () {
    final settings = RoutineSettingsModel(
      startTime: DateTime(2025, 1, 1, 6, 0).millisecondsSinceEpoch,
      breaksEnabledByDefault: false,
      defaultBreakDuration: 120,
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'emits routineCompleted when last task is marked done',
      build: () {
        when(
          () => mockRepository.saveRoutine(any()),
        ).thenAnswer((_) async => true);
        return RoutineBloc(repository: mockRepository);
      },
      seed: () => RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
            TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 600,
              isCompleted: false,
              order: 1,
            ),
          ],
          settings: settings,
          selectedTaskId: '2',
        ),
      ),
      act: (bloc) => bloc.add(const MarkTaskDone(actualDuration: 620)),
      expect: () => [
        predicate<RoutineBlocState>((state) {
          return state.routineCompleted == true &&
              state.model != null &&
              state.model!.isRoutineCompleted;
        }),
      ],
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'does not emit routineCompleted when not all tasks done',
      build: () {
        when(
          () => mockRepository.saveRoutine(any()),
        ).thenAnswer((_) async => true);
        return RoutineBloc(repository: mockRepository);
      },
      seed: () => RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: false,
              order: 0,
            ),
            TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 600,
              isCompleted: false,
              order: 1,
            ),
            TaskModel(
              id: '3',
              name: 'Task 3',
              estimatedDuration: 600,
              isCompleted: false,
              order: 2,
            ),
          ],
          settings: settings,
          selectedTaskId: '1',
        ),
      ),
      act: (bloc) => bloc.add(const MarkTaskDone(actualDuration: 580)),
      verify: (bloc) {
        final state = bloc.state;
        expect(state.routineCompleted, isFalse);
        expect(state.model!.completedTasksCount, 1);
      },
    );
  });

  group('ResetRoutine', () {
    final settings = RoutineSettingsModel(
      startTime: DateTime(2025, 1, 1, 6, 0).millisecondsSinceEpoch,
      breaksEnabledByDefault: false,
      defaultBreakDuration: 120,
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'resets all tasks to uncompleted state',
      build: () {
        when(
          () => mockRepository.saveRoutine(any()),
        ).thenAnswer((_) async => true);
        return RoutineBloc(repository: mockRepository);
      },
      seed: () => RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
            TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 620,
              order: 1,
            ),
          ],
          settings: settings,
          selectedTaskId: '2',
        ),
        routineCompleted: true,
      ),
      act: (bloc) => bloc.add(const ResetRoutine()),
      verify: (bloc) {
        final state = bloc.state;
        expect(state.routineCompleted, isFalse);
        expect(state.model!.tasks.every((t) => !t.isCompleted), isTrue);
        expect(
          state.model!.tasks.every((t) => t.actualDuration == null),
          isTrue,
        );
        expect(state.model!.selectedTaskId, '1'); // Back to first task
      },
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'saves reset state to Firebase',
      build: () {
        when(
          () => mockRepository.saveRoutine(any()),
        ).thenAnswer((_) async => true);
        return RoutineBloc(repository: mockRepository);
      },
      seed: () => RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
          ],
          settings: settings,
          selectedTaskId: '1',
        ),
      ),
      act: (bloc) => bloc.add(const ResetRoutine()),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        verify(
          () => mockRepository.saveRoutine(any()),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'resets break state',
      build: () {
        when(
          () => mockRepository.saveRoutine(any()),
        ).thenAnswer((_) async => true);
        return RoutineBloc(repository: mockRepository);
      },
      seed: () => RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
          ],
          settings: settings,
          selectedTaskId: '1',
          isOnBreak: true,
          currentBreakIndex: 0,
        ),
      ),
      act: (bloc) => bloc.add(const ResetRoutine()),
      verify: (bloc) {
        final state = bloc.state;
        expect(state.model!.isOnBreak, isFalse);
        expect(state.model!.currentBreakIndex, isNull);
      },
    );
  });

  group('SaveRoutineCompletion', () {
    final settings = RoutineSettingsModel(
      startTime: DateTime(2025, 1, 1, 6, 0).millisecondsSinceEpoch,
      breaksEnabledByDefault: false,
      defaultBreakDuration: 120,
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'saves completion data to repository',
      build: () {
        when(
          () => mockRepository.saveCompletion(any()),
        ).thenAnswer((_) async => true);
        return RoutineBloc(repository: mockRepository);
      },
      seed: () => RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 580,
              order: 0,
            ),
            TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 620,
              order: 1,
            ),
          ],
          settings: settings,
          selectedTaskId: '2',
        ),
      ),
      act: (bloc) => bloc.add(
        SaveRoutineCompletion(routineStartTime: DateTime(2025, 1, 1, 6, 0)),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final captured =
            verify(
                  () => mockRepository.saveCompletion(captureAny()),
                ).captured.single
                as RoutineCompletion;

        expect(captured.tasksCompleted, 2);
        expect(captured.totalTasks, 2);
        expect(captured.totalTimeSpent, 1200); // 580 + 620
        expect(captured.scheduleVariance, 0); // 1200 - 1200
        expect(captured.taskCompletions.length, 2);
      },
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'calculates schedule variance correctly when ahead',
      build: () {
        when(
          () => mockRepository.saveCompletion(any()),
        ).thenAnswer((_) async => true);
        return RoutineBloc(repository: mockRepository);
      },
      seed: () => RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 550,
              order: 0,
            ),
            TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 570,
              order: 1,
            ),
          ],
          settings: settings,
          selectedTaskId: '2',
        ),
      ),
      act: (bloc) => bloc.add(
        SaveRoutineCompletion(routineStartTime: DateTime(2025, 1, 1, 6, 0)),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final captured =
            verify(
                  () => mockRepository.saveCompletion(captureAny()),
                ).captured.single
                as RoutineCompletion;

        // Total spent: 550 + 570 = 1120
        // Total estimated: 600 + 600 = 1200
        // Variance: 1120 - 1200 = -80 (ahead by 80 seconds)
        expect(captured.scheduleVariance, -80);
      },
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'calculates schedule variance correctly when behind',
      build: () {
        when(
          () => mockRepository.saveCompletion(any()),
        ).thenAnswer((_) async => true);
        return RoutineBloc(repository: mockRepository);
      },
      seed: () => RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: '1',
              name: 'Task 1',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 650,
              order: 0,
            ),
            TaskModel(
              id: '2',
              name: 'Task 2',
              estimatedDuration: 600,
              isCompleted: true,
              actualDuration: 630,
              order: 1,
            ),
          ],
          settings: settings,
          selectedTaskId: '2',
        ),
      ),
      act: (bloc) => bloc.add(
        SaveRoutineCompletion(routineStartTime: DateTime(2025, 1, 1, 6, 0)),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final captured =
            verify(
                  () => mockRepository.saveCompletion(captureAny()),
                ).captured.single
                as RoutineCompletion;

        // Total spent: 650 + 630 = 1280
        // Total estimated: 600 + 600 = 1200
        // Variance: 1280 - 1200 = 80 (behind by 80 seconds)
        expect(captured.scheduleVariance, 80);
      },
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'includes task completion details',
      build: () {
        when(
          () => mockRepository.saveCompletion(any()),
        ).thenAnswer((_) async => true);
        return RoutineBloc(repository: mockRepository);
      },
      seed: () => RoutineBlocState(
        loading: false,
        model: RoutineStateModel(
          tasks: const [
            TaskModel(
              id: 'task1',
              name: 'Morning Workout',
              estimatedDuration: 1200,
              isCompleted: true,
              actualDuration: 1150,
              order: 0,
            ),
          ],
          settings: settings,
          selectedTaskId: 'task1',
        ),
      ),
      act: (bloc) => bloc.add(
        SaveRoutineCompletion(routineStartTime: DateTime(2025, 1, 1, 6, 0)),
      ),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final captured =
            verify(
                  () => mockRepository.saveCompletion(captureAny()),
                ).captured.single
                as RoutineCompletion;

        expect(captured.taskCompletions.length, 1);
        final taskCompletion = captured.taskCompletions.first;
        expect(taskCompletion.taskId, 'task1');
        expect(taskCompletion.taskName, 'Morning Workout');
        expect(taskCompletion.estimatedDuration, 1200);
        expect(taskCompletion.actualDuration, 1150);
      },
    );
  });
}
