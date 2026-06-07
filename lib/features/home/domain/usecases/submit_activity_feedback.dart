import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/activity_feedback.dart';
import '../repositories/home_repository.dart';

class SubmitActivityFeedback
    implements UseCase<ActivityFeedback, SubmitActivityFeedbackParams> {
  const SubmitActivityFeedback(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, ActivityFeedback>> call(
    SubmitActivityFeedbackParams params,
  ) {
    return _repository.submitActivityFeedback(
      activityId: params.activityId,
      targetProfileId: params.targetProfileId,
      rating: params.rating,
      comment: params.comment,
    );
  }
}

class SubmitActivityFeedbackParams extends Equatable {
  const SubmitActivityFeedbackParams({
    required this.activityId,
    required this.targetProfileId,
    required this.rating,
    required this.comment,
  });

  final String activityId;
  final String targetProfileId;
  final int rating;
  final String comment;

  @override
  List<Object?> get props => [activityId, targetProfileId, rating, comment];
}
