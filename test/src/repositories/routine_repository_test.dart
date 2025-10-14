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
      test('saveCompletion stores completion data in Firestore', () async {
        final completion = RoutineCompletionData(
          completedAt: DateTime.now().millisecondsSinceEpoch,
          totalDurationSeconds: 3600,
          tasksCompleted: 4,
          totalEstimatedDuration: 3000,
          totalActualDuration: 2700,
          routineName: 'Morning Routine',
        );

        final result = await repository.saveCompletion(completion);

        expect(result, isTrue);
      });

      test('saveCompletion fails when user not signed in', () async {
        final unauthRepo = RoutineRepository(
          firestore: fakeFirestore,
          authService: AuthService(auth: MockFirebaseAuth(signedIn: false)),
        );

        final completion = RoutineCompletionData(
          completedAt: DateTime.now().millisecondsSinceEpoch,
          totalDurationSeconds: 3600,
          tasksCompleted: 4,
          totalEstimatedDuration: 3000,
          totalActualDuration: 2700,
          routineName: 'Morning Routine',
        );

        final result = await unauthRepo.saveCompletion(completion);
        expect(result, isFalse);
      });

      test('loadRecentCompletions returns empty list when no data', () async {
        final completions = await repository.loadRecentCompletions();
        expect(completions, isEmpty);
      });

      test(
        'loadRecentCompletions returns saved completions in order',
        () async {
          // Save multiple completions with different timestamps
          final completion1 = RoutineCompletionData(
            completedAt: 1000,
            totalDurationSeconds: 3600,
            tasksCompleted: 4,
            totalEstimatedDuration: 3000,
            totalActualDuration: 2700,
            routineName: 'Morning Routine',
          );

          final completion2 = RoutineCompletionData(
            completedAt: 2000,
            totalDurationSeconds: 3000,
            tasksCompleted: 3,
            totalEstimatedDuration: 2500,
            totalActualDuration: 2400,
            routineName: 'Evening Routine',
          );

          final completion3 = RoutineCompletionData(
            completedAt: 3000,
            totalDurationSeconds: 4000,
            tasksCompleted: 5,
            totalEstimatedDuration: 4500,
            totalActualDuration: 4200,
            routineName: 'Workout Routine',
          );

          await repository.saveCompletion(completion1);
          await repository.saveCompletion(completion2);
          await repository.saveCompletion(completion3);

          final completions = await repository.loadRecentCompletions();

          expect(completions.length, 3);
          // Should be in descending order (most recent first)
          expect(completions[0].completedAt, 3000);
          expect(completions[1].completedAt, 2000);
          expect(completions[2].completedAt, 1000);
        },
      );

      test('loadRecentCompletions respects limit parameter', () async {
        // Save 5 completions
        for (int i = 0; i < 5; i++) {
          final completion = RoutineCompletionData(
            completedAt: i * 1000,
            totalDurationSeconds: 3600,
            tasksCompleted: 4,
            totalEstimatedDuration: 3000,
            totalActualDuration: 2700,
            routineName: 'Routine $i',
          );
          await repository.saveCompletion(completion);
        }

        final completions = await repository.loadRecentCompletions(limit: 3);

        expect(completions.length, 3);
        // Should get the 3 most recent
        expect(completions[0].routineName, 'Routine 4');
        expect(completions[1].routineName, 'Routine 3');
        expect(completions[2].routineName, 'Routine 2');
      });

      test(
        'loadRecentCompletions returns empty list when user not signed in',
        () async {
          final unauthRepo = RoutineRepository(
            firestore: fakeFirestore,
            authService: AuthService(auth: MockFirebaseAuth(signedIn: false)),
          );

          final completions = await unauthRepo.loadRecentCompletions();
          expect(completions, isEmpty);
        },
      );

      test('different users have separate completion histories', () async {
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
        final completion1 = RoutineCompletionData(
          completedAt: 1000,
          totalDurationSeconds: 3600,
          tasksCompleted: 4,
          totalEstimatedDuration: 3000,
          totalActualDuration: 2700,
          routineName: 'User 1 Routine',
        );
        await repo1.saveCompletion(completion1);

        // Save completion for user 2
        final completion2 = RoutineCompletionData(
          completedAt: 2000,
          totalDurationSeconds: 3000,
          tasksCompleted: 3,
          totalEstimatedDuration: 2500,
          totalActualDuration: 2400,
          routineName: 'User 2 Routine',
        );
        await repo2.saveCompletion(completion2);

        // Load completions for each user and verify separation
        final completions1 = await repo1.loadRecentCompletions();
        final completions2 = await repo2.loadRecentCompletions();

        expect(completions1.length, 1);
        expect(completions2.length, 1);
        expect(completions1[0].routineName, 'User 1 Routine');
        expect(completions2[0].routineName, 'User 2 Routine');
      });
    });
  });
}
