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

    group('Routine Completion', () {
      test('saveCompletion stores completion data in Firestore', () async {
        final completion = RoutineCompletion(
          completedAt: DateTime(2025, 10, 14, 9, 30),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleStatus: 'ahead',
          scheduleVarianceSeconds: -120,
        );

        final result = await repository.saveCompletion(completion);

        expect(result, isTrue);

        // Verify data was saved
        final history = await repository.loadCompletionHistory();
        expect(history.length, 1);
        expect(history[0].totalTimeSpent, 3600);
        expect(history[0].tasksCompleted, 5);
        expect(history[0].scheduleStatus, 'ahead');
        expect(history[0].scheduleVarianceSeconds, -120);
      });

      test('loadCompletionHistory returns empty list when no data', () async {
        final history = await repository.loadCompletionHistory();
        expect(history, isEmpty);
      });

      test('loadCompletionHistory returns multiple completions', () async {
        final completion1 = RoutineCompletion(
          completedAt: DateTime(2025, 10, 14, 9, 0),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleStatus: 'ahead',
          scheduleVarianceSeconds: -120,
        );

        final completion2 = RoutineCompletion(
          completedAt: DateTime(2025, 10, 15, 9, 0),
          totalTimeSpent: 3800,
          tasksCompleted: 5,
          scheduleStatus: 'behind',
          scheduleVarianceSeconds: 200,
        );

        final completion3 = RoutineCompletion(
          completedAt: DateTime(2025, 10, 16, 9, 0),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleStatus: 'on-track',
          scheduleVarianceSeconds: 0,
        );

        await repository.saveCompletion(completion1);
        await repository.saveCompletion(completion2);
        await repository.saveCompletion(completion3);

        final history = await repository.loadCompletionHistory();

        expect(history.length, 3);
        // Should be ordered by completedAt descending (most recent first)
        expect(history[0].completedAt.day, 16);
        expect(history[1].completedAt.day, 15);
        expect(history[2].completedAt.day, 14);
      });

      test('loadCompletionHistory respects limit parameter', () async {
        // Save 5 completions
        for (int i = 0; i < 5; i++) {
          final completion = RoutineCompletion(
            completedAt: DateTime(2025, 10, 14 + i, 9, 0),
            totalTimeSpent: 3600,
            tasksCompleted: 5,
            scheduleStatus: 'ahead',
            scheduleVarianceSeconds: -120,
          );
          await repository.saveCompletion(completion);
        }

        final history = await repository.loadCompletionHistory(limit: 3);

        expect(history.length, 3);
      });

      test('saveCompletion fails when user not signed in', () async {
        final unauthRepo = RoutineRepository(
          firestore: fakeFirestore,
          authService: AuthService(auth: MockFirebaseAuth(signedIn: false)),
        );

        final completion = RoutineCompletion(
          completedAt: DateTime(2025, 10, 14, 9, 30),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleStatus: 'ahead',
          scheduleVarianceSeconds: -120,
        );

        final result = await unauthRepo.saveCompletion(completion);
        expect(result, isFalse);
      });

      test(
        'loadCompletionHistory returns empty when user not signed in',
        () async {
          final unauthRepo = RoutineRepository(
            firestore: fakeFirestore,
            authService: AuthService(auth: MockFirebaseAuth(signedIn: false)),
          );

          final history = await unauthRepo.loadCompletionHistory();
          expect(history, isEmpty);
        },
      );

      test('different users have separate completion history', () async {
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

        // Save completion for user 1
        final completion1 = RoutineCompletion(
          completedAt: DateTime(2025, 10, 14, 9, 0),
          totalTimeSpent: 3600,
          tasksCompleted: 5,
          scheduleStatus: 'ahead',
          scheduleVarianceSeconds: -120,
        );
        await repo1.saveCompletion(completion1);

        // Save completion for user 2
        final completion2 = RoutineCompletion(
          completedAt: DateTime(2025, 10, 14, 10, 0),
          totalTimeSpent: 4000,
          tasksCompleted: 6,
          scheduleStatus: 'behind',
          scheduleVarianceSeconds: 200,
        );
        await repo2.saveCompletion(completion2);

        // Load history for each user and verify separation
        final history1 = await repo1.loadCompletionHistory();
        final history2 = await repo2.loadCompletionHistory();

        expect(history1.length, 1);
        expect(history2.length, 1);
        expect(history1[0].totalTimeSpent, 3600);
        expect(history2[0].totalTimeSpent, 4000);
        expect(history1[0].tasksCompleted, 5);
        expect(history2[0].tasksCompleted, 6);
      });
    });
  });
}
