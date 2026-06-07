import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_sign_up_result.dart';
import '../repositories/auth_repository.dart';

class SignUp implements UseCase<AuthSignUpResult, SignUpParams> {
  const SignUp(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSignUpResult>> call(SignUpParams params) {
    return _repository.signUp(email: params.email, password: params.password);
  }
}

class SignUpParams extends Equatable {
  const SignUpParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
