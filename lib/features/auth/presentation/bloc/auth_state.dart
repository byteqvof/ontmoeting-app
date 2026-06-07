part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthEmailVerificationPending extends AuthState {
  const AuthEmailVerificationPending(
    this.email, {
    this.isResending = false,
    this.noticeMessage,
    this.errorMessage,
  });

  final String email;
  final bool isResending;
  final String? noticeMessage;
  final String? errorMessage;

  AuthEmailVerificationPending copyWith({
    bool? isResending,
    String? noticeMessage,
    String? errorMessage,
    bool clearNoticeMessage = false,
    bool clearErrorMessage = false,
  }) {
    return AuthEmailVerificationPending(
      email,
      isResending: isResending ?? this.isResending,
      noticeMessage: clearNoticeMessage
          ? null
          : noticeMessage ?? this.noticeMessage,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [email, isResending, noticeMessage, errorMessage];
}

final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
