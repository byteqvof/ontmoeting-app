import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/account_trust_service.dart';
import '../../domain/entities/create_profile_draft.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_activity.dart';
import '../../domain/entities/profile_interest.dart';
import '../../domain/entities/profile_trust.dart';
import '../../domain/entities/update_profile_draft.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(
    this._dataSource, {
    AccountTrustService? accountTrustService,
    String? Function()? currentUserIdProvider,
  }) : _accountTrustService = accountTrustService,
       _currentUserIdProvider = currentUserIdProvider;

  final ProfileDataSource _dataSource;
  final AccountTrustService? _accountTrustService;
  final String? Function()? _currentUserIdProvider;

  @override
  Future<Either<Failure, Profile>> getProfile({String? profileId}) async {
    try {
      final profile = await _dataSource.getProfile(profileId: profileId);
      return right(_mergeLocalTrustForOwnProfile(profile, profileId));
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
    if (_looksLikeTransientNetworkError(error)) {
      return const NetworkFailure('De verbinding hapert. Probeer het opnieuw.');
    }
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

  Profile _mergeLocalTrustForOwnProfile(Profile profile, String? profileId) {
    final localTrust = _accountTrustService?.localFakeTrust;
    if (localTrust == null || !localTrust.phoneVerified) {
      return profile;
    }

    if (!_isOwnProfile(profile: profile, requestedProfileId: profileId)) {
      return profile;
    }

    final mergedTrust = ProfileTrust(
      phoneVerified: profile.trust.phoneVerified || localTrust.phoneVerified,
      phoneVerifiedAt:
          profile.trust.phoneVerifiedAt ?? localTrust.phoneVerifiedAt,
      identityStatus: profile.trust.identityStatus,
      identityMethod: profile.trust.identityMethod,
      identityCompletedAt: profile.trust.identityCompletedAt,
      ageVerified: profile.trust.ageVerified,
      reputationLevel: profile.trust.reputationLevel,
      reputationScore: profile.trust.reputationScore,
    );

    return Profile(
      id: profile.id,
      displayName: profile.displayName,
      initials: profile.initials,
      cityName: profile.cityName,
      ageBand: profile.ageBand,
      gender: profile.gender,
      memberSince: profile.memberSince,
      avatarUrl: profile.avatarUrl,
      attendanceScore: profile.attendanceScore,
      activitiesJoinedCount: profile.activitiesJoinedCount,
      activitiesHostedCount: profile.activitiesHostedCount,
      rating: profile.rating,
      isVerified: profile.isVerified,
      isPremium: profile.isPremium,
      trust: mergedTrust,
      interests: profile.interests,
    );
  }

  bool _isOwnProfile({
    required Profile profile,
    required String? requestedProfileId,
  }) {
    final currentUserId = _currentUserIdProvider?.call();
    if (requestedProfileId == null || requestedProfileId.isEmpty) {
      return true;
    }
    return requestedProfileId == currentUserId || profile.id == currentUserId;
  }
}

bool _looksLikeTransientNetworkError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('clientexception') ||
      message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('timed out') ||
      message.contains('timeout');
}
