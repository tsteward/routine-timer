import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:routine_timer/src/services/auth_service.dart';
import 'package:routine_timer/src/repositories/routine_repository.dart';
import 'package:routine_timer/src/bloc/routine_bloc.dart';
import 'package:routine_timer/src/bloc/auth_bloc.dart';

/// Test helper for Firebase services with proper mocking
class FirebaseTestHelper {
  static MockFirebaseAuth? _mockAuth;
  static FakeFirebaseFirestore? _mockFirestore;
  static AuthService? _authService;
  static RoutineRepository? _routineRepository;
  static RoutineBloc? _routineBloc;
  static AuthBloc? _authBloc;

  /// Get or create mock Firebase Auth instance
  static MockFirebaseAuth get mockAuth {
    _mockAuth ??= MockFirebaseAuth();
    return _mockAuth!;
  }

  /// Get or create mock Firestore instance
  static FakeFirebaseFirestore get mockFirestore {
    _mockFirestore ??= FakeFirebaseFirestore();
    return _mockFirestore!;
  }

  /// Get or create AuthService with mocked dependencies
  static AuthService get authService {
    _authService ??= AuthService(auth: mockAuth);
    return _authService!;
  }

  /// Get or create RoutineRepository with mocked dependencies
  static RoutineRepository get routineRepository {
    _routineRepository ??= RoutineRepository(
      firestore: mockFirestore,
      authService: authService,
    );
    return _routineRepository!;
  }

  /// Get or create RoutineBloc with mocked dependencies
  static RoutineBloc get routineBloc {
    _routineBloc ??= RoutineBloc(repository: routineRepository);
    return _routineBloc!;
  }

  /// Get or create AuthBloc with mocked dependencies
  static AuthBloc get authBloc {
    _authBloc ??= AuthBloc(authService: authService);
    return _authBloc!;
  }

  /// Reset all mock instances (useful for test cleanup)
  static void reset() {
    _mockAuth = null;
    _mockFirestore = null;
    _authService = null;
    _routineRepository = null;
    _routineBloc = null;
    _authBloc = null;
  }

  /// Set up a signed-in user for testing
  static void setupSignedInUser({
    String uid = 'test-user-123',
    String email = 'test@example.com',
    String displayName = 'Test User',
    bool isAnonymous = false,
  }) {
    final user = MockUser(
      uid: uid,
      email: email,
      displayName: displayName,
      isAnonymous: isAnonymous,
    );
    // Note: MockFirebaseAuth doesn't have signInWithCredential setter
    // We'll use the existing user if available or create a new mock auth
    _mockAuth = MockFirebaseAuth(signedIn: true, mockUser: user);
  }

  /// Set up an anonymous user for testing
  static void setupAnonymousUser() {
    setupSignedInUser(
      uid: 'anonymous-user-123',
      email: 'anonymous@example.com',
      displayName: 'Anonymous User',
      isAnonymous: true,
    );
  }
}
