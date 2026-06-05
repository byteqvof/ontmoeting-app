import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/create_profile_draft.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_activity.dart';
import '../../domain/entities/profile_interest.dart';
import '../../domain/entities/update_profile_draft.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._dataSource);

  final ProfileDataSource _dataSource;

  @override
  Future<Either<Failure, Profile>> getProfile({String? profileId}) async {
    try {
      return right(await _dataSource.getProfile(profileId: profileId));
    } catch (error) {
      return left(_mapProfileError(error));
    }
  }

  @override
  Future<Either<Failure, bool>> isProfileOnboardingRequired() async {
    try {
      return right(await _dataSource.isProfileOnboardingRequired());
    } catch (error) {
      return left(_mapProfileError(error));
    }
  }

  @override
  Future<Either<Failure, List<ProfileInterest>>> getAvailableInterests() async {
    try {
      return right(await _dataSource.getAvailableInterests());
    } catch (error) {
      return left(_mapProfileError(error));
    }
  }

  @override
  Future<Either<Failure, Profile>> createProfile(
    CreateProfileDraft draft,
  ) async {
    try {
      return right(await _dataSource.createProfile(draft));
    } catch (error) {
      return left(_mapProfileError(error));
    }
  }

  @override
  Future<Either<Failure, List<ProfileActivity>>> getActivitiesForUser({
    String? profileId,
  }) async {
    try {
      return right(
        await _dataSource.getActivitiesForUser(profileId: profileId),
      );
    } catch (error) {
      return left(_mapProfileError(error));
    }
  }

  @override
  Future<Either<Failure, Profile>> updateProfile(
    UpdateProfileDraft draft,
  ) async {
    try {
      return right(await _dataSource.updateProfile(draft));
    } catch (error) {
      return left(_mapProfileError(error));
    }
  }

  Failure _mapProfileError(Object error) {
    if (error is AuthException) {
      return AuthFailure(error.message);
    }
    if (error is FunctionException && error.status == 401) {
      return const AuthFailure(
        'Je sessie is verlopen. Log opnieuw in om door te gaan.',
      );
    }
    if (error is FunctionException && error.status >= 500) {
      return const ServerFailure(
        'De profielservice is tijdelijk niet beschikbaar.',
      );
    }
    return UnknownFailure(error.toString());
  }
}
