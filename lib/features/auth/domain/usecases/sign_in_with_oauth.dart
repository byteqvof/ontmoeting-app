import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_oauth_provider.dart';
import '../repositories/auth_repository.dart';

class SignInWithOAuth implements UseCase<void, SignInWithOAuthParams> {
  const SignInWithOAuth(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(SignInWithOAuthParams params) {
    return _repository.signInWithOAuth(params.provider);
  }
}

class SignInWithOAuthParams extends Equatable {
  const SignInWithOAuthParams(this.provider);

  final AuthOAuthProvider provider;

  @override
  List<Object?> get props => [provider];
}
