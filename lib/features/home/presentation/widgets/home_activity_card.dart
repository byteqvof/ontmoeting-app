import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';
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
    final skin = tochCategorySkin('${activity.category.id} ${activity.category.label}');
    final borderRadius = BorderRadius.circular(TochRadius.lg);
    final isLarge = activity.isFeatured || activity.distanceKm <= 2;

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
            boxShadow: TochShadows.card(colors),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TochPhotoPanel(
                title: activity.title,
                categoryLabel: activity.category.label,
                icon: activity.category.icon,
                skin: skin,
                distanceLabel: activity.distanceLabel,
                live: _isLive(activity),
                height: isLarge ? 176 : 120,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
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
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _HostRow(activity: activity),
                    const SizedBox(height: 8),
                    _MetaRow(activity: activity),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: const Color(0xFFF2EEE5)),
                    ),
                    Row(
                      children: [
                        HomeAvatarStack(
                          participants: activity.participants,
                          maxVisibleAvatars: 3,
                          onProfilePressed: onProfilePressed,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _participantsLabel(activity),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: colors.ink3,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _JoinButton(
                          activity: activity,
                          isPending: isJoinPending,
                          onPressed: onJoinPressed,
                        ),
                      ],
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

class _HostRow extends StatelessWidget {
  const _HostRow({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final initials = activity.hostName.trim().isEmpty
        ? '?'
        : activity.hostName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
              .join();

    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: tochCategorySkin(activity.category.label).color,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 8,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            activity.hostName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.ink2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (activity.hostIdentityVerified) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: 'Deze gebruiker heeft zijn identiteit geverifieerd.',
            child: Icon(Icons.verified_rounded, color: colors.verified, size: 14),
          ),
        ],
        const SizedBox(width: 8),
        Text(
          '${activity.hostScore} score',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.ink3,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _MetaItem(
          icon: Icons.calendar_today_rounded,
          label: '${activity.dateLabel} ${activity.timeLabel}',
        ),
        _MetaItem(
          icon: Icons.place_outlined,
          label: activity.meetingPoint.isEmpty
              ? activity.locationName
              : activity.meetingPoint,
        ),
      ].map((item) {
        return IconTheme(
          data: IconThemeData(color: colors.ink3, size: 13),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.ink3,
              fontWeight: FontWeight.w700,
            ),
            child: item,
          ),
        );
      }).toList(),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

    return SizedBox(
      height: 36,
      child: TextButton(
        onPressed: disabled ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: filled ? Colors.white : colors.green,
          backgroundColor: filled ? colors.green : colors.green100,
          disabledForegroundColor: colors.ink4,
          disabledBackgroundColor: colors.surface2,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        child: isPending
            ? SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: filled ? Colors.white : colors.green,
                ),
              )
            : Text(_joinLabelFor(activity)),
      ),
    );
  }
}

String _participantsLabel(HomeActivity activity) {
  final count = activity.participantCount;
  if (count <= 0) {
    return activity.spotsLabel;
  }
  return '$count gaan mee - ${activity.spotsLabel}';
}

String _joinLabelFor(HomeActivity activity) {
  if (activity.isOwnedByCurrentUser) {
    return 'Beheer';
  }
  if (activity.isParticipationPending) {
    return 'In aanvraag';
  }
  if (!activity.isJoined && activity.availableSpots <= 0) {
    return 'Vol';
  }
  return activity.isJoined ? 'Je gaat' : 'Aansluiten';
}

bool _isLive(HomeActivity activity) {
  final start = activity.startsAt;
  if (start == null || activity.isCompleted) {
    return false;
  }
  final now = DateTime.now();
  return !start.isAfter(now) && now.difference(start).inHours < 5;
}
