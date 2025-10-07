import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/auth_service.dart';
import 'auth_events.dart';
import 'auth_state_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(const AuthBlocState()) {
    on<AuthStateChanged>(_onAuthStateChanged);
    on<SignInWithGoogle>(_onSignInWithGoogle);
    on<SignInAnonymously>(_onSignInAnonymously);
    on<SignOut>(_onSignOut);
    on<LinkAnonymousToGoogle>(_onLinkAnonymousToGoogle);
    on<DeleteAccount>(_onDeleteAccount);

    // Listen to Firebase auth state changes
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      add(AuthStateChanged(user?.uid));
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthBlocState> emit,
  ) {
    if (event.userId != null) {
      emit(
        AuthBlocState(
          status: AuthStatus.authenticated,
          userId: event.userId,
          isAnonymous: _authService.isAnonymous,
        ),
      );
    } else {
      emit(const AuthBlocState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogle event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final error = await _authService.signInWithGoogle();

    if (error != null) {
      emit(
        state.copyWith(status: AuthStatus.unauthenticated, errorMessage: error),
      );
    }
    // Auth state change will be handled by _onAuthStateChanged
  }

  Future<void> _onSignInAnonymously(
    SignInAnonymously event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final error = await _authService.signInAnonymously();

    if (error != null) {
      emit(
        state.copyWith(status: AuthStatus.unauthenticated, errorMessage: error),
      );
    }
    // Auth state change will be handled by _onAuthStateChanged
  }

  Future<void> _onSignOut(SignOut event, Emitter<AuthBlocState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final error = await _authService.signOut();

    if (error != null) {
      emit(state.copyWith(errorMessage: error));
    }
    // Auth state change will be handled by _onAuthStateChanged
  }

  Future<void> _onLinkAnonymousToGoogle(
    LinkAnonymousToGoogle event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    final error = await _authService.linkAnonymousToGoogle();

    if (error != null) {
      emit(
        state.copyWith(status: AuthStatus.authenticated, errorMessage: error),
      );
    }
    // Auth state change will be handled by _onAuthStateChanged
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final error = await _authService.deleteAccount();

    if (error != null) {
      emit(state.copyWith(errorMessage: error));
    }
    // Auth state change will be handled by _onAuthStateChanged
  }
}
