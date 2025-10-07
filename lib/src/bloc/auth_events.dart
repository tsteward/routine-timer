import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when Firebase auth state changes
class AuthStateChanged extends AuthEvent {
  const AuthStateChanged(this.userId);

  final String? userId;

  @override
  List<Object?> get props => [userId];
}

/// User initiates Google Sign-In
class SignInWithGoogle extends AuthEvent {
  const SignInWithGoogle();
}

/// User initiates Guest/Anonymous Sign-In
class SignInAnonymously extends AuthEvent {
  const SignInAnonymously();
}

/// User signs up with email and password
class SignUpWithEmailPassword extends AuthEvent {
  const SignUpWithEmailPassword({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// User signs in with email and password
class SignInWithEmailPassword extends AuthEvent {
  const SignInWithEmailPassword({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// User requests password reset email
class SendPasswordReset extends AuthEvent {
  const SendPasswordReset(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// User initiates sign-out
class SignOut extends AuthEvent {
  const SignOut();
}

/// Guest user upgrades to Google account
class LinkAnonymousToGoogle extends AuthEvent {
  const LinkAnonymousToGoogle();
}

/// User deletes their account
class DeleteAccount extends AuthEvent {
  const DeleteAccount();
}
