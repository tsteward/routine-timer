import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
