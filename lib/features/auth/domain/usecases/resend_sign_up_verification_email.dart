import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResendSignUpVerificationEmail
    implements UseCase<void, ResendSignUpVerificationEmailParams> {
  const ResendSignUpVerificationEmail(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(
    ResendSignUpVerificationEmailParams params,
  ) {
    return _repository.resendSignUpVerificationEmail(params.email);
  }
}

class ResendSignUpVerificationEmailParams extends Equatable {
  const ResendSignUpVerificationEmailParams(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
