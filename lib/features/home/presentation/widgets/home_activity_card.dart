import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';
import 'home_avatar_stack.dart';

class HomeActivityCard extends StatelessWidget {
  const HomeActivityCard({
    required this.activity,
    this.onPressed,
    this.onJoinPressed,
    this.onProfilePressed,
    this.isJoinPending = false,
    super.key,
  });

  final HomeActivity activity;
  final VoidCallback? onPressed;
  final VoidCallback? onJoinPressed;
  final ValueChanged<String>? onProfilePressed;
  final bool isJoinPending;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final borderRadius = BorderRadius.circular(22);

    return Material(
      color: colors.card,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: borderRadius,
            border: Border.all(color: colors.line),
            boxShadow: [
              BoxShadow(
                color: colors.ink.withValues(alpha: .06),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Row(
                  children: [
                    _CategoryTile(activity: activity),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activity.category.label,
<<<<<<< HEAD
                                  maxLines: 1,
=======
>>>>>>> codex/beta-round-2-polish
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: activity.category.color,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              if (activity.isFeatured) ...[
                                const SizedBox(width: 8),
                                const _FeaturedBadge(),
                              ],
                              const SizedBox(width: 8),
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: colors.green700.withValues(alpha: .55),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                activity.distanceLabel,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colors.green700.withValues(
                                        alpha: .72,
                                      ),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activity.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: colors.ink,
                                        height: 1.12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                              if (activity.hostIdentityVerified) ...[
                                const SizedBox(width: 6),
                                Tooltip(
                                  message:
                                      'Deze gebruiker heeft zijn identiteit geverifieerd.',
                                  child: Icon(
                                    Icons.verified_rounded,
                                    color: const Color(0xFF2E7E5C),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: colors.green700,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        activity.dateLabel,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.green700,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: colors.green700,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      activity.timeLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.green700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 13, 18, 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFBF8),
                  border: Border(top: BorderSide(color: colors.line)),
                ),
                child: Row(
                  children: [
                    HomeAvatarStack(
                      participants: activity.participants,
                      maxVisibleAvatars: 3,
                      onProfilePressed: onProfilePressed,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        activity.spotsLabel,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.green700.withValues(alpha: .72),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    _JoinButton(
                      activity: activity,
                      isPending: isJoinPending,
                      onPressed: onJoinPressed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1B53A)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 12, color: colors.ink),
            const SizedBox(width: 3),
            Text(
              'Uitgelicht',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.activity,
    required this.isPending,
    this.onPressed,
  });

  final HomeActivity activity;
  final bool isPending;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final isOwnActivity = activity.isOwnedByCurrentUser;
    final isFull = !activity.isJoined && activity.availableSpots <= 0;
    final disabled =
        isOwnActivity || isFull || isPending || activity.isParticipationPending;
    final filled = !disabled && !activity.isJoined;

    return TextButton.icon(
      onPressed: disabled ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: disabled
            ? colors.green700.withValues(alpha: .55)
            : filled
            ? Colors.white
            : colors.green,
        backgroundColor: disabled
            ? colors.cream
            : filled
            ? colors.green
            : colors.green100,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
      ),
      icon: isPending
          ? SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: filled ? Colors.white : colors.green,
              ),
            )
          : Icon(_joinIconFor(activity), size: 17),
      label: Text(_joinLabelFor(activity)),
    );
  }
}

IconData _joinIconFor(HomeActivity activity) {
  if (activity.isOwnedByCurrentUser) {
    return Icons.event_available_rounded;
  }
  if (activity.isParticipationPending) {
    return Icons.hourglass_top_rounded;
  }
  if (!activity.isJoined && activity.availableSpots <= 0) {
    return Icons.block_rounded;
  }
  return activity.isJoined ? Icons.check_rounded : Icons.add_rounded;
}

String _joinLabelFor(HomeActivity activity) {
  if (activity.isOwnedByCurrentUser) {
    return 'Jouw event';
  }
  if (activity.isParticipationPending) {
    return 'In aanvraag';
  }
  if (!activity.isJoined && activity.availableSpots <= 0) {
    return 'Vol';
  }
  return activity.isJoined ? 'Je gaat' : 'Ga mee';
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: activity.category.color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: SizedBox.square(
        dimension: 52,
        child: Icon(activity.category.icon, color: Colors.white, size: 26),
      ),
    );
  }
}
