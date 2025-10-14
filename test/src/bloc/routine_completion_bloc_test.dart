import 'package:bloc_test/bloc_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/models/break.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';
import 'package:routine_timer/src/services/auth_service.dart';

void main() {
  group('RoutineBloc - Completion Logic', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RoutineRepository repository;
    late RoutineBloc bloc;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      final authService = AuthService();
      repository = RoutineRepository(
        firestore: fakeFirestore,
        authService: authService,
      );
      bloc = RoutineBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('should complete routine when last task is marked done', () async {
      // Arrange: Create a routine with tasks
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        defaultBreakDuration: 120,
      );

      final initialModel = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[0].id,
      );

      bloc.emit(RoutineBlocState(loading: false, model: initialModel));

      // Act: Mark first task done
      bloc.add(const MarkTaskDone(actualDuration: 550));
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify first task is completed and we moved to second task
      expect(bloc.state.model?.tasks[0].isCompleted, isTrue);
      expect(bloc.state.model?.currentTaskIndex, 1);

      // Mark second task done (last task)
      bloc.add(const MarkTaskDone(actualDuration: 280));
      await Future.delayed(const Duration(milliseconds: 200));

      // Assert: Routine should be completed
      expect(bloc.state.model?.isCompleted, isTrue);
      expect(bloc.state.model?.completion, isNotNull);
      expect(bloc.state.model?.completion?.tasksCompleted, 2);
      expect(bloc.state.model?.completion?.totalTimeSpent, 830); // 550 + 280
      expect(
        bloc.state.model?.completion?.totalEstimatedTime,
        900,
      ); // 600 + 300
      expect(bloc.state.model?.completion?.isAheadOfSchedule, isTrue);
    });

    blocTest<RoutineBloc, RoutineBlocState>(
      'CompleteRoutine should calculate completion statistics correctly',
      build: () => bloc,
      seed: () {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Morning Workout',
            estimatedDuration: 1200,
            actualDuration: 1000,
            isCompleted: true,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Shower',
            estimatedDuration: 600,
            actualDuration: 550,
            isCompleted: true,
            order: 1,
          ),
        ];

        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        );

        return RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            selectedTaskId: tasks[0].id,
          ),
        );
      },
      act: (bloc) => bloc.add(const CompleteRoutine()),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.model?.isCompleted, isTrue);
        expect(bloc.state.model?.completion, isNotNull);

        final completion = bloc.state.model?.completion;
        expect(completion?.tasksCompleted, 2);
        expect(completion?.totalTimeSpent, 1550); // 1000 + 550
        expect(completion?.totalEstimatedTime, 1800); // 1200 + 600
        expect(completion?.timeDifference, 250); // 250 seconds ahead
        expect(completion?.isAheadOfSchedule, isTrue);
        expect(completion?.taskDetails.length, 2);
        expect(completion?.taskDetails[0].taskName, 'Morning Workout');
      },
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'CompleteRoutine should handle behind schedule correctly',
      build: () => bloc,
      seed: () {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            actualDuration: 800,
            isCompleted: true,
            order: 0,
          ),
        ];

        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        );

        return RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            selectedTaskId: tasks[0].id,
          ),
        );
      },
      act: (bloc) => bloc.add(const CompleteRoutine()),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final completion = bloc.state.model?.completion;
        expect(completion?.timeDifference, -200); // 200 seconds behind
        expect(completion?.isAheadOfSchedule, isFalse);
      },
    );

    blocTest<RoutineBloc, RoutineBlocState>(
      'ResetRoutine should reset all tasks and completion state',
      build: () => bloc,
      seed: () {
        final tasks = [
          const TaskModel(
            id: '1',
            name: 'Task 1',
            estimatedDuration: 600,
            actualDuration: 550,
            isCompleted: true,
            order: 0,
          ),
          const TaskModel(
            id: '2',
            name: 'Task 2',
            estimatedDuration: 300,
            actualDuration: 280,
            isCompleted: true,
            order: 1,
          ),
        ];

        final settings = RoutineSettingsModel(
          startTime: DateTime.now().millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        );

        final breaks = [const BreakModel(duration: 120, isEnabled: true)];

        return RoutineBlocState(
          loading: false,
          model: RoutineStateModel(
            tasks: tasks,
            settings: settings,
            breaks: breaks,
            selectedTaskId: tasks[1].id,
            isCompleted: true,
            completion: RoutineCompletion(
              completedAt: 1234567890,
              totalTimeSpent: 830,
              tasksCompleted: 2,
              totalEstimatedTime: 900,
              taskDetails: [],
            ),
          ),
        );
      },
      act: (bloc) => bloc.add(const ResetRoutine()),
      verify: (bloc) {
        expect(bloc.state.model?.isCompleted, isFalse);
        expect(bloc.state.model?.completion, isNull);
        expect(bloc.state.model?.tasks[0].isCompleted, isFalse);
        expect(bloc.state.model?.tasks[1].isCompleted, isFalse);
        expect(bloc.state.model?.tasks[0].actualDuration, isNull);
        expect(bloc.state.model?.tasks[1].actualDuration, isNull);
        expect(bloc.state.model?.selectedTaskId, bloc.state.model?.tasks[0].id);
        expect(bloc.state.model?.isOnBreak, isFalse);
        expect(bloc.state.model?.currentBreakIndex, isNull);
      },
    );

    test('should not complete routine if not on last task', () async {
      // Arrange: Create a routine with multiple tasks
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
        const TaskModel(
          id: '2',
          name: 'Task 2',
          estimatedDuration: 300,
          order: 1,
        ),
        const TaskModel(
          id: '3',
          name: 'Task 3',
          estimatedDuration: 400,
          order: 2,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        defaultBreakDuration: 120,
      );

      final initialModel = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[0].id,
      );

      bloc.emit(RoutineBlocState(loading: false, model: initialModel));

      // Act: Mark first task done (not last task)
      bloc.add(const MarkTaskDone(actualDuration: 550));
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Routine should NOT be completed
      expect(bloc.state.model?.isCompleted, isFalse);
      expect(bloc.state.model?.completion, isNull);
      expect(bloc.state.model?.currentTaskIndex, 1); // Moved to next task
    });

    test('should handle completion with no completed tasks', () async {
      // Arrange: Create a routine with no completed tasks
      final tasks = [
        const TaskModel(
          id: '1',
          name: 'Task 1',
          estimatedDuration: 600,
          order: 0,
        ),
      ];

      final settings = RoutineSettingsModel(
        startTime: DateTime.now().millisecondsSinceEpoch,
        defaultBreakDuration: 120,
      );

      final initialModel = RoutineStateModel(
        tasks: tasks,
        settings: settings,
        selectedTaskId: tasks[0].id,
      );

      bloc.emit(RoutineBlocState(loading: false, model: initialModel));

      // Act: Try to complete routine without completing tasks
      bloc.add(const CompleteRoutine());
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Should create completion with zero stats
      expect(bloc.state.model?.isCompleted, isTrue);
      expect(bloc.state.model?.completion?.tasksCompleted, 0);
      expect(bloc.state.model?.completion?.totalTimeSpent, 0);
    });
  });
}
