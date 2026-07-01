import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_activity.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/get_profile_activities.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(
    this._getProfile,
    this._getProfileActivities, {
    String Function()? cacheKeyProvider,
  }) : _cacheKeyProvider = cacheKeyProvider,
       super(const ProfileInitial()) {
    on<ProfileStarted>(_onStarted);
  }

  final GetProfile _getProfile;
  final GetProfileActivities _getProfileActivities;
  final String Function()? _cacheKeyProvider;

  static final Map<String, ProfileLoaded> _loadedCache = {};
  static const String _ownProfileCacheKey = '__own_profile__';

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    final cacheKey = _cacheKey(event.profileId);
    final cached = _loadedCache[cacheKey];
    if (cached != null) {
      emit(cached);
    } else {
      emit(const ProfileLoading());
    }

    final result = await _getProfile(
      GetProfileParams(profileId: event.profileId),
    );
    await result.fold(
      (failure) async {
        if (cached == null) {
          emit(ProfileError(failure.message));
        }
      },
      (profile) async {
        final activitiesResult = await _getProfileActivities(
          GetProfileActivitiesParams(profileId: event.profileId),
        );
        activitiesResult.fold(
          (failure) {
            final loaded = ProfileLoaded(
              profile: profile,
              activities: cached?.activities ?? const [],
              activitiesErrorMessage: failure.message,
            );
            _loadedCache[cacheKey] = loaded;
            emit(loaded);
          },
          (activities) {
            final loaded = ProfileLoaded(
              profile: profile,
              activities: activities,
            );
            _loadedCache[cacheKey] = loaded;
            emit(loaded);
          },
        );
      },
    );
  }

  String _cacheKey(String? profileId) {
    final requestedProfileId = profileId?.trim();
    if (requestedProfileId != null && requestedProfileId.isNotEmpty) {
      return requestedProfileId;
    }
    return _cacheKeyProvider?.call() ?? _ownProfileCacheKey;
  }
}
