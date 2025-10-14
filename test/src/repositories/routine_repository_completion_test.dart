import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';
import 'package:routine_timer/src/services/auth_service.dart';

void main() {
  group('RoutineRepository - Completion Methods', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late AuthService authService;
    late RoutineRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(signedIn: true);
      authService = AuthService(auth: mockAuth);
      repository = RoutineRepository(
        firestore: fakeFirestore,
        authService: authService,
      );
    });

    test('saveCompletion should save completion to Firestore', () async {
      // Arrange
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: const [
          TaskCompletionDetail(
            taskId: 'task1',
            taskName: 'Morning Workout',
            estimatedDuration: 1200,
            actualDuration: 1000,
          ),
        ],
      );

      // Act
      final result = await repository.saveCompletion(completion);

      // Assert
      expect(result, isTrue);

      // Verify data was saved to Firestore
      final userId = mockAuth.currentUser!.uid;
      final doc = await fakeFirestore
          .collection('routines')
          .doc(userId)
          .collection('completions')
          .doc(completion.completedAt.toString())
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()?['totalTimeSpent'], 3600);
      expect(doc.data()?['tasksCompleted'], 4);
    });

    test(
      'saveCompletion should return false when user is not signed in',
      () async {
        // Arrange
        final mockAuthSignedOut = MockFirebaseAuth(signedIn: false);
        final authServiceSignedOut = AuthService(auth: mockAuthSignedOut);
        final repositorySignedOut = RoutineRepository(
          firestore: fakeFirestore,
          authService: authServiceSignedOut,
        );

        final completion = RoutineCompletion(
          completedAt: DateTime.now().millisecondsSinceEpoch,
          totalTimeSpent: 3600,
          tasksCompleted: 4,
          totalEstimatedTime: 3000,
          taskDetails: const [],
        );

        // Act
        final result = await repositorySignedOut.saveCompletion(completion);

        // Assert
        expect(result, isFalse);
      },
    );

    test(
      'loadRecentCompletions should load completions from Firestore',
      () async {
        // Arrange: Save multiple completions
        final userId = mockAuth.currentUser!.uid;
        final completionsCollection = fakeFirestore
            .collection('routines')
            .doc(userId)
            .collection('completions');

        final completion1 = RoutineCompletion(
          completedAt: 1000,
          totalTimeSpent: 3600,
          tasksCompleted: 4,
          totalEstimatedTime: 3000,
          taskDetails: const [],
        );

        final completion2 = RoutineCompletion(
          completedAt: 2000,
          totalTimeSpent: 3000,
          tasksCompleted: 3,
          totalEstimatedTime: 2800,
          taskDetails: const [],
        );

        final completion3 = RoutineCompletion(
          completedAt: 3000,
          totalTimeSpent: 4000,
          tasksCompleted: 5,
          totalEstimatedTime: 4200,
          taskDetails: const [],
        );

        await completionsCollection.doc('1000').set(completion1.toMap());
        await completionsCollection.doc('2000').set(completion2.toMap());
        await completionsCollection.doc('3000').set(completion3.toMap());

        // Act
        final results = await repository.loadRecentCompletions(limit: 10);

        // Assert
        expect(results.length, 3);
        // Should be ordered by most recent first
        expect(results[0].completedAt, 3000);
        expect(results[1].completedAt, 2000);
        expect(results[2].completedAt, 1000);
      },
    );

    test('loadRecentCompletions should respect limit parameter', () async {
      // Arrange: Save multiple completions
      final userId = mockAuth.currentUser!.uid;
      final completionsCollection = fakeFirestore
          .collection('routines')
          .doc(userId)
          .collection('completions');

      for (int i = 0; i < 15; i++) {
        final completion = RoutineCompletion(
          completedAt: 1000 + i,
          totalTimeSpent: 3600,
          tasksCompleted: 4,
          totalEstimatedTime: 3000,
          taskDetails: const [],
        );
        await completionsCollection
            .doc((1000 + i).toString())
            .set(completion.toMap());
      }

      // Act
      final results = await repository.loadRecentCompletions(limit: 5);

      // Assert
      expect(results.length, 5);
      // Should get the 5 most recent
      expect(results[0].completedAt, 1014);
      expect(results[4].completedAt, 1010);
    });

    test(
      'loadRecentCompletions should return empty list when user not signed in',
      () async {
        // Arrange
        final mockAuthSignedOut = MockFirebaseAuth(signedIn: false);
        final authServiceSignedOut = AuthService(auth: mockAuthSignedOut);
        final repositorySignedOut = RoutineRepository(
          firestore: fakeFirestore,
          authService: authServiceSignedOut,
        );

        // Act
        final results = await repositorySignedOut.loadRecentCompletions(
          limit: 10,
        );

        // Assert
        expect(results, isEmpty);
      },
    );

    test(
      'loadRecentCompletions should return empty list when no completions',
      () async {
        // Act
        final results = await repository.loadRecentCompletions(limit: 10);

        // Assert
        expect(results, isEmpty);
      },
    );

    test('watchRecentCompletions should stream completions updates', () async {
      // Arrange
      final userId = mockAuth.currentUser!.uid;
      final completionsCollection = fakeFirestore
          .collection('routines')
          .doc(userId)
          .collection('completions');

      // Act
      final stream = repository.watchRecentCompletions(limit: 10);

      // Add a completion
      final completion = RoutineCompletion(
        completedAt: 1000,
        totalTimeSpent: 3600,
        tasksCompleted: 4,
        totalEstimatedTime: 3000,
        taskDetails: const [],
      );

      await completionsCollection.doc('1000').set(completion.toMap());

      // Assert
      await expectLater(
        stream,
        emits(
          predicate<List<RoutineCompletion>>((list) {
            return list.length == 1 && list[0].completedAt == 1000;
          }),
        ),
      );
    });

    test(
      'watchRecentCompletions should return empty stream when not signed in',
      () async {
        // Arrange
        final mockAuthSignedOut = MockFirebaseAuth(signedIn: false);
        final authServiceSignedOut = AuthService(auth: mockAuthSignedOut);
        final repositorySignedOut = RoutineRepository(
          firestore: fakeFirestore,
          authService: authServiceSignedOut,
        );

        // Act
        final stream = repositorySignedOut.watchRecentCompletions(limit: 10);

        // Assert
        await expectLater(stream, emits(isEmpty));
      },
    );

    test('saveCompletion should handle task details correctly', () async {
      // Arrange
      final completion = RoutineCompletion(
        completedAt: DateTime.now().millisecondsSinceEpoch,
        totalTimeSpent: 1550,
        tasksCompleted: 2,
        totalEstimatedTime: 1800,
        taskDetails: const [
          TaskCompletionDetail(
            taskId: 'task1',
            taskName: 'Morning Workout',
            estimatedDuration: 1200,
            actualDuration: 1000,
          ),
          TaskCompletionDetail(
            taskId: 'task2',
            taskName: 'Shower',
            estimatedDuration: 600,
            actualDuration: 550,
          ),
        ],
      );

      // Act
      await repository.saveCompletion(completion);
      final results = await repository.loadRecentCompletions(limit: 1);

      // Assert
      expect(results.length, 1);
      final loaded = results[0];
      expect(loaded.taskDetails.length, 2);
      expect(loaded.taskDetails[0].taskName, 'Morning Workout');
      expect(loaded.taskDetails[0].actualDuration, 1000);
      expect(loaded.taskDetails[1].taskName, 'Shower');
      expect(loaded.taskDetails[1].actualDuration, 550);
    });
  });
}
