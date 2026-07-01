import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/toch_snack_bar.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/entities/meeting_location_suggestion.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_home_feed.dart';
import '../../domain/usecases/search_meeting_locations.dart';
import '../widgets/activity_map_canvas.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_category_style.dart';

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
  final SearchMeetingLocations _searchLocations = sl();
  final TextEditingController _searchController = TextEditingController();
  late HomeLocation _location = widget.args.location;
  late List<HomeActivity> _activities = widget.args.activities;
  HomeLocation? _pendingSearchLocation;
  Timer? _searchDebounce;
  List<MeetingLocationSuggestion> _locationResults = const [];
  bool _hasLocationSearch = false;
  bool _isLocationSearching = false;
  bool _isSearching = false;
  bool _isLocating = false;
  String? _locationSearchError;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.greenDeep,
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
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MapSearchField(
                            controller: _searchController,
                            cityName: _location.cityName,
                            isSearching: _isLocationSearching,
                            onChanged: _onSearchChanged,
                            onSubmitted: _searchLocationText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: 'Filters',
                          onPressed: () => context.go(AppRoutes.home),
                          style: IconButton.styleFrom(
                            backgroundColor: colors.card.withValues(alpha: .96),
                            foregroundColor: colors.ink,
                            fixedSize: const Size.square(58),
                            elevation: 10,
                            shadowColor: colors.ink.withValues(alpha: .18),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 22),
                        ),
                      ],
                    ),
                    if (_shouldShowLocationResults) ...[
                      const SizedBox(height: TochSpacing.xs),
                      _LocationSearchResults(
                        isLoading: _isLocationSearching,
                        hasSearched: _hasLocationSearch,
                        errorMessage: _locationSearchError,
                        results: _locationResults,
                        onSelected: _selectSearchResult,
                      ),
                    ],
                    const SizedBox(height: 16),
                    const _MapFilterChips(),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 26,
              bottom: 218,
              child: SafeArea(
                top: false,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: colors.card.withValues(alpha: .96),
                    foregroundColor: colors.green,
                    fixedSize: const Size.square(52),
                    elevation: 12,
                    shadowColor: colors.ink.withValues(alpha: .18),
                  ),
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
                top: 154,
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
              left: 30,
              right: 30,
              bottom: 124,
              child: SafeArea(
                top: false,
                child: _MapActivityTray(
                  activities: _activities,
                  onActivityUpdated: _replaceActivity,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HomeBottomNav(
                location: _location,
                selected: HomeNavDestination.map,
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

    await _loadActivitiesForLocation(searchLocation);
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
        showTochSnackBar(
          context,
          failure.message,
          type: TochSnackBarType.error,
        );
      },
      (location) async {
        setState(() {
          _isLocating = false;
        });
        await _loadActivitiesForLocation(location);
      },
    );
  }

  bool get _shouldShowLocationResults =>
      _isLocationSearching ||
      _locationSearchError != null ||
      _locationResults.isNotEmpty ||
      _hasLocationSearch && _searchController.text.trim().length >= 3;

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _hasLocationSearch = false;
        _isLocationSearching = false;
        _locationSearchError = null;
        _locationResults = const [];
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _searchLocationText(query);
    });
  }

  Future<void> _searchLocationText([String? submittedQuery]) async {
    final query = (submittedQuery ?? _searchController.text).trim();
    if (query.length < 3 || _isLocationSearching) {
      return;
    }

    setState(() {
      _hasLocationSearch = true;
      _isLocationSearching = true;
      _locationSearchError = null;
    });

    final result = await _searchLocations(
      SearchMeetingLocationsParams(query: query, nearLocation: _location),
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isLocationSearching = false;
          _locationSearchError = failure.message;
          _locationResults = const [];
        });
      },
      (results) {
        setState(() {
          _isLocationSearching = false;
          _locationSearchError = null;
          _locationResults = results;
        });
      },
    );
  }

  Future<void> _selectSearchResult(MeetingLocationSuggestion suggestion) async {
    _searchController.text = suggestion.addressLine;
    FocusScope.of(context).unfocus();
    setState(() {
      _hasLocationSearch = false;
      _locationSearchError = null;
      _locationResults = const [];
    });
    await _loadActivitiesForLocation(
      HomeLocation(
        cityName: suggestion.city.isEmpty ? suggestion.label : suggestion.city,
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
      ),
    );
  }

  Future<void> _loadActivitiesForLocation(HomeLocation location) async {
    if (_isSearching) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final result = await _getHomeFeed(
      GetHomeFeedParams(
        location: location,
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
        showTochSnackBar(
          context,
          failure.message,
          type: TochSnackBarType.error,
        );
      },
      (feed) {
        setState(() {
          _location = location;
          _activities = feed.activities;
          _pendingSearchLocation = null;
          _isSearching = false;
        });
      },
    );
  }

  void _replaceActivity(HomeActivity updatedActivity) {
    setState(() {
      _activities = [
        for (final activity in _activities)
          if (activity.id == updatedActivity.id) updatedActivity else activity,
      ];
    });
  }
}

class _MapFilterChips extends StatelessWidget {
  const _MapFilterChips();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MapFilterPill(label: 'Nu live', active: true, showDot: true),
          SizedBox(width: 10),
          _MapFilterPill(label: 'Vandaag'),
          SizedBox(width: 10),
          _MapFilterPill(label: 'Dit weekend'),
        ],
      ),
    );
  }
}

class _MapFilterPill extends StatelessWidget {
  const _MapFilterPill({
    required this.label,
    this.active = false,
    this.showDot = false,
  });

  final String label;
  final bool active;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final background = active
        ? colors.green
        : colors.card.withValues(alpha: .94);
    final foreground = active ? Colors.white : colors.ink;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TochRadius.pill),
        boxShadow: active
            ? TochShadows.button(colors)
            : TochShadows.card(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 9),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isMeaningfullyDifferent(HomeLocation left, HomeLocation right) {
  final latitudeDelta = (left.latitude - right.latitude).abs();
  final longitudeDelta = (left.longitude - right.longitude).abs();
  return latitudeDelta > 0.003 || longitudeDelta > 0.003;
}

class _MapSearchField extends StatelessWidget {
  const _MapSearchField({
    required this.controller,
    required this.cityName,
    required this.isSearching,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String cityName;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: .10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Zoek in $cityName',
          hintStyle: TextStyle(
            color: colors.green700.withValues(alpha: .72),
            fontWeight: FontWeight.w900,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: colors.ink3, size: 23),
          suffixIcon: isSearching
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.green,
                    ),
                  ),
                )
              : IconButton(
                  tooltip: 'Zoeken',
                  onPressed: () => onSubmitted(controller.text),
                  icon: Icon(Icons.arrow_forward_rounded, color: colors.green),
                ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 17,
          ),
        ),
      ),
    );
  }
}

class _LocationSearchResults extends StatelessWidget {
  const _LocationSearchResults({
    required this.isLoading,
    required this.hasSearched,
    required this.errorMessage,
    required this.results,
    required this.onSelected,
  });

  final bool isLoading;
  final bool hasSearched;
  final String? errorMessage;
  final List<MeetingLocationSuggestion> results;
  final ValueChanged<MeetingLocationSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: .12),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.toch;
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(TochSpacing.md),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: TochSpacing.sm),
            Expanded(child: Text('Locaties zoeken...')),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.orange),
            const SizedBox(width: TochSpacing.sm),
            Expanded(child: Text(errorMessage!)),
          ],
        ),
      );
    }

    if (hasSearched && results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(TochSpacing.md),
        child: Row(
          children: [
            Icon(Icons.location_off_rounded),
            SizedBox(width: TochSpacing.sm),
            Expanded(
              child: Text(
                'Geen locatie gevonden. Probeer een adres of plaatsnaam.',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.line),
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          dense: true,
          leading: Icon(Icons.place_rounded, color: colors.green),
          title: Text(
            result.label.isEmpty ? result.addressLine : result.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            [
              if (result.addressLine.isNotEmpty) result.addressLine,
              if (result.postcode != null) result.postcode!,
            ].join(' - '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onSelected(result),
        );
      },
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
  const _MapActivityTray({
    required this.activities,
    required this.onActivityUpdated,
  });

  final List<HomeActivity> activities;
  final ValueChanged<HomeActivity> onActivityUpdated;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final activity = activities.isEmpty ? null : activities.first;

    if (activity == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(TochRadius.lg),
          border: Border.all(color: colors.line),
          boxShadow: TochShadows.raised(colors),
        ),
        child: const Padding(
          padding: EdgeInsets.all(TochSpacing.md),
          child: Text('Geen activiteiten binnen deze filters.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: colors.card.withValues(alpha: .97),
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              final updatedActivity = await context.push<HomeActivity>(
                AppRoutes.activityDetailPath(activity.id),
                extra: activity,
              );
              if (!context.mounted || updatedActivity == null) {
                return;
              }
              onActivityUpdated(updatedActivity);
            },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: TochShadows.raised(colors),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: activity.category.backgroundColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: SizedBox.square(
                        dimension: 58,
                        child: Icon(
                          activity.category.icon,
                          color: activity.category.color,
                          size: 27,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: colors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  activity.distanceLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: colors.orange,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                  height: 1.06,
                                ),
                          ),
                          const SizedBox(height: 7),
                          _MapParticipantSummary(activity: activity),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 108,
                      child: FilledButton(
                        onPressed: () async {
                          final updatedActivity = await context
                              .push<HomeActivity>(
                                AppRoutes.activityDetailPath(activity.id),
                                extra: activity,
                              );
                          if (!context.mounted || updatedActivity == null) {
                            return;
                          }
                          onActivityUpdated(updatedActivity);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 50),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        child: Text(
                          activity.isJoined ? 'Je gaat' : 'Aansluiten',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapParticipantSummary extends StatelessWidget {
  const _MapParticipantSummary({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final avatarLabels = _avatarLabels(activity);

    return Row(
      children: [
        SizedBox(
          width: 54,
          height: 22,
          child: Stack(
            children: [
              for (var index = 0; index < avatarLabels.length; index++)
                Positioned(
                  left: index * 16,
                  child: _MapMiniAvatar(label: avatarLabels[index]),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            activity.spotsLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.green700.withValues(alpha: .72),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapMiniAvatar extends StatelessWidget {
  const _MapMiniAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: colors.card, width: 1.5),
      ),
      child: SizedBox.square(
        dimension: 22,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _avatarLabels(HomeActivity activity) {
  final labels = activity.participants
      .take(3)
      .map((participant) => participant.initials.trim())
      .where((initials) => initials.isNotEmpty)
      .toList();
  if (labels.isNotEmpty) {
    return labels;
  }
  final hostInitials = _initialsFor(
    activity.hostFullName.trim().isEmpty
        ? activity.hostName
        : activity.hostFullName,
  );
  return hostInitials.isEmpty ? const [] : [hostInitials];
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(0, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
