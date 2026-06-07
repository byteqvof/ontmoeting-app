import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_home_feed.dart';
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

class ActivityMapLoaderPage extends StatefulWidget {
  const ActivityMapLoaderPage({super.key});

  @override
  State<ActivityMapLoaderPage> createState() => _ActivityMapLoaderPageState();
}

class _ActivityMapLoaderPageState extends State<ActivityMapLoaderPage> {
  final GetCurrentLocation _getCurrentLocation = sl();
  final GetHomeFeed _getHomeFeed = sl();

  ActivityMapPageArgs? _args;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  Future<void> _loadMap() async {
    setState(() {
      _errorMessage = null;
    });

    final locationResult = await _getCurrentLocation(
      const GetCurrentLocationParams(forceRefresh: true),
    );
    if (!mounted) {
      return;
    }

    await locationResult.fold(
      (failure) async {
        setState(() {
          _errorMessage = failure.message;
        });
      },
      (location) async {
        final filters = const HomeFeedFilters();
        final feedResult = await _getHomeFeed(
          GetHomeFeedParams(
            location: location,
            filters: filters,
            forceRefresh: true,
          ),
        );
        if (!mounted) {
          return;
        }
        feedResult.fold(
          (failure) => setState(() {
            _errorMessage = failure.message;
          }),
          (feed) => setState(() {
            _args = ActivityMapPageArgs(
              location: location,
              activities: feed.activities,
              filters: filters,
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args != null) {
      return ActivityMapPage(args: args);
    }

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
                Icon(Icons.map_rounded, color: colors.green, size: 44),
                const SizedBox(height: TochSpacing.md),
                Text(
                  _errorMessage == null ? 'Kaart laden' : 'Kaart niet geladen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TochSpacing.sm),
                if (_errorMessage == null)
                  const CircularProgressIndicator()
                else ...[
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: TochSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: _loadMap,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Opnieuw proberen'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityMapPage extends StatefulWidget {
  const ActivityMapPage({required this.args, super.key});

  final ActivityMapPageArgs args;

  @override
  State<ActivityMapPage> createState() => _ActivityMapPageState();
}

class _ActivityMapPageState extends State<ActivityMapPage> {
  final GetHomeFeed _getHomeFeed = sl();
  final GetCurrentLocation _getCurrentLocation = sl();
  late HomeLocation _location = widget.args.location;
  late List<HomeActivity> _activities = widget.args.activities;
  HomeLocation? _pendingSearchLocation;
  bool _isSearching = false;
  bool _isLocating = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: ActivityMapCanvas(
                location: _location,
                activities: _activities,
                onCameraIdleLocation: _onCameraIdleLocation,
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
                          borderRadius: BorderRadius.circular(TochRadius.pill),
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
                            '${_activities.length} activiteiten rond ${_location.cityName}',
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
              top: 88,
              right: 14,
              child: SafeArea(
                child: IconButton.filled(
                  onPressed: _isLocating ? null : _recenterOnDeviceLocation,
                  icon: _isLocating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  tooltip: 'Mijn locatie',
                ),
              ),
            ),
            if (_pendingSearchLocation != null)
              Positioned(
                top: 78,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: _isSearching ? null : _searchInThisArea,
                      icon: _isSearching
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.travel_explore_rounded),
                      label: const Text('Zoek in dit gebied'),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: _MapActivityTray(activities: _activities),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCameraIdleLocation(HomeLocation location) {
    if (!_isMeaningfullyDifferent(location, _location)) {
      return;
    }
    setState(() {
      _pendingSearchLocation = location;
    });
  }

  Future<void> _searchInThisArea() async {
    final searchLocation = _pendingSearchLocation;
    if (searchLocation == null || _isSearching) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final result = await _getHomeFeed(
      GetHomeFeedParams(
        location: searchLocation,
        filters: widget.args.filters,
        forceRefresh: true,
      ),
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (feed) {
        setState(() {
          _location = searchLocation;
          _activities = feed.activities;
          _pendingSearchLocation = null;
          _isSearching = false;
        });
      },
    );
  }

  Future<void> _recenterOnDeviceLocation() async {
    if (_isLocating) {
      return;
    }
    setState(() {
      _isLocating = true;
    });

    final result = await _getCurrentLocation(
      const GetCurrentLocationParams(forceRefresh: true),
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isLocating = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (location) {
        setState(() {
          _location = location;
          _pendingSearchLocation = location;
          _isLocating = false;
        });
      },
    );
  }
}

bool _isMeaningfullyDifferent(HomeLocation left, HomeLocation right) {
  final latitudeDelta = (left.latitude - right.latitude).abs();
  final longitudeDelta = (left.longitude - right.longitude).abs();
  return latitudeDelta > 0.003 || longitudeDelta > 0.003;
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
