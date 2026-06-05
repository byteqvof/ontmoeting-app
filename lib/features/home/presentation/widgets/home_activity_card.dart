import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';
import 'home_avatar_stack.dart';

class HomeActivityCard extends StatelessWidget {
  const HomeActivityCard({required this.activity, super.key});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: .045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CategoryTile(activity: activity),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.category.label,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: activity.category.color,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
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
                                  color: colors.green700.withValues(alpha: .72),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.ink, height: 1.12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: colors.green700,
                ),
                const SizedBox(width: 6),
                Text(
                  activity.dateLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.green700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text('·', style: TextStyle(color: colors.green700)),
                const SizedBox(width: 6),
                Icon(Icons.schedule_rounded, size: 16, color: colors.green700),
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
            const SizedBox(height: 14),
            Divider(height: 1, color: colors.line),
            const SizedBox(height: 12),
            Row(
              children: [
                HomeAvatarStack(initials: activity.participantInitials),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              activity.hostName,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            color: const Color(0xFF2E7E5C),
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        activity.spotsLabel,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.green700.withValues(alpha: .72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _JoinButton(activity: activity),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return TextButton.icon(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: colors.green,
        backgroundColor: colors.green100,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
      ),
      icon: Icon(
        activity.isJoined ? Icons.check_rounded : Icons.add_rounded,
        size: 17,
      ),
      label: Text(activity.isJoined ? 'Je gaat' : 'Ga mee'),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: activity.category.backgroundColor,
        borderRadius: BorderRadius.circular(TochRadius.md),
      ),
      child: SizedBox.square(
        dimension: 48,
        child: Icon(
          activity.category.icon,
          color: activity.category.color,
          size: 25,
        ),
      ),
    );
  }
}
