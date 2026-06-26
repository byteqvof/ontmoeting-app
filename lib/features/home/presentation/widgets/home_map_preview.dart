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
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TochRadius.xl),
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
              height: 190,
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
                    left: 14,
                    top: 14,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(TochRadius.pill),
                        boxShadow: TochShadows.card(colors),
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
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.card.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: TochShadows.raised(colors),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.green100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SizedBox.square(
                                dimension: 42,
                                child: Icon(
                                  Icons.map_rounded,
                                  color: colors.green,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bekijk op kaart',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: colors.ink,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rond ${location.cityName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colors.ink3,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox.square(
                                dimension: 40,
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.green,
                        shape: BoxShape.circle,
                        boxShadow: TochShadows.button(colors),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
