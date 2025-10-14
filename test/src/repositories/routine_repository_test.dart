import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/models/routine_settings.dart';
import 'package:routine_timer/src/models/routine_state.dart';
import 'package:routine_timer/src/models/task.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';
import 'package:routine_timer/src/services/auth_service.dart';

void main() {
  group('RoutineRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late AuthService authService;
    late RoutineRepository repository;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(signedIn: true);
      authService = AuthService(auth: mockAuth);
      repository = RoutineRepository(
        firestore: fakeFirestore,
        authService: authService,
      );
    });

    test('saveRoutine stores data in Firestore', () async {
      final routine = RoutineStateModel(
        tasks: [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ],
        settings: RoutineSettingsModel(
          startTime: DateTime(2024, 1, 1, 8, 0).millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        ),
      );

      final result = await repository.saveRoutine(routine);

      expect(result, isTrue);
      final loaded = await repository.loadRoutine();
      expect(loaded, isNotNull);
      expect(loaded!.tasks.length, 1);
      expect(loaded.tasks[0].name, 'Test Task');
    });

    test('loadRoutine returns null when document does not exist', () async {
      final loaded = await repository.loadRoutine();
      expect(loaded, isNull);
    });

    test('loadRoutine returns null when user not signed in', () async {
      final unauthRepo = RoutineRepository(
        firestore: fakeFirestore,
        authService: AuthService(auth: MockFirebaseAuth(signedIn: false)),
      );

      final loaded = await unauthRepo.loadRoutine();
      expect(loaded, isNull);
    });

    test('saveRoutine fails when user not signed in', () async {
      final unauthRepo = RoutineRepository(
        firestore: fakeFirestore,
        authService: AuthService(auth: MockFirebaseAuth(signedIn: false)),
      );

      final routine = RoutineStateModel(
        tasks: [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ],
        settings: RoutineSettingsModel(
          startTime: DateTime(2024, 1, 1).millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        ),
      );

      final result = await unauthRepo.saveRoutine(routine);
      expect(result, isFalse);
    });

    test('deleteRoutine removes data from Firestore', () async {
      final routine = RoutineStateModel(
        tasks: [
          const TaskModel(
            id: '1',
            name: 'Test Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ],
        settings: RoutineSettingsModel(
          startTime: DateTime(2024, 1, 1, 8, 0).millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        ),
      );

      await repository.saveRoutine(routine);
      final result = await repository.deleteRoutine();

      expect(result, isTrue);
      final loaded = await repository.loadRoutine();
      expect(loaded, isNull);
    });

    test('different users have separate data', () async {
      // User 1
      final mockAuth1 = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user1'),
      );
      final authService1 = AuthService(auth: mockAuth1);
      final repo1 = RoutineRepository(
        firestore: fakeFirestore,
        authService: authService1,
      );

      // User 2
      final mockAuth2 = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'user2'),
      );
      final authService2 = AuthService(auth: mockAuth2);
      final repo2 = RoutineRepository(
        firestore: fakeFirestore,
        authService: authService2,
      );

      // Save data for user 1
      final routine1 = RoutineStateModel(
        tasks: [
          const TaskModel(
            id: '1',
            name: 'User 1 Task',
            estimatedDuration: 300,
            order: 0,
          ),
        ],
        settings: RoutineSettingsModel(
          startTime: DateTime(2024, 1, 1).millisecondsSinceEpoch,
          defaultBreakDuration: 120,
        ),
      );
      await repo1.saveRoutine(routine1);

      // Save data for user 2
      final routine2 = RoutineStateModel(
        tasks: [
          const TaskModel(
            id: '2',
            name: 'User 2 Task',
            estimatedDuration: 600,
            order: 0,
          ),
        ],
        settings: RoutineSettingsModel(
          startTime: DateTime(2024, 1, 2).millisecondsSinceEpoch,
          defaultBreakDuration: 180,
        ),
      );
      await repo2.saveRoutine(routine2);

      // Load data for each user and verify separation
      final loaded1 = await repo1.loadRoutine();
      final loaded2 = await repo2.loadRoutine();

      expect(loaded1!.tasks[0].name, 'User 1 Task');
      expect(loaded2!.tasks[0].name, 'User 2 Task');
      expect(loaded1.tasks[0].estimatedDuration, 300);
      expect(loaded2.tasks[0].estimatedDuration, 600);
    });

    group('Completion Data', () {
      test('saveCompletionData stores completion in Firestore', () async {
        final completion = RoutineCompletionModel(
          completedAt: DateTime.now().millisecondsSinceEpoch,
          totalTasksCompleted: 4,
          totalTimeSpent: 3000,
          totalEstimatedTime: 3600,
          routineName: 'Morning Routine',
          tasksDetails: const [
            TaskCompletionDetail(
              taskName: 'Task 1',
              estimatedDuration: 900,
              actualDuration: 750,
            ),
          ],
        );

        final result = await repository.saveCompletionData(completion);

        expect(result, isTrue);

        // Verify data was saved by loading it
        final history = await repository.loadCompletionHistory();
        expect(history.length, 1);
        expect(history[0].totalTasksCompleted, 4);
        expect(history[0].totalTimeSpent, 3000);
        expect(history[0].routineName, 'Morning Routine');
      });

      test('loadCompletionHistory returns empty list when no data', () async {
        final history = await repository.loadCompletionHistory();
        expect(history, isEmpty);
      });

      test(
        'loadCompletionHistory returns completions in descending order',
        () async {
          // Save multiple completions at different times
          final completion1 = RoutineCompletionModel(
            completedAt: DateTime(2024, 1, 1).millisecondsSinceEpoch,
            totalTasksCompleted: 4,
            totalTimeSpent: 3000,
            totalEstimatedTime: 3600,
            routineName: 'Morning Routine',
          );

          final completion2 = RoutineCompletionModel(
            completedAt: DateTime(2024, 1, 2).millisecondsSinceEpoch,
            totalTasksCompleted: 4,
            totalTimeSpent: 3200,
            totalEstimatedTime: 3600,
            routineName: 'Morning Routine',
          );

          final completion3 = RoutineCompletionModel(
            completedAt: DateTime(2024, 1, 3).millisecondsSinceEpoch,
            totalTasksCompleted: 4,
            totalTimeSpent: 2800,
            totalEstimatedTime: 3600,
            routineName: 'Morning Routine',
          );

          await repository.saveCompletionData(completion1);
          await repository.saveCompletionData(completion2);
          await repository.saveCompletionData(completion3);

          final history = await repository.loadCompletionHistory();

          expect(history.length, 3);
          // Most recent first
          expect(
            history[0].completedAt,
            DateTime(2024, 1, 3).millisecondsSinceEpoch,
          );
          expect(
            history[1].completedAt,
            DateTime(2024, 1, 2).millisecondsSinceEpoch,
          );
          expect(
            history[2].completedAt,
            DateTime(2024, 1, 1).millisecondsSinceEpoch,
          );
        },
      );

      test('loadCompletionHistory respects limit parameter', () async {
        // Save 5 completions
        for (int i = 0; i < 5; i++) {
          final completion = RoutineCompletionModel(
            completedAt: DateTime(2024, 1, i + 1).millisecondsSinceEpoch,
            totalTasksCompleted: 4,
            totalTimeSpent: 3000,
            totalEstimatedTime: 3600,
            routineName: 'Morning Routine',
          );
          await repository.saveCompletionData(completion);
        }

        final history = await repository.loadCompletionHistory(limit: 3);

        expect(history.length, 3);
      });

      test(
        'saveCompletionData returns false when user not signed in',
        () async {
          final unauthRepo = RoutineRepository(
            firestore: fakeFirestore,
            authService: AuthService(auth: MockFirebaseAuth(signedIn: false)),
          );

          final completion = RoutineCompletionModel(
            completedAt: DateTime.now().millisecondsSinceEpoch,
            totalTasksCompleted: 4,
            totalTimeSpent: 3000,
            totalEstimatedTime: 3600,
            routineName: 'Morning Routine',
          );

          final result = await unauthRepo.saveCompletionData(completion);

          expect(result, isFalse);
        },
      );

      test('completion data is isolated per user', () async {
        // Create two users
        final mockAuth1 = MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'user1'),
        );
        final mockAuth2 = MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'user2'),
        );

        final repo1 = RoutineRepository(
          firestore: fakeFirestore,
          authService: AuthService(auth: mockAuth1),
        );

        final repo2 = RoutineRepository(
          firestore: fakeFirestore,
          authService: AuthService(auth: mockAuth2),
        );

        // Save completion for user 1
        final completion1 = RoutineCompletionModel(
          completedAt: DateTime.now().millisecondsSinceEpoch,
          totalTasksCompleted: 4,
          totalTimeSpent: 3000,
          totalEstimatedTime: 3600,
          routineName: 'User 1 Routine',
        );
        await repo1.saveCompletionData(completion1);

        // Save completion for user 2
        final completion2 = RoutineCompletionModel(
          completedAt: DateTime.now().millisecondsSinceEpoch,
          totalTasksCompleted: 3,
          totalTimeSpent: 2500,
          totalEstimatedTime: 3000,
          routineName: 'User 2 Routine',
        );
        await repo2.saveCompletionData(completion2);

        // Verify each user sees only their own data
        final history1 = await repo1.loadCompletionHistory();
        final history2 = await repo2.loadCompletionHistory();

        expect(history1.length, 1);
        expect(history2.length, 1);
        expect(history1[0].routineName, 'User 1 Routine');
        expect(history2[0].routineName, 'User 2 Routine');
        expect(history1[0].totalTasksCompleted, 4);
        expect(history2[0].totalTasksCompleted, 3);
      });
    });
  });
}
