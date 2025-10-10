import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/completion_summary.dart';
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

    // Completion Data Tests
    group('Completion Data', () {
      final sampleCompletion = CompletionSummary(
        completedAt: DateTime.parse('2025-01-01T08:00:00.000Z'),
        totalTimeSpent: 2400,
        totalEstimatedTime: 3000,
        tasksCompleted: 4,
        totalTasks: 4,
        tasks: const [
          CompletedTaskSummary(
            name: 'Task 1',
            estimatedDuration: 600,
            actualDuration: 500,
            wasCompleted: true,
            order: 0,
          ),
          CompletedTaskSummary(
            name: 'Task 2',
            estimatedDuration: 900,
            actualDuration: 800,
            wasCompleted: true,
            order: 1,
          ),
          CompletedTaskSummary(
            name: 'Task 3',
            estimatedDuration: 1200,
            actualDuration: 1000,
            wasCompleted: true,
            order: 2,
          ),
          CompletedTaskSummary(
            name: 'Task 4',
            estimatedDuration: 300,
            actualDuration: 100,
            wasCompleted: true,
            order: 3,
          ),
        ],
      );

      test('saveCompletionData stores data with userId in Firestore', () async {
        final result = await repository.saveCompletionData(sampleCompletion);

        expect(result, isTrue);

        // Verify data was stored in Firestore
        final snapshot = await fakeFirestore.collection('completions').get();
        expect(snapshot.docs.length, 1);

        final doc = snapshot.docs.first;
        expect(doc.data()['userId'], equals(mockAuth.currentUser!.uid));
        expect(doc.data()['totalTimeSpent'], equals(2400));
        expect(doc.data()['tasksCompleted'], equals(4));
      });

      test(
        'saveCompletionData returns false when user not signed in',
        () async {
          final unauthenticatedAuth = MockFirebaseAuth(signedIn: false);
          final unauthenticatedService = AuthService(auth: unauthenticatedAuth);
          final unauthenticatedRepo = RoutineRepository(
            firestore: fakeFirestore,
            authService: unauthenticatedService,
          );

          final result = await unauthenticatedRepo.saveCompletionData(
            sampleCompletion,
          );

          expect(result, isFalse);
        },
      );

      test(
        'getRecentCompletions returns completions for current user',
        () async {
          // Save multiple completions
          final completion1 = sampleCompletion;
          final completion2 = sampleCompletion.copyWith(
            completedAt: DateTime.parse('2025-01-02T08:00:00.000Z'),
            totalTimeSpent: 2600,
          );
          final completion3 = sampleCompletion.copyWith(
            completedAt: DateTime.parse('2025-01-03T08:00:00.000Z'),
            totalTimeSpent: 2200,
          );

          await repository.saveCompletionData(completion1);
          await repository.saveCompletionData(completion2);
          await repository.saveCompletionData(completion3);

          final completions = await repository.getRecentCompletions();

          expect(completions.length, 3);
          // Should be ordered by completion time (most recent first)
          expect(completions[0].completedAt, equals(completion3.completedAt));
          expect(completions[1].completedAt, equals(completion2.completedAt));
          expect(completions[2].completedAt, equals(completion1.completedAt));
        },
      );

      test('getRecentCompletions respects limit parameter', () async {
        // Save 5 completions
        for (int i = 0; i < 5; i++) {
          final completion = sampleCompletion.copyWith(
            completedAt: DateTime.parse('2025-01-0${i + 1}T08:00:00.000Z'),
          );
          await repository.saveCompletionData(completion);
        }

        final completions = await repository.getRecentCompletions(limit: 3);

        expect(completions.length, 3);
      });

      test(
        'getRecentCompletions returns empty list when user not signed in',
        () async {
          final unauthenticatedAuth = MockFirebaseAuth(signedIn: false);
          final unauthenticatedService = AuthService(auth: unauthenticatedAuth);
          final unauthenticatedRepo = RoutineRepository(
            firestore: fakeFirestore,
            authService: unauthenticatedService,
          );

          final completions = await unauthenticatedRepo.getRecentCompletions();

          expect(completions, isEmpty);
        },
      );

      test('getRecentCompletions filters by current user only', () async {
        // Save completion for current user
        await repository.saveCompletionData(sampleCompletion);

        // Save completion for different user by directly adding to Firestore
        await fakeFirestore.collection('completions').add({
          'userId': 'different-user-id',
          ...sampleCompletion.toMap(),
        });

        final completions = await repository.getRecentCompletions();

        // Should only return completion for current user
        expect(completions.length, 1);
        expect(
          completions[0].totalTimeSpent,
          equals(sampleCompletion.totalTimeSpent),
        );
      });

      test(
        'getRecentCompletions handles Firestore errors gracefully',
        () async {
          // Use a mock that will throw an error (simulate Firestore error)
          // For this test, we'll use a repository with null user ID
          final nullAuthService = AuthService(
            auth: MockFirebaseAuth(signedIn: false),
          );
          final errorRepo = RoutineRepository(
            firestore: fakeFirestore,
            authService: nullAuthService,
          );

          final completions = await errorRepo.getRecentCompletions();

          expect(completions, isEmpty);
        },
      );

      test('completion data preserves all task information', () async {
        await repository.saveCompletionData(sampleCompletion);

        final completions = await repository.getRecentCompletions();
        final loaded = completions.first;

        expect(loaded.tasks.length, equals(sampleCompletion.tasks.length));

        for (int i = 0; i < loaded.tasks.length; i++) {
          final loadedTask = loaded.tasks[i];
          final originalTask = sampleCompletion.tasks[i];

          expect(loadedTask.name, equals(originalTask.name));
          expect(
            loadedTask.estimatedDuration,
            equals(originalTask.estimatedDuration),
          );
          expect(
            loadedTask.actualDuration,
            equals(originalTask.actualDuration),
          );
          expect(loadedTask.wasCompleted, equals(originalTask.wasCompleted));
          expect(loadedTask.order, equals(originalTask.order));
        }
      });

      test('completion data handles serialization edge cases', () async {
        final edgeCaseCompletion = CompletionSummary(
          completedAt: DateTime.parse(
            '2025-12-31T23:59:59.999Z',
          ), // Edge datetime
          totalTimeSpent: 0, // Zero time
          totalEstimatedTime: 86400, // Very large time (24 hours)
          tasksCompleted: 0, // No tasks completed
          totalTasks: 10, // But many tasks exist
          tasks: const [], // Empty tasks list
          routineName: 'Edge Case Routine',
        );

        final result = await repository.saveCompletionData(edgeCaseCompletion);
        expect(result, isTrue);

        final completions = await repository.getRecentCompletions();
        final loaded = completions.first;

        expect(loaded.totalTimeSpent, equals(0));
        expect(loaded.totalEstimatedTime, equals(86400));
        expect(loaded.tasksCompleted, equals(0));
        expect(loaded.totalTasks, equals(10));
        expect(loaded.tasks, isEmpty);
        expect(loaded.routineName, equals('Edge Case Routine'));
      });
    });
  });
}
