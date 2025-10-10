import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:routine_timer/src/models/routine_completion.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';
import '../test_helpers/firebase_test_helper.dart';

void main() {
  group('RoutineRepository Completion Tests', () {
    late RoutineRepository repository;
    late FakeFirebaseFirestore firestore;
    late RoutineCompletionModel testCompletion;

    setUp(() {
      FirebaseTestHelper.reset();
      firestore = FirebaseTestHelper.firestore;
      repository = FirebaseTestHelper.routineRepository;
      
      testCompletion = RoutineCompletionModel(
        completedAt: DateTime(2025, 1, 10, 8, 30),
        totalTimeSpent: 3600, // 1 hour
        tasksCompleted: 4,
        totalTasks: 4,
        finalAheadBehindStatus: -300, // 5 minutes behind
        tasks: [
          const CompletedTaskModel(
            id: '1',
            name: 'Morning Workout',
            estimatedDuration: 1200,
            actualDuration: 1500,
            isCompleted: true,
            order: 0,
          ),
          const CompletedTaskModel(
            id: '2',
            name: 'Shower',
            estimatedDuration: 600,
            actualDuration: 600,
            isCompleted: true,
            order: 1,
          ),
          const CompletedTaskModel(
            id: '3',
            name: 'Breakfast',
            estimatedDuration: 900,
            actualDuration: 800,
            isCompleted: true,
            order: 2,
          ),
          const CompletedTaskModel(
            id: '4',
            name: 'Review Plan',
            estimatedDuration: 300,
            actualDuration: 360,
            isCompleted: true,
            order: 3,
          ),
        ],
        routineStartTime: DateTime(2025, 1, 10, 7, 30),
      );
    });

    group('saveCompletion', () {
      test('saves completion data successfully when user is authenticated', () async {
        // Sign in user first
        await FirebaseTestHelper.signInTestUser();
        
        final result = await repository.saveCompletion(testCompletion);
        
        expect(result, isTrue);
        
        // Verify data was saved in Firestore
        final userId = FirebaseTestHelper.testUserId;
        final doc = await firestore
            .collection('completions')
            .doc(userId)
            .collection('sessions')
            .doc(testCompletion.completedAt.millisecondsSinceEpoch.toString())
            .get();
            
        expect(doc.exists, isTrue);
        
        final savedCompletion = RoutineCompletionModel.fromMap(doc.data()!);
        expect(savedCompletion.completedAt, equals(testCompletion.completedAt));
        expect(savedCompletion.totalTimeSpent, equals(testCompletion.totalTimeSpent));
        expect(savedCompletion.tasksCompleted, equals(testCompletion.tasksCompleted));
        expect(savedCompletion.totalTasks, equals(testCompletion.totalTasks));
        expect(savedCompletion.tasks.length, equals(testCompletion.tasks.length));
      });

      test('returns false when user is not authenticated', () async {
        // Don't sign in user
        final result = await repository.saveCompletion(testCompletion);
        expect(result, isFalse);
      });

      test('uses timestamp as document ID for chronological ordering', () async {
        await FirebaseTestHelper.signInTestUser();
        
        final completion1 = testCompletion;
        final completion2 = testCompletion.copyWith(
          completedAt: DateTime(2025, 1, 11, 8, 30), // Next day
        );
        
        await repository.saveCompletion(completion1);
        await repository.saveCompletion(completion2);
        
        // Verify both were saved with timestamp IDs
        final userId = FirebaseTestHelper.testUserId;
        final collection = firestore
            .collection('completions')
            .doc(userId)
            .collection('sessions');
            
        final doc1 = await collection
            .doc(completion1.completedAt.millisecondsSinceEpoch.toString())
            .get();
        final doc2 = await collection
            .doc(completion2.completedAt.millisecondsSinceEpoch.toString())
            .get();
            
        expect(doc1.exists, isTrue);
        expect(doc2.exists, isTrue);
      });
    });

    group('loadLatestCompletion', () {
      test('loads most recent completion data', () async {
        await FirebaseTestHelper.signInTestUser();
        
        // Save multiple completions
        final completion1 = testCompletion.copyWith(
          completedAt: DateTime(2025, 1, 10, 8, 30),
        );
        final completion2 = testCompletion.copyWith(
          completedAt: DateTime(2025, 1, 11, 8, 30), // More recent
        );
        final completion3 = testCompletion.copyWith(
          completedAt: DateTime(2025, 1, 9, 8, 30), // Older
        );
        
        await repository.saveCompletion(completion1);
        await repository.saveCompletion(completion2);
        await repository.saveCompletion(completion3);
        
        final latest = await repository.loadLatestCompletion();
        
        expect(latest, isNotNull);
        expect(latest!.completedAt, equals(completion2.completedAt));
      });

      test('returns null when no completions exist', () async {
        await FirebaseTestHelper.signInTestUser();
        
        final result = await repository.loadLatestCompletion();
        expect(result, isNull);
      });

      test('returns null when user is not authenticated', () async {
        // Don't sign in user
        final result = await repository.loadLatestCompletion();
        expect(result, isNull);
      });
    });

    group('loadCompletionHistory', () {
      test('loads completion history in chronological order (most recent first)', () async {
        await FirebaseTestHelper.signInTestUser();
        
        // Save multiple completions
        final completions = [
          testCompletion.copyWith(
            completedAt: DateTime(2025, 1, 8, 8, 30),
            tasksCompleted: 2,
          ),
          testCompletion.copyWith(
            completedAt: DateTime(2025, 1, 10, 8, 30),
            tasksCompleted: 4,
          ),
          testCompletion.copyWith(
            completedAt: DateTime(2025, 1, 9, 8, 30),
            tasksCompleted: 3,
          ),
        ];
        
        for (final completion in completions) {
          await repository.saveCompletion(completion);
        }
        
        final history = await repository.loadCompletionHistory();
        
        expect(history.length, equals(3));
        // Should be ordered by date (most recent first)
        expect(history[0].completedAt, equals(DateTime(2025, 1, 10, 8, 30)));
        expect(history[1].completedAt, equals(DateTime(2025, 1, 9, 8, 30)));
        expect(history[2].completedAt, equals(DateTime(2025, 1, 8, 8, 30)));
        
        // Check tasks completed values to ensure correct order
        expect(history[0].tasksCompleted, equals(4));
        expect(history[1].tasksCompleted, equals(3));
        expect(history[2].tasksCompleted, equals(2));
      });

      test('respects limit parameter', () async {
        await FirebaseTestHelper.signInTestUser();
        
        // Save 5 completions
        for (int i = 0; i < 5; i++) {
          final completion = testCompletion.copyWith(
            completedAt: DateTime(2025, 1, 10 + i, 8, 30),
            tasksCompleted: i + 1,
          );
          await repository.saveCompletion(completion);
        }
        
        final history = await repository.loadCompletionHistory(limit: 3);
        
        expect(history.length, equals(3));
        // Should get the 3 most recent
        expect(history[0].tasksCompleted, equals(5)); // Most recent
        expect(history[1].tasksCompleted, equals(4));
        expect(history[2].tasksCompleted, equals(3));
      });

      test('returns empty list when no completions exist', () async {
        await FirebaseTestHelper.signInTestUser();
        
        final history = await repository.loadCompletionHistory();
        expect(history, isEmpty);
      });

      test('returns empty list when user is not authenticated', () async {
        // Don't sign in user
        final history = await repository.loadCompletionHistory();
        expect(history, isEmpty);
      });
    });

    group('deleteAllCompletions', () {
      test('deletes all completion data for the user', () async {
        await FirebaseTestHelper.signInTestUser();
        
        // Save multiple completions
        for (int i = 0; i < 3; i++) {
          final completion = testCompletion.copyWith(
            completedAt: DateTime(2025, 1, 10 + i, 8, 30),
          );
          await repository.saveCompletion(completion);
        }
        
        // Verify completions exist
        final historyBefore = await repository.loadCompletionHistory();
        expect(historyBefore.length, equals(3));
        
        // Delete all completions
        final result = await repository.deleteAllCompletions();
        expect(result, isTrue);
        
        // Verify completions are deleted
        final historyAfter = await repository.loadCompletionHistory();
        expect(historyAfter, isEmpty);
      });

      test('returns false when user is not authenticated', () async {
        // Don't sign in user
        final result = await repository.deleteAllCompletions();
        expect(result, isFalse);
      });

      test('returns true when no completions exist', () async {
        await FirebaseTestHelper.signInTestUser();
        
        // No completions saved
        final result = await repository.deleteAllCompletions();
        expect(result, isTrue);
      });
    });

    group('error handling', () {
      test('handles Firestore errors gracefully in saveCompletion', () async {
        await FirebaseTestHelper.signInTestUser();
        
        // Create a malformed completion that might cause errors
        final invalidCompletion = RoutineCompletionModel(
          completedAt: DateTime(2025, 1, 10, 8, 30),
          totalTimeSpent: -1, // Invalid negative value
          tasksCompleted: -1, // Invalid negative value
          totalTasks: 0, // Invalid zero value
          finalAheadBehindStatus: 0,
          tasks: [], // Empty tasks but non-zero counts
        );
        
        // Even with invalid data, save should not throw
        final result = await repository.saveCompletion(invalidCompletion);
        
        // Should still succeed (Firestore is flexible with data)
        expect(result, isTrue);
      });

      test('handles concurrent saves correctly', () async {
        await FirebaseTestHelper.signInTestUser();
        
        // Create multiple completions with different timestamps
        final completions = List.generate(5, (index) => 
          testCompletion.copyWith(
            completedAt: DateTime(2025, 1, 10, 8, 30, index),
            tasksCompleted: index + 1,
          )
        );
        
        // Save all completions concurrently
        final futures = completions.map((c) => repository.saveCompletion(c));
        final results = await Future.wait(futures);
        
        // All saves should succeed
        expect(results.every((result) => result), isTrue);
        
        // All should be retrievable
        final history = await repository.loadCompletionHistory(limit: 10);
        expect(history.length, equals(5));
      });
    });
  });
}