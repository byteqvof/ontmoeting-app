import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/friendship_service.dart';
import '../../../../core/services/safety_service.dart';
import '../../../../core/widgets/safety_report_dialog.dart';
import '../../../../core/widgets/toch_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../home/domain/entities/home_activity.dart';
import '../../../home/domain/entities/home_category.dart';
import '../../../home/presentation/widgets/home_bottom_nav.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_activity.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_activities_card.dart';
import '../widgets/profile_agenda_shortcut_card.dart';
import '../widgets/profile_interests_card.dart';
import '../widgets/profile_menu_list.dart';
import '../widgets/profile_premium_card.dart';
import '../widgets/profile_score_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({this.profileId, super.key});

  final String? profileId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ProfileBloc>()..add(ProfileStarted(profileId: profileId)),
      child: _ProfileView(profileId: profileId),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profileId});

  final String? profileId;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final currentUserId = _currentUserId(context);
    final requestedOwnProfile =
        profileId == null ||
        (currentUserId != null &&
            currentUserId.isNotEmpty &&
            profileId == currentUserId);

    return Scaffold(
      backgroundColor: colors.cream,
      bottomNavigationBar: requestedOwnProfile
          ? const HomeBottomNav(selected: HomeNavDestination.profile)
          : null,
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
                    isOwnProfile:
                        requestedOwnProfile || profile.id == currentUserId,
                  ),
              };
            },
          ),
        ),
      ),
    );
  }
}

String? _currentUserId(BuildContext context) {
  final authState = context.watch<AuthBloc>().state;
  return authState is AuthAuthenticated ? authState.user.id : null;
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
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 130),
        children: [
          _ProfileHeroHeader(profile: profile, isOwnProfile: isOwnProfile),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isOwnProfile) ...[
                  _FriendshipActionCard(profile: profile),
                  const SizedBox(height: TochSpacing.md),
                ],
                if (isOwnProfile) ...[
                  ProfileAgendaShortcutCard(
                    onPressed: () => context.push(AppRoutes.activityAgenda),
                  ),
                  const SizedBox(height: TochSpacing.md),
                ],
                _ProfileStatsGrid(profile: profile),
                const SizedBox(height: TochSpacing.md),
                ProfileScoreCard(profile: profile),
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
                _ProfileMenu(isOwnProfile: isOwnProfile, profile: profile),
                if (isOwnProfile) ...[
                  const SizedBox(height: TochSpacing.lg),
                  const _AppVersionFooter(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroHeader extends StatelessWidget {
  const _ProfileHeroHeader({required this.profile, required this.isOwnProfile});

  final Profile profile;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: colors.green),
          child: SizedBox(
            height: 112,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Align(
                alignment: Alignment.topRight,
                child: isOwnProfile
                    ? TextButton.icon(
                        onPressed: () async {
                          final updatedProfile = await context.push<Profile>(
                            AppRoutes.editProfile,
                            extra: profile,
                          );
                          if (updatedProfile != null && context.mounted) {
                            context.read<ProfileBloc>().add(
                              const ProfileStarted(),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .18),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(0, 34),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        icon: const Icon(Icons.edit_rounded, size: 15),
                        label: const Text('Bewerken'),
                      )
                    : IconButton(
                        onPressed: context.pop,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .18),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileAvatar(profile: profile),
                const SizedBox(height: 10),
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.place_outlined, color: colors.ink3, size: 15),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${profile.cityName} - lid sinds ${_profileMemberSinceLabel(profile.memberSince)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.ink3,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _profileBioLine(profile),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.ink2,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.cream, width: 4),
            boxShadow: [
              BoxShadow(
                color: colors.ink.withValues(alpha: .18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: colors.green,
            foregroundImage: profile.avatarUrl == null
                ? null
                : NetworkImage(profile.avatarUrl!),
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        if (profile.trust.identityVerified || profile.trust.phoneVerified)
          Positioned(
            right: 2,
            bottom: 2,
            child: Tooltip(
              message: profile.trust.identityVerified
                  ? 'Deze gebruiker heeft zijn identiteit geverifieerd.'
                  : 'Telefoon bevestigd.',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.verified,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.cream, width: 3),
                ),
                child: const SizedBox.square(
                  dimension: 26,
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileStatsGrid extends StatelessWidget {
  const _ProfileStatsGrid({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.75,
      ),
      children: [
        _ProfileStatTile(
          value: '${profile.activitiesJoinedCount}',
          label: 'keer meegedaan',
        ),
        _ProfileStatTile(
          value: '${profile.activitiesHostedCount}',
          label: 'georganiseerd',
        ),
        _ProfileStatTile(
          value: profile.rating.toStringAsFixed(1).replaceAll('.', ','),
          label: 'beoordeling',
          accent: context.toch.orange,
        ),
        _ProfileStatTile(
          value: '${profile.attendanceScore}%',
          label: 'opkomst',
          accent: context.toch.green,
        ),
      ],
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.value,
    required this.label,
    this.accent,
  });

  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.md),
        boxShadow: TochShadows.card(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: accent ?? colors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.ink3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _profileBioLine(Profile profile) {
  return 'Open voor laagdrempelige ontmoetingen en spontane plannen in de buurt.';
}

String _profileMemberSinceLabel(DateTime date) {
  const months = [
    'januari',
    'februari',
    'maart',
    'april',
    'mei',
    'juni',
    'juli',
    'augustus',
    'september',
    'oktober',
    'november',
    'december',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version = info?.version;
        if (version == null || version.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Text(
          'Versie $version',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.green700.withValues(alpha: .48),
            fontWeight: FontWeight.w800,
          ),
        );
      },
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.isOwnProfile, required this.profile});

  final bool isOwnProfile;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    if (!isOwnProfile) {
      return _buildMenu(context, friendsBadgeCount: 0);
    }

    return FutureBuilder<List<FriendshipListItem>>(
      future: sl<FriendshipService>().listFriends(),
      builder: (context, snapshot) {
        final friendsBadgeCount = snapshot.hasData
            ? countIncomingFriendRequests(snapshot.data!)
            : 0;
        return _buildMenu(context, friendsBadgeCount: friendsBadgeCount);
      },
    );
  }

  ProfileMenuList _buildMenu(
    BuildContext context, {
    required int friendsBadgeCount,
  }) {
    return ProfileMenuList(
      isOwnProfile: isOwnProfile,
      friendsBadgeCount: friendsBadgeCount,
      onSignOutPressed: () => _confirmSignOut(context),
      onAccountVerificationPressed: isOwnProfile
          ? () => context.push(AppRoutes.accountVerification)
          : null,
      onAgendaPressed: isOwnProfile
          ? () => context.push(AppRoutes.activityAgenda)
          : null,
      onFriendsPressed: isOwnProfile
          ? () => context.push(AppRoutes.friends)
          : null,
      onPrivacyPressed: () => context.push(AppRoutes.privacyLocation),
      onNotificationsPressed: () => context.push(AppRoutes.notifications),
      onHelpPressed: () => context.push(AppRoutes.appInfo),
      onDeleteAccountPressed: isOwnProfile
          ? () => _confirmDeleteAccount(context)
          : null,
      onReportProfilePressed: isOwnProfile
          ? null
          : () => _reportProfile(context, profile),
      onBlockProfilePressed: isOwnProfile
          ? null
          : () => _blockProfile(context, profile),
    );
  }
}

class _FriendshipActionCard extends StatefulWidget {
  const _FriendshipActionCard({required this.profile});

  final Profile profile;

  @override
  State<_FriendshipActionCard> createState() => _FriendshipActionCardState();
}

class _FriendshipActionCardState extends State<_FriendshipActionCard> {
  late Future<FriendshipSummary> _statusFuture = _loadStatus();
  bool _isUpdating = false;

  Future<FriendshipSummary> _loadStatus() {
    return sl<FriendshipService>().getStatus(widget.profile.id);
  }

  void _refresh() {
    setState(() {
      _statusFuture = _loadStatus();
    });
  }

  Future<void> _runAction(
    Future<FriendshipSummary> Function(FriendshipService service) action,
    String successMessage,
  ) async {
    setState(() => _isUpdating = true);
    try {
      final result = await action(sl<FriendshipService>());
      if (!mounted) {
        return;
      }
      setState(() {
        _statusFuture = Future.value(result);
        _isUpdating = false;
      });
      _showProfileMessage(context, successMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isUpdating = false);
      _showProfileMessage(context, 'Vriendschap bijwerken lukt nu niet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FriendshipSummary>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _FriendshipCardShell(child: _FriendshipLoading());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _FriendshipCardShell(
            child: _FriendshipStatusError(onRetry: _refresh),
          );
        }

        final status = snapshot.data!.status;
        return _FriendshipCardShell(
          child: switch (status) {
            FriendshipStatus.accepted => _FriendshipAcceptedActions(
              isUpdating: _isUpdating,
              onRemove: () => _runAction(
                (service) => service.remove(widget.profile.id),
                'Vriend verwijderd.',
              ),
            ),
            FriendshipStatus.pendingSent => _FriendshipPendingSentActions(
              isUpdating: _isUpdating,
              onCancel: () => _runAction(
                (service) => service.remove(widget.profile.id),
                'Verzoek ingetrokken.',
              ),
            ),
            FriendshipStatus.pendingReceived =>
              _FriendshipPendingReceivedActions(
                isUpdating: _isUpdating,
                onAccept: () => _runAction(
                  (service) => service.accept(widget.profile.id),
                  'Vriend toegevoegd.',
                ),
                onDecline: () => _runAction(
                  (service) => service.decline(widget.profile.id),
                  'Verzoek geweigerd.',
                ),
              ),
            FriendshipStatus.blocked => _FriendshipUnavailable(),
            FriendshipStatus.self => const SizedBox.shrink(),
            _ => _FriendshipRequestActions(
              isUpdating: _isUpdating,
              onRequest: () => _runAction(
                (service) => service.request(widget.profile.id),
                'Vriendschapsverzoek verstuurd.',
              ),
            ),
          },
        );
      },
    );
  }
}

class _FriendshipCardShell extends StatelessWidget {
  const _FriendshipCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: child,
      ),
    );
  }
}

class _FriendshipStatusError extends StatelessWidget {
  const _FriendshipStatusError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.group_off_outlined, color: colors.green),
            const SizedBox(width: TochSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vriendenfunctie niet bereikbaar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'We kunnen de vriendschapstatus nu niet ophalen. Probeer het later opnieuw.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.green700.withValues(alpha: .72),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TochSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Opnieuw proberen'),
          ),
        ),
      ],
    );
  }
}

class _FriendshipLoading extends StatelessWidget {
  const _FriendshipLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Row(
      children: [
        SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(color: colors.green, strokeWidth: 2),
        ),
        const SizedBox(width: TochSpacing.sm),
        Expanded(
          child: Text(
            'Vriendschap laden',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.green700,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendshipRequestActions extends StatelessWidget {
  const _FriendshipRequestActions({
    required this.isUpdating,
    required this.onRequest,
  });

  final bool isUpdating;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_add_alt_1_rounded),
        const SizedBox(width: TochSpacing.sm),
        Expanded(
          child: Text(
            'Leuk gehad? Voeg toe als vriend om elkaar later sneller terug te vinden.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: TochSpacing.sm),
        FilledButton(
          onPressed: isUpdating ? null : onRequest,
          child: const Text('Toevoegen'),
        ),
      ],
    );
  }
}

class _FriendshipPendingSentActions extends StatelessWidget {
  const _FriendshipPendingSentActions({
    required this.isUpdating,
    required this.onCancel,
  });

  final bool isUpdating;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.schedule_rounded),
        const SizedBox(width: TochSpacing.sm),
        const Expanded(child: Text('Vriendschapsverzoek verstuurd.')),
        TextButton(
          onPressed: isUpdating ? null : onCancel,
          child: const Text('Intrekken'),
        ),
      ],
    );
  }
}

class _FriendshipPendingReceivedActions extends StatelessWidget {
  const _FriendshipPendingReceivedActions({
    required this.isUpdating,
    required this.onAccept,
    required this.onDecline,
  });

  final bool isUpdating;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Deze gebruiker wil vrienden worden.'),
        const SizedBox(height: TochSpacing.sm),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isUpdating ? null : onAccept,
                child: const Text('Accepteer'),
              ),
            ),
            const SizedBox(width: TochSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: isUpdating ? null : onDecline,
                child: const Text('Weiger'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FriendshipAcceptedActions extends StatelessWidget {
  const _FriendshipAcceptedActions({
    required this.isUpdating,
    required this.onRemove,
  });

  final bool isUpdating;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: colors.green),
        const SizedBox(width: TochSpacing.sm),
        const Expanded(child: Text('Jullie zijn vrienden.')),
        TextButton(
          onPressed: isUpdating ? null : onRemove,
          child: const Text('Verwijder'),
        ),
      ],
    );
  }
}

class _FriendshipUnavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.block_rounded),
        SizedBox(width: TochSpacing.sm),
        Expanded(child: Text('Vriendschap is niet beschikbaar.')),
      ],
    );
  }
}

Future<void> _reportProfile(BuildContext context, Profile profile) async {
  final report = await _askForSafetyDetails(
    context,
    title: 'Profiel rapporteren',
    body: 'Vertel kort wat er niet klopt. We bewaren dit voor moderatie.',
    confirmLabel: 'Rapporteer',
  );
  if (report == null || !context.mounted) {
    return;
  }

  try {
    await sl<SafetyService>().reportProfile(
      profileId: profile.id,
      reason: report.reason,
      details: report.details,
    );
    if (context.mounted) {
      _showProfileMessage(context, 'Profiel gerapporteerd.');
    }
    AnalyticsService.instance.track(
      'report_submitted',
      properties: {'target_type': 'profile', 'reason': report.reason.name},
    );
  } catch (_) {
    if (context.mounted) {
      _showProfileMessage(context, 'Rapporteren lukt nu niet.');
    }
  }
}

Future<void> _blockProfile(BuildContext context, Profile profile) async {
  final shouldBlock = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Gebruiker blokkeren?'),
        content: Text(
          '${profile.displayName} kan jou dan niet meer benaderen. Je kunt dit later weer aanpassen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuleer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Blokkeer'),
          ),
        ],
      );
    },
  );

  if (shouldBlock != true || !context.mounted) {
    return;
  }

  try {
    await sl<SafetyService>().blockProfile(profile.id);
    if (context.mounted) {
      _showProfileMessage(context, 'Gebruiker geblokkeerd.');
      AnalyticsService.instance.track(
        'block_submitted',
        properties: {'target_type': 'profile'},
      );
      context.go(AppRoutes.home);
    }
  } catch (_) {
    if (context.mounted) {
      _showProfileMessage(context, 'Blokkeren lukt nu niet.');
    }
  }
}

Future<void> _confirmDeleteAccount(BuildContext context) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Account verwijderen?'),
        content: const Text(
          'Je profiel, sessie en gekoppelde account worden verwijderd. Dit kun je niet terugdraaien.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuleer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Verwijder'),
          ),
        ],
      );
    },
  );

  if (shouldDelete != true || !context.mounted) {
    return;
  }

  try {
    await sl<SafetyService>().deleteAccount();
    if (context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  } catch (_) {
    if (context.mounted) {
      _showProfileMessage(context, 'Account verwijderen lukt nu niet.');
    }
  }
}

Future<SafetyReportDraft?> _askForSafetyDetails(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  return showSafetyReportDialog(
    context,
    title: title,
    body: body,
    confirmLabel: confirmLabel,
  );
}

void _showProfileMessage(BuildContext context, String message) {
  showTochSnackBar(context, message);
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
      iconKey: activity.category.iconKey,
      colorHex: activity.category.foregroundColorHex,
      backgroundColorHex: activity.category.backgroundColorHex,
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
    hostScore: profile.trust.reputationScore,
    hostIdentityVerified: profile.trust.identityVerified,
    hostReputationLevel: profile.trust.reputationLevel,
    hostAvatarUrl: profile.avatarUrl,
    participants: const [],
    availableSpots: activity.availableSpots,
    spotsLabel: activity.spotsLabel,
    isJoined: false,
    isOwnedByCurrentUser: isOwnProfile,
    status: activity.status,
  );
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
