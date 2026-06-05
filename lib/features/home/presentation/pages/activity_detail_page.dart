import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';
import '../widgets/activity_detail_action_bar.dart';
import '../widgets/activity_detail_hero.dart';
import '../widgets/activity_detail_host_card.dart';
import '../widgets/activity_detail_info_card.dart';
import '../widgets/activity_detail_participants_card.dart';

class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({required this.activity, super.key});

  final HomeActivity activity;

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
                    child: ActivityDetailHero(activity: activity),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 126),
                    sliver: SliverList.list(
                      children: [
                        ActivityDetailInfoCard(activity: activity),
                        const SizedBox(height: TochSpacing.md),
                        ActivityDetailHostCard(activity: activity),
                        const SizedBox(height: TochSpacing.md),
                        _DescriptionCard(activity: activity),
                        const SizedBox(height: TochSpacing.md),
                        ActivityDetailParticipantsCard(activity: activity),
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
                child: ActivityDetailActionBar(activity: activity),
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
