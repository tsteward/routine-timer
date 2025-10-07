import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/src/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth);
    });

    test('currentUser returns null when not signed in', () {
      expect(authService.currentUser, isNull);
      expect(authService.isSignedIn, isFalse);
      expect(authService.currentUserId, isNull);
    });

    test('signInAnonymously creates anonymous user', () async {
      final error = await authService.signInAnonymously();

      expect(error, isNull);
      expect(authService.isSignedIn, isTrue);
      expect(authService.isAnonymous, isTrue);
      expect(authService.currentUserId, isNotNull);
    });

    test('currentUserId returns user ID when signed in', () async {
      await authService.signInAnonymously();

      expect(authService.currentUserId, isNotNull);
      expect(authService.currentUserId, isA<String>());
    });

    test('signOut clears current user', () async {
      await authService.signInAnonymously();
      expect(authService.isSignedIn, isTrue);

      final error = await authService.signOut();

      expect(error, isNull);
      expect(authService.isSignedIn, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('auth state changes are emitted', () async {
      expect(
        authService.authStateChanges,
        emitsInOrder([
          isNull, // Initially not signed in
          isNotNull, // After sign in
        ]),
      );

      await Future.delayed(const Duration(milliseconds: 100));
      await authService.signInAnonymously();
    });

    test('isAnonymous returns true for anonymous user', () async {
      await authService.signInAnonymously();

      expect(authService.isAnonymous, isTrue);
    });

    test('isAnonymous returns false when not signed in', () {
      expect(authService.isAnonymous, isFalse);
    });

    test('deleteAccount removes user', () async {
      await authService.signInAnonymously();
      expect(authService.isSignedIn, isTrue);

      final error = await authService.deleteAccount();

      expect(error, isNull);
      expect(authService.isSignedIn, isFalse);
    });

    test('deleteAccount fails when not signed in', () async {
      final error = await authService.deleteAccount();

      expect(error, isNotNull);
      expect(error, contains('Not signed in'));
    });
  });
}
