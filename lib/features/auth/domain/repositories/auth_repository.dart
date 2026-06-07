import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_oauth_provider.dart';
import '../entities/auth_sign_up_result.dart';
import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, AuthSignUpResult>> signUp({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signInWithOAuth(AuthOAuthProvider provider);

  Future<Either<Failure, void>> resendSignUpVerificationEmail(String email);

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, AuthUser?>> getCurrentUser();

  Stream<Either<Failure, AuthUser?>> authStateChanges();
}
