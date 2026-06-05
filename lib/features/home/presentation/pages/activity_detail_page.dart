import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/usecases/set_activity_participation.dart';
import '../widgets/activity_detail_action_bar.dart';
import '../widgets/activity_detail_hero.dart';
import '../widgets/activity_detail_host_card.dart';
import '../widgets/activity_detail_info_card.dart';
import '../widgets/activity_detail_participants_card.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({required this.activity, super.key});

  final HomeActivity activity;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late HomeActivity _activity = widget.activity;
  final SetActivityParticipation _setActivityParticipation = sl();
  bool _isParticipationPending = false;

  Future<void> _toggleParticipation() async {
    if (_activity.isOwnedByCurrentUser || _isParticipationPending) {
      return;
    }

    if (!_activity.isJoined && _activity.availableSpots <= 0) {
      _showMessage('Deze activiteit zit vol.');
      return;
    }

    setState(() {
      _isParticipationPending = true;
    });

    final result = await _setActivityParticipation(
      SetActivityParticipationParams(
        activityId: _activity.id,
        join: !_activity.isJoined,
      ),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isParticipationPending = false;
        });
        _showMessage(failure.message);
      },
      (update) {
        setState(() {
          _activity = _activity.applyParticipationUpdate(update);
          _isParticipationPending = false;
        });
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openChat() {
    if (!_activity.isOwnedByCurrentUser && !_activity.isJoined) {
      _showMessage('Meld je eerst aan om de chat te openen.');
      return;
    }

    context.push(AppRoutes.activityChatPath(_activity.id), extra: _activity);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ActivityDetailHero(
                      activity: _activity,
                      onBackPressed: () => context.pop(_activity),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 126),
                    sliver: SliverList.list(
                      children: [
                        ActivityDetailInfoCard(activity: _activity),
                        const SizedBox(height: TochSpacing.md),
                        ActivityDetailHostCard(
                          activity: _activity,
                          onProfilePressed: (profileId) {
                            context.push(AppRoutes.profilePath(profileId));
                          },
                        ),
                        const SizedBox(height: TochSpacing.md),
                        _DescriptionCard(activity: _activity),
                        const SizedBox(height: TochSpacing.md),
                        ActivityDetailParticipantsCard(
                          activity: _activity,
                          onProfilePressed: (profileId) {
                            context.push(AppRoutes.profilePath(profileId));
                          },
                        ),
                        const SizedBox(height: TochSpacing.md),
                        const _SafetyCard(),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ActivityDetailActionBar(
                  activity: _activity,
                  isParticipationPending: _isParticipationPending,
                  onParticipationPressed: _toggleParticipation,
                  onChatPressed: _openChat,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MissingActivityDetailPage extends StatelessWidget {
  const MissingActivityDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded, color: colors.orange, size: 44),
                const SizedBox(height: TochSpacing.md),
                Text(
                  'Activiteit niet gevonden',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TochSpacing.sm),
                Text(
                  'Open deze activiteit opnieuw vanuit de feed.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: TochSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Terug naar overzicht'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.activity});

  final HomeActivity activity;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Over deze activiteit',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.green700.withValues(alpha: .7),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: TochSpacing.sm),
            Text(
              activity.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.ink,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.green100,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.green200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_rounded, color: colors.green, size: 22),
            const SizedBox(width: TochSpacing.sm),
            Expanded(
              child: Text(
                'Geverifieerde host · deel altijd je locatie met iemand die je vertrouwt.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.green,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
