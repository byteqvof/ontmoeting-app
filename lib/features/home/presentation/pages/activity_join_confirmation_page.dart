import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';

class ActivityJoinConfirmationPage extends StatelessWidget {
  const ActivityJoinConfirmationPage({
    required this.activity,
    this.onOpenChat,
    this.onBackToDiscover,
    super.key,
  });

  final HomeActivity activity;
  final VoidCallback? onOpenChat;
  final VoidCallback? onBackToDiscover;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.green,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                children: [
                  const Spacer(),
                  _CheckMarkHero(color: colors.green),
                  const SizedBox(height: TochSpacing.lg),
                  Text(
                    'Je gaat!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: TochSpacing.sm),
                  Text(
                    'Geen druk - kom je opdagen, dan stijgt je opkomstscore.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: .92),
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: TochSpacing.lg),
                  _JoinedActivityCard(activity: activity),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onOpenChat ?? () => _openChat(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.card,
                        foregroundColor: colors.green,
                        minimumSize: const Size.fromHeight(54),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Open de chat'),
                    ),
                  ),
                  const SizedBox(height: TochSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed:
                          onBackToDiscover ?? () => context.go(AppRoutes.home),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .16),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: const Text('Terug naar ontdekken'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    context.push(AppRoutes.activityChatPath(activity.id), extra: activity);
  }
}

class _CheckMarkHero extends StatelessWidget {
  const _CheckMarkHero({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .06),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: SizedBox.square(
            dimension: 92,
            child: Icon(Icons.check_rounded, color: color, size: 60),
          ),
        ),
      ),
    );
  }
}

class _JoinedActivityCard extends StatelessWidget {
  const _JoinedActivityCard({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: activity.category.backgroundColor,
                borderRadius: BorderRadius.circular(TochRadius.md),
              ),
              child: SizedBox.square(
                dimension: 56,
                child: Icon(
                  activity.category.icon,
                  color: activity.category.color,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: TochSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${activity.dateLabel} - ${activity.timeLabel}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.green700.withValues(alpha: .75),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
