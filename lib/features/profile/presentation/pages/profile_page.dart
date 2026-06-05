import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../home/domain/entities/home_activity.dart';
import '../../../home/domain/entities/home_category.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_activity.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_activities_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_interests_card.dart';
import '../widgets/profile_menu_list.dart';
import '../widgets/profile_premium_card.dart';
import '../widgets/profile_score_card.dart';
import '../widgets/profile_stats_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({this.profileId, super.key});

  final String? profileId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ProfileBloc>()..add(ProfileStarted(profileId: profileId)),
      child: _ProfileView(isOwnProfile: profileId == null),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.isOwnProfile});

  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              return switch (state) {
                ProfileInitial() || ProfileLoading() => const _ProfileLoading(),
                ProfileError(:final message) => _ProfileError(message: message),
                ProfileLoaded(
                  :final profile,
                  :final activities,
                  :final activitiesErrorMessage,
                ) =>
                  _ProfileContent(
                    profile: profile,
                    activities: activities,
                    activitiesErrorMessage: activitiesErrorMessage,
                    isOwnProfile: isOwnProfile,
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.activities,
    required this.isOwnProfile,
    this.activitiesErrorMessage,
  });

  final Profile profile;
  final List<ProfileActivity> activities;
  final bool isOwnProfile;
  final String? activitiesErrorMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
        children: [
          _ProfileTopBar(profile: profile, isOwnProfile: isOwnProfile),
          const SizedBox(height: TochSpacing.md),
          ProfileHeader(profile: profile),
          const SizedBox(height: TochSpacing.md),
          ProfileScoreCard(profile: profile),
          const SizedBox(height: TochSpacing.md),
          ProfileStatsCard(profile: profile),
          const SizedBox(height: TochSpacing.md),
          ProfileActivitiesCard(
            activities: activities,
            isOwnProfile: isOwnProfile,
            errorMessage: activitiesErrorMessage,
            onActivityPressed: (activity) {
              context.push(
                AppRoutes.activityDetailPath(activity.id),
                extra: _homeActivityFromProfileActivity(
                  activity: activity,
                  profile: profile,
                  isOwnProfile: isOwnProfile,
                ),
              );
            },
          ),
          const SizedBox(height: TochSpacing.md),
          ProfileInterestsCard(interests: profile.interests),
          const SizedBox(height: TochSpacing.md),
          ProfilePremiumCard(isPremium: profile.isPremium),
          const SizedBox(height: TochSpacing.md),
          ProfileMenuList(
            isOwnProfile: isOwnProfile,
            onSignOutPressed: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmSignOut(BuildContext context) async {
  final shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Uitloggen?'),
        content: const Text('Je kunt later weer inloggen met je account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuleer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log uit'),
          ),
        ],
      );
    },
  );

  if (shouldSignOut == true && context.mounted) {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
  }
}

HomeActivity _homeActivityFromProfileActivity({
  required ProfileActivity activity,
  required Profile profile,
  required bool isOwnProfile,
}) {
  return HomeActivity(
    id: activity.id,
    category: HomeCategory(
      id: activity.category.id,
      label: activity.category.label,
      icon: _iconForKey(activity.category.iconKey),
      color: _colorFromHex(
        activity.category.foregroundColorHex,
        fallback: const Color(0xFF1E5740),
      ),
      backgroundColor: _colorFromHex(
        activity.category.backgroundColorHex,
        fallback: const Color(0xFFE6EFE9),
      ),
    ),
    distanceKm: 0,
    distanceLabel: activity.locationName,
    title: activity.title,
    dateLabel: activity.dateLabel,
    timeLabel: activity.timeLabel,
    locationName: activity.locationName,
    meetingPoint: activity.meetingPoint.isEmpty
        ? activity.locationName
        : activity.meetingPoint,
    description: activity.description,
    hostId: profile.id,
    hostName: profile.displayName.split(' ').first,
    hostFullName: profile.displayName,
    hostSubtitle: profile.cityName,
    hostScore: profile.attendanceScore,
    hostAvatarUrl: profile.avatarUrl,
    participants: const [],
    availableSpots: activity.availableSpots,
    spotsLabel: activity.spotsLabel,
    isJoined: false,
    isOwnedByCurrentUser: isOwnProfile,
  );
}

Color _colorFromHex(String hex, {required Color fallback}) {
  final normalized = hex.replaceFirst('#', '').trim();
  if (normalized.length != 6 && normalized.length != 8) {
    return fallback;
  }

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return fallback;
  }

  return Color(normalized.length == 6 ? 0xFF000000 | value : value);
}

IconData _iconForKey(String key) {
  return switch (key) {
    'set_meal' || 'fishing' => Icons.set_meal_rounded,
    'directions_walk' || 'walking' => Icons.directions_walk_rounded,
    'local_cafe' || 'coffee' => Icons.local_cafe_rounded,
    'sports_basketball' || 'sport' => Icons.sports_basketball_rounded,
    'sports_esports' || 'gaming' => Icons.sports_esports_rounded,
    'two_wheeler' || 'motor' => Icons.two_wheeler_rounded,
    'casino' || 'boardgames' => Icons.casino_rounded,
    'photo_camera' || 'photo' => Icons.photo_camera_rounded,
    'favorite' || 'social' => Icons.favorite_rounded,
    _ => Icons.event_rounded,
  };
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.profile, required this.isOwnProfile});

  final Profile profile;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Profiel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isOwnProfile)
          IconButton(
            onPressed: () async {
              final updatedProfile = await context.push<Profile>(
                AppRoutes.editProfile,
                extra: profile,
              );
              if (updatedProfile != null && context.mounted) {
                context.read<ProfileBloc>().add(const ProfileStarted());
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: colors.card,
              foregroundColor: colors.ink,
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
      ],
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: context.toch.green));
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.xl),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
