import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../widgets/activity_map_canvas.dart';

class ActivityMapPageArgs {
  const ActivityMapPageArgs({
    required this.location,
    required this.activities,
    required this.filters,
  });

  final HomeLocation location;
  final List<HomeActivity> activities;
  final HomeFeedFilters filters;
}

class ActivityMapPage extends StatelessWidget {
  const ActivityMapPage({required this.args, super.key});

  final ActivityMapPageArgs args;

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
              Positioned.fill(
                child: ActivityMapCanvas(
                  location: args.location,
                  activities: args.activities,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      IconButton.filled(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                            return;
                          }
                          context.go(AppRoutes.home);
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: TochSpacing.sm),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.card.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(
                              TochRadius.pill,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.ink.withValues(alpha: .10),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              '${args.activities.length} activiteiten rond ${args.location.cityName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: _MapActivityTray(activities: args.activities),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MissingActivityMapPage extends StatelessWidget {
  const MissingActivityMapPage({super.key});

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
                Icon(Icons.map_outlined, color: colors.green, size: 44),
                const SizedBox(height: TochSpacing.md),
                Text(
                  'Kaart niet geladen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TochSpacing.sm),
                const Text(
                  'Open de kaart opnieuw vanuit Ontdek.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TochSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Naar ontdekken'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapActivityTray extends StatelessWidget {
  const _MapActivityTray({required this.activities});

  final List<HomeActivity> activities;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final visibleActivities = activities.take(8).toList();

    if (visibleActivities.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(TochRadius.lg),
          border: Border.all(color: colors.line),
        ),
        child: const Padding(
          padding: EdgeInsets.all(TochSpacing.md),
          child: Text('Geen activiteiten binnen deze filters.'),
        ),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleActivities.length,
        separatorBuilder: (_, _) => const SizedBox(width: TochSpacing.sm),
        itemBuilder: (context, index) {
          final activity = visibleActivities[index];
          return SizedBox(
            width: 260,
            child: Material(
              color: colors.card.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(TochRadius.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(TochRadius.lg),
                onTap: () {
                  context.push(
                    AppRoutes.activityDetailPath(activity.id),
                    extra: activity,
                  );
                },
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
                          dimension: 54,
                          child: Icon(
                            activity.category.icon,
                            color: activity.category.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: TochSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              activity.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w900,
                                    height: 1.12,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activity.distanceLabel} - ${activity.timeLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.green700.withValues(
                                      alpha: .68,
                                    ),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
