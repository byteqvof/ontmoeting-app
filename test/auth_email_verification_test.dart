import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/errors/failures.dart';
import 'package:meetings_app/features/auth/domain/entities/auth_oauth_provider.dart';
import 'package:meetings_app/features/auth/domain/entities/auth_sign_up_result.dart';
import 'package:meetings_app/features/auth/domain/entities/auth_user.dart';
import 'package:meetings_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:meetings_app/features/auth/domain/usecases/auth_state_changes.dart';
import 'package:meetings_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:meetings_app/features/auth/domain/usecases/resend_sign_up_verification_email.dart';
import 'package:meetings_app/features/auth/domain/usecases/sign_in.dart';
import 'package:meetings_app/features/auth/domain/usecases/sign_in_with_oauth.dart';
import 'package:meetings_app/features/auth/domain/usecases/sign_out.dart';
import 'package:meetings_app/features/auth/domain/usecases/sign_up.dart';
import 'package:meetings_app/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  test('signup without session emits email verification pending', () async {
    final repository = _FakeAuthRepository(
      signUpResult: const AuthSignUpEmailVerificationRequired(
        'jasper@example.com',
      ),
    );
    final bloc = _authBloc(repository);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        const AuthLoading(),
        const AuthEmailVerificationPending('jasper@example.com'),
      ]),
    );

    bloc.add(
      const AuthSignUpRequested(
        email: 'jasper@example.com',
        password: 'secret123',
      ),
    );

    await expectation;
    await Future<void>.delayed(Duration.zero);
    await bloc.close();
  });

  test('resend verification email emits loading and success notice', () async {
    final repository = _FakeAuthRepository();
    final bloc = _authBloc(repository);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        const AuthEmailVerificationPending(
          'jasper@example.com',
          isResending: true,
        ),
        const AuthEmailVerificationPending(
          'jasper@example.com',
          noticeMessage: 'We hebben je een nieuwe verificatiemail gestuurd.',
        ),
      ]),
    );

    bloc.add(const AuthVerificationEmailResendRequested('jasper@example.com'));

    await expectation;
    expect(repository.lastResentEmail, 'jasper@example.com');
    await bloc.close();
  });

  test('auth state callback still authenticates after email link', () async {
    const user = AuthUser(id: 'user-1', email: 'jasper@example.com');
    final repository = _FakeAuthRepository();
    final bloc = _authBloc(repository);

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        const AuthLoading(),
        const AuthUnauthenticated(),
        const AuthAuthenticated(user),
      ]),
    );

    bloc.add(const AuthStarted());
    await Future<void>.delayed(Duration.zero);
    repository.emitAuthUser(user);

    await expectation;
    await bloc.close();
  });
}

AuthBloc _authBloc(_FakeAuthRepository repository) {
  return AuthBloc(
    SignIn(repository),
    SignInWithOAuth(repository),
    SignUp(repository),
    ResendSignUpVerificationEmail(repository),
    SignOut(repository),
    GetCurrentUser(repository),
    AuthStateChanges(repository),
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.signUpResult = const AuthSignUpEmailVerificationRequired(
      'jasper@example.com',
    ),
  });

  final AuthSignUpResult signUpResult;
  final StreamController<Either<Failure, AuthUser?>> _authController =
      StreamController<Either<Failure, AuthUser?>>.broadcast();
  String? lastResentEmail;

  void emitAuthUser(AuthUser user) {
    _authController.add(right(user));
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    return right(null);
  }

  @override
  Stream<Either<Failure, AuthUser?>> authStateChanges() {
    return _authController.stream;
  }

  @override
  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    return right(AuthUser(id: 'user-1', email: email));
  }

  @override
  Future<Either<Failure, AuthSignUpResult>> signUp({
    required String email,
    required String password,
  }) async {
    return right(signUpResult);
  }

  @override
  Future<Either<Failure, void>> resendSignUpVerificationEmail(
    String email,
  ) async {
    lastResentEmail = email;
    return right(null);
  }

  @override
  Future<Either<Failure, void>> signInWithOAuth(
    AuthOAuthProvider provider,
  ) async {
    return right(null);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return right(null);
  }
}
