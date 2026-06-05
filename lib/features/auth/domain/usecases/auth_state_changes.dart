import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class AuthStateChanges implements StreamUseCase<AuthUser?, NoParams> {
  const AuthStateChanges(this._repository);

  final AuthRepository _repository;

  @override
  Stream<Either<Failure, AuthUser?>> call(NoParams params) {
    return _repository.authStateChanges();
  }
}
