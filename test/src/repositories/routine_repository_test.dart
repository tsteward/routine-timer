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

    group('Completion Tracking', () {
      test('saveCompletion stores completion data in Firestore', () async {
        final completion = RoutineCompletion(
          completionId: 'test-completion-1',
          completedAt: DateTime(2025, 10, 14, 10, 30, 0),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 120,
          routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
        );

        final result = await repository.saveCompletion(completion);

        expect(result, isTrue);
      });

      test('loadCompletions retrieves saved completion data', () async {
        final completion1 = RoutineCompletion(
          completionId: 'completion-1',
          completedAt: DateTime(2025, 10, 14, 10, 30, 0),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 120,
          routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
        );

        final completion2 = RoutineCompletion(
          completionId: 'completion-2',
          completedAt: DateTime(2025, 10, 15, 10, 30, 0),
          totalTimeSpent: 3800,
          tasksCompleted: 6,
          scheduleVariance: -60,
          routineStartTime: DateTime(2025, 10, 15, 6, 0, 0),
        );

        await repository.saveCompletion(completion1);
        await repository.saveCompletion(completion2);

        final completions = await repository.loadCompletions();

        expect(completions.length, 2);
        // Should be sorted by date descending (newest first)
        expect(completions[0].completionId, 'completion-2');
        expect(completions[1].completionId, 'completion-1');
      });

      test(
        'loadCompletions returns empty list when no completions exist',
        () async {
          final completions = await repository.loadCompletions();

          expect(completions, isEmpty);
        },
      );

      test('loadCompletions respects limit parameter', () async {
        // Add 5 completions
        for (int i = 0; i < 5; i++) {
          final completion = RoutineCompletion(
            completionId: 'completion-$i',
            completedAt: DateTime(2025, 10, 14 + i, 10, 30, 0),
            totalTimeSpent: 3600 + i * 100,
            tasksCompleted: 5,
            scheduleVariance: 0,
            routineStartTime: DateTime(2025, 10, 14 + i, 6, 0, 0),
          );
          await repository.saveCompletion(completion);
        }

        final completions = await repository.loadCompletions(limit: 3);

        expect(completions.length, 3);
      });

      test('saveCompletion returns false when user is not signed in', () async {
        final unauthRepo = RoutineRepository(
          firestore: fakeFirestore,
          authService: AuthService(auth: MockFirebaseAuth(signedIn: false)),
        );

        final completion = RoutineCompletion(
          completedAt: DateTime.now(),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 0,
          routineStartTime: DateTime.now(),
        );

        final result = await unauthRepo.saveCompletion(completion);

        expect(result, isFalse);
      });

      test(
        'loadCompletions returns empty list when user is not signed in',
        () async {
          final unauthRepo = RoutineRepository(
            firestore: fakeFirestore,
            authService: AuthService(auth: MockFirebaseAuth(signedIn: false)),
          );

          final completions = await unauthRepo.loadCompletions();

          expect(completions, isEmpty);
        },
      );

      test('completions are user-specific', () async {
        // Create two repositories for different users
        final mockAuth1 = MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'user-1'),
        );
        final mockAuth2 = MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'user-2'),
        );

        final repo1 = RoutineRepository(
          firestore: fakeFirestore,
          authService: AuthService(auth: mockAuth1),
        );
        final repo2 = RoutineRepository(
          firestore: fakeFirestore,
          authService: AuthService(auth: mockAuth2),
        );

        // Save completions for each user
        final completion1 = RoutineCompletion(
          completionId: 'user1-completion',
          completedAt: DateTime.now(),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 120,
          routineStartTime: DateTime.now(),
        );

        final completion2 = RoutineCompletion(
          completionId: 'user2-completion',
          completedAt: DateTime.now(),
          totalTimeSpent: 4200,
          tasksCompleted: 7,
          scheduleVariance: -60,
          routineStartTime: DateTime.now(),
        );

        await repo1.saveCompletion(completion1);
        await repo2.saveCompletion(completion2);

        // Load completions for each user and verify separation
        final loaded1 = await repo1.loadCompletions();
        final loaded2 = await repo2.loadCompletions();

        expect(loaded1.length, 1);
        expect(loaded2.length, 1);
        expect(loaded1[0].completionId, 'user1-completion');
        expect(loaded2[0].completionId, 'user2-completion');
      });

      test('saveCompletion generates completionId if not provided', () async {
        final completion = RoutineCompletion(
          completedAt: DateTime.now(),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleVariance: 0,
          routineStartTime: DateTime.now(),
          // No completionId provided
        );

        final result = await repository.saveCompletion(completion);

        expect(result, isTrue);

        final completions = await repository.loadCompletions();
        expect(completions.length, 1);
        expect(completions[0].completionId, isNotNull);
      });

      test('completion data round-trips correctly', () async {
        final original = RoutineCompletion(
          completionId: 'test-round-trip',
          completedAt: DateTime(2025, 10, 14, 10, 30, 45),
          totalTimeSpent: 3661,
          tasksCompleted: 8,
          scheduleVariance: -125,
          routineStartTime: DateTime(2025, 10, 14, 6, 0, 0),
        );

        await repository.saveCompletion(original);
        final completions = await repository.loadCompletions();

        expect(completions.length, 1);
        final loaded = completions[0];

        expect(loaded.completionId, original.completionId);
        expect(loaded.completedAt, original.completedAt);
        expect(loaded.totalTimeSpent, original.totalTimeSpent);
        expect(loaded.tasksCompleted, original.tasksCompleted);
        expect(loaded.scheduleVariance, original.scheduleVariance);
        expect(loaded.routineStartTime, original.routineStartTime);
      });
    });
  });
}
