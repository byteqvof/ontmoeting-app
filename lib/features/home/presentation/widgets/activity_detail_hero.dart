import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../pages/activity_map_page.dart';
import 'activity_map_canvas.dart';

class ActivityDetailHero extends StatelessWidget {
  const ActivityDetailHero({
    required this.activity,
    this.onBackPressed,
    this.onEditPressed,
    super.key,
  });

  final HomeActivity activity;
  final VoidCallback? onBackPressed;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cream,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(TochRadius.lg),
        ),
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeroIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBackPressed ?? () => context.pop(),
                  ),
                  const Spacer(),
                  _HeroIconButton(
                    icon: Icons.ios_share_rounded,
                    onPressed: () {},
                  ),
                  const SizedBox(width: TochSpacing.xs),
                  if (onEditPressed != null) ...[
                    _HeroIconButton(
                      icon: Icons.edit_rounded,
                      onPressed: onEditPressed!,
                    ),
                    const SizedBox(width: TochSpacing.xs),
                  ],
                  _HeroIconButton(
                    icon: Icons.bookmark_border_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: TochSpacing.lg),
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: activity.category.backgroundColor,
                      borderRadius: BorderRadius.circular(TochRadius.md),
                    ),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        activity.category.icon,
                        color: activity.category.color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: TochSpacing.sm),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${activity.category.label} · ${activity.distanceLabel}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.green700.withValues(alpha: .72),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (activity.isFeatured) const _FeaturedBadge(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TochSpacing.sm),
              Text(
                activity.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.ink,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: TochSpacing.lg),
              _MapPreview(activity: activity),
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

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.card,
        foregroundColor: colors.ink,
        fixedSize: const Size.square(42),
      ),
      icon: Icon(icon, size: 21),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final hasCoordinates = activity.latitude != 0 || activity.longitude != 0;
    final location = HomeLocation(
      cityName: activity.locationName,
      latitude: activity.latitude,
      longitude: activity.longitude,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(TochRadius.lg),
      child: Material(
        color: const Color(0xFFE7EBE0),
        child: InkWell(
          onTap: hasCoordinates
              ? () => context.push(
                  AppRoutes.activityMap,
                  extra: ActivityMapPageArgs(
                    location: location,
                    activities: [activity],
                    filters: const HomeFeedFilters(),
                  ),
                )
              : null,
          child: SizedBox(
            height: 152,
            width: double.infinity,
            child: Stack(
              children: [
                if (hasCoordinates)
                  Positioned.fill(
                    child: ActivityMapCanvas(
                      location: location,
                      activities: [activity],
                      interactive: false,
                    ),
                  )
                else
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFFE7EBE0)),
                  ),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(TochRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: colors.ink.withValues(alpha: .10),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasCoordinates
                                ? Icons.map_rounded
                                : Icons.location_off_rounded,
                            color: colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Text(
                              hasCoordinates
                                  ? activity.meetingPoint
                                  : 'Locatie nog niet exact',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
