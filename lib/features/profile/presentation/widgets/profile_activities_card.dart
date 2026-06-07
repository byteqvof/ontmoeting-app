import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/profile_activity.dart';

class ProfileActivitiesCard extends StatelessWidget {
  const ProfileActivitiesCard({
    required this.activities,
    required this.isOwnProfile,
    required this.onActivityPressed,
    this.errorMessage,
    super.key,
  });

  final List<ProfileActivity> activities;
  final bool isOwnProfile;
  final ValueChanged<ProfileActivity> onActivityPressed;
  final String? errorMessage;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    isOwnProfile ? 'Mijn activiteiten' : 'Activiteiten',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${activities.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.green700.withValues(alpha: .72),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TochSpacing.sm),
            if (errorMessage != null)
              _ProfileActivitiesMessage(
                icon: Icons.error_outline_rounded,
                message: 'Activiteiten laden lukte niet.',
                detail: errorMessage!,
              )
            else if (activities.isEmpty)
              _ProfileActivitiesMessage(
                icon: Icons.event_busy_rounded,
                message: isOwnProfile
                    ? 'Je hebt nog geen activiteiten aangemaakt.'
                    : 'Nog geen publieke activiteiten.',
                detail: isOwnProfile
                    ? 'Maak een activiteit aan via de plus-knop.'
                    : 'Kom later nog eens kijken.',
              )
            else
              ...activities.take(6).map((activity) {
                return Padding(
                  padding: const EdgeInsets.only(top: TochSpacing.sm),
                  child: _ProfileActivityTile(
                    activity: activity,
                    onPressed: () => onActivityPressed(activity),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ProfileActivityTile extends StatelessWidget {
  const _ProfileActivityTile({required this.activity, required this.onPressed});

  final ProfileActivity activity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final categoryColor = _colorFromHex(
      activity.category.foregroundColorHex,
      fallback: colors.green,
    );
    final categoryBackground = _colorFromHex(
      activity.category.backgroundColorHex,
      fallback: colors.green100,
    );

    final borderRadius = BorderRadius.circular(TochRadius.md);

    return Material(
      color: colors.cream,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: colors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: categoryBackground,
                    borderRadius: BorderRadius.circular(TochRadius.md),
                  ),
                  child: SizedBox.square(
                    dimension: 42,
                    child: Icon(
                      _iconForKey(activity.category.iconKey),
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: TochSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: colors.ink, height: 1.12),
                            ),
                          ),
                          const SizedBox(width: TochSpacing.xs),
                          _StatusChip(status: activity.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (activity.dateLabel.isNotEmpty) activity.dateLabel,
                          if (activity.timeLabel.isNotEmpty) activity.timeLabel,
                        ].join(' · '),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.green700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        [
                          if (activity.locationName.isNotEmpty)
                            activity.locationName,
                          activity.spotsLabel,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.green700.withValues(alpha: .72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TochSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.green700.withValues(alpha: .45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final label = switch (status) {
      'draft' => 'Concept',
      'cancelled' => 'Geannuleerd',
      'archived' => 'Archief',
      'completed' => 'Afgerond',
      _ => 'Live',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: status == 'published' ? colors.green100 : colors.card,
        borderRadius: BorderRadius.circular(TochRadius.pill),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: status == 'published'
                ? colors.green
                : colors.green700.withValues(alpha: .7),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProfileActivitiesMessage extends StatelessWidget {
  const _ProfileActivitiesMessage({
    required this.icon,
    required this.message,
    required this.detail,
  });

  final IconData icon;
  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TochSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: colors.green700.withValues(alpha: .55)),
          const SizedBox(width: TochSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.green700.withValues(alpha: .68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
