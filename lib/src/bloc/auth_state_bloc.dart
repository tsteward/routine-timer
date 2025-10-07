import 'package:equatable/equatable.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthBlocState extends Equatable {
  const AuthBlocState({
    this.status = AuthStatus.initial,
    this.userId,
    this.isAnonymous = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? userId;
  final bool isAnonymous;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthBlocState copyWith({
    AuthStatus? status,
    String? userId,
    bool? isAnonymous,
    String? errorMessage,
  }) {
    return AuthBlocState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, userId, isAnonymous, errorMessage];
}
