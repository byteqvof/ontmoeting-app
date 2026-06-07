import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/services/analytics_service.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../pages/activity_map_page.dart';
import 'activity_map_canvas.dart';

class HomeMapPreview extends StatelessWidget {
  const HomeMapPreview({
    required this.location,
    required this.activities,
    required this.filters,
    super.key,
  });

  final HomeLocation location;
  final List<HomeActivity> activities;
  final HomeFeedFilters filters;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TochRadius.lg),
        child: Material(
          color: const Color(0xFFEAEDE4),
          child: InkWell(
            onTap: () {
              AnalyticsService.instance.track(
                'map_opened',
                properties: {
                  'activity_count': activities.length,
                  'distance_km': filters.distanceKm,
                  'has_advanced_filters': filters.hasAdvancedFilters,
                },
              );
              context.push(
                AppRoutes.activityMap,
                extra: ActivityMapPageArgs(
                  location: location,
                  activities: activities,
                  filters: filters,
                ),
              );
            },
            child: SizedBox(
              height: 198,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ActivityMapCanvas(
                      location: location,
                      activities: activities,
                      interactive: false,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(TochRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: colors.ink.withValues(alpha: .08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
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
                              Icons.map_outlined,
                              color: colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${activities.length} vlakbij',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.ink.withValues(alpha: .18),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const SizedBox.square(
                        dimension: 42,
                        child: Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.card.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(TochRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: colors.ink.withValues(alpha: .10),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.travel_explore_rounded,
                              color: colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bekijk op kaart',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: colors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.green,
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
      ),
    );
  }
}
