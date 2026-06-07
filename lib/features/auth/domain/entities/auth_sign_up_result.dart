import 'package:equatable/equatable.dart';

import 'auth_user.dart';

sealed class AuthSignUpResult extends Equatable {
  const AuthSignUpResult();
}

final class AuthSignUpAuthenticated extends AuthSignUpResult {
  const AuthSignUpAuthenticated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

final class AuthSignUpEmailVerificationRequired extends AuthSignUpResult {
  const AuthSignUpEmailVerificationRequired(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
