import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/pip_mascot.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_home_feed.dart';
import '../widgets/home_activity_card.dart';

class ActivitySearchPage extends StatefulWidget {
  const ActivitySearchPage({super.key});

  @override
  State<ActivitySearchPage> createState() => _ActivitySearchPageState();
}

class _ActivitySearchPageState extends State<ActivitySearchPage> {
  static const _recentSearches = ['Avondvissen', 'Koffie centrum', 'Hardlopen'];

  static const _categories = [
    _SearchCategory('Vissen', Icons.phishing_rounded, 'vissen'),
    _SearchCategory('Wandelen', Icons.directions_walk_rounded, 'wandelen'),
    _SearchCategory('Koffie', Icons.local_cafe_rounded, 'koffie'),
    _SearchCategory('Sport', Icons.sports_basketball_rounded, 'sport'),
    _SearchCategory('Gaming', Icons.sports_esports_rounded, 'gaming'),
    _SearchCategory('Motor', Icons.two_wheeler_rounded, 'motor'),
    _SearchCategory('Bordspellen', Icons.casino_rounded, 'bordspel'),
    _SearchCategory('Foto', Icons.photo_camera_rounded, 'foto'),
    _SearchCategory('Sociaal', Icons.groups_rounded, 'sociaal'),
  ];

  final _controller = TextEditingController();
  final _getCurrentLocation = sl<GetCurrentLocation>();
  final _getHomeFeed = sl<GetHomeFeed>();

  HomeLocation? _location;
  List<HomeActivity> _results = const [];
  String? _activeQuery;
  String? _errorMessage;
  bool _isSearching = false;
  int _requestSerial = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitSearch([String? rawQuery]) async {
    final query = (rawQuery ?? _controller.text).trim();
    if (query.isEmpty) {
      setState(() {
        _activeQuery = null;
        _results = const [];
        _errorMessage = 'Typ eerst waar je zin in hebt.';
      });
      return;
    }

    if (rawQuery != null && rawQuery != _controller.text) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    final serial = ++_requestSerial;
    setState(() {
      _activeQuery = query;
      _results = const [];
      _errorMessage = null;
      _isSearching = true;
    });

    var location = _location;
    if (location == null) {
      final locationResult = await _getCurrentLocation(
        const GetCurrentLocationParams(forceRefresh: false),
      );
      if (!mounted || serial != _requestSerial) {
        return;
      }
      location = locationResult.fold((failure) {
        setState(() {
          _isSearching = false;
          _errorMessage = failure.message;
        });
        return null;
      }, (value) => value);
      if (location == null) {
        return;
      }
      _location = location;
    }

    final feedResult = await _getHomeFeed(
      GetHomeFeedParams(
        location: location,
        filters: const HomeFeedFilters(distanceKm: 50, sort: homeSortStartTime),
        forceRefresh: true,
      ),
    );

    if (!mounted || serial != _requestSerial) {
      return;
    }

    feedResult.fold(
      (failure) {
        setState(() {
          _isSearching = false;
          _errorMessage = failure.message;
        });
      },
      (feed) {
        final matches = feed.activities.where((activity) {
          return _matchesActivity(activity, query);
        }).toList()..sort(_sortSearchResults);

        setState(() {
          _isSearching = false;
          _results = matches;
          _errorMessage = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: context.pop,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: colors.ink,
                        ),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      Expanded(
                        child: _SearchField(
                          controller: _controller,
                          isSearching: _isSearching,
                          onSubmitted: _submitSearch,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _isSearching
                      ? LinearProgressIndicator(
                          key: const ValueKey('search-progress'),
                          minHeight: 2,
                          color: colors.green,
                          backgroundColor: colors.green100,
                        )
                      : const SizedBox(key: ValueKey('search-progress-empty')),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                    children: [
                      const _SearchEmptyHero(),
                      _SearchStatus(
                        query: _activeQuery,
                        isSearching: _isSearching,
                        errorMessage: _errorMessage,
                        resultCount: _results.length,
                        onRetry: _activeQuery == null
                            ? null
                            : () => _submitSearch(_activeQuery),
                      ),
                      if (_results.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        for (final activity in _results) ...[
                          HomeActivityCard(
                            activity: activity,
                            onPressed: () {
                              context.push(
                                AppRoutes.activityDetailPath(activity.id),
                                extra: activity,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                      if (!_isSearching) ...[
                        const SizedBox(height: 8),
                        const TochSectionLabel('Recent'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final search in _recentSearches)
                              TochPill(
                                label: search,
                                icon: Icons.history_rounded,
                                onTap: () => _submitSearch(search),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const TochSectionLabel('Categorieen'),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: .95,
                          children: [
                            for (final category in _categories)
                              _CategorySearchTile(
                                category: category,
                                onTap: () => _submitSearch(category.label),
                              ),
                          ],
                        ),
                      ],
                    ],
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isSearching,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isSearching;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.pill),
        boxShadow: TochShadows.card(colors),
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        enabled: !isSearching,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: 'Zoek een activiteit...',
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: colors.ink3, size: 20),
          suffixIcon: isSearching
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 16,
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
        ),
      ),
    );
  }
}

class _SearchStatus extends StatelessWidget {
  const _SearchStatus({
    required this.query,
    required this.isSearching,
    required this.errorMessage,
    required this.resultCount,
    required this.onRetry,
  });

  final String? query;
  final bool isSearching;
  final String? errorMessage;
  final int resultCount;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final activeQuery = query;

    if (isSearching && activeQuery != null) {
      return _SearchNotice(
        icon: Icons.search_rounded,
        text: 'Zoeken naar "$activeQuery"...',
      );
    }

    if (errorMessage != null) {
      return _SearchNotice(
        icon: Icons.error_outline_rounded,
        text: errorMessage!,
        actionLabel: onRetry == null ? null : 'Opnieuw proberen',
        onAction: onRetry,
      );
    }

    if (activeQuery == null) {
      return const SizedBox.shrink();
    }

    if (resultCount == 0) {
      return _SearchNotice(
        icon: Icons.travel_explore_rounded,
        text: 'Geen resultaten voor "$activeQuery".',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        resultCount == 1 ? '1 resultaat' : '$resultCount resultaten',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colors.ink3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SearchNotice extends StatelessWidget {
  const _SearchNotice({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.md),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.ink2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _SearchEmptyHero extends StatelessWidget {
  const _SearchEmptyHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.green100,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const SizedBox.square(
              dimension: 96,
              child: Center(
                child: PipMascot(expression: PipExpression.thinking, size: 72),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Waar heb je zin in?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Zoek op activiteit, plek of mens - of kies een categorie hieronder.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.ink3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySearchTile extends StatelessWidget {
  const _CategorySearchTile({required this.category, required this.onTap});

  final _SearchCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final skin = tochCategorySkin(category.skinKey);

    return Material(
      color: skin.tint,
      borderRadius: BorderRadius.circular(TochRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: skin.color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: SizedBox.square(
                  dimension: 42,
                  child: Icon(category.icon, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.ink,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCategory {
  const _SearchCategory(this.label, this.icon, this.skinKey);

  final String label;
  final IconData icon;
  final String skinKey;
}

bool _matchesActivity(HomeActivity activity, String query) {
  final needle = _normalizeSearchText(query);
  final haystack = [
    activity.title,
    activity.description,
    activity.locationName,
    activity.meetingPoint,
    activity.hostName,
    activity.hostFullName,
    activity.category.label,
  ].map(_normalizeSearchText).join(' ');
  return haystack.contains(needle);
}

int _sortSearchResults(HomeActivity a, HomeActivity b) {
  final aStart = a.startsAt;
  final bStart = b.startsAt;
  if (aStart != null && bStart != null) {
    return aStart.compareTo(bStart);
  }
  if (aStart != null) {
    return -1;
  }
  if (bStart != null) {
    return 1;
  }
  return a.distanceKm.compareTo(b.distanceKm);
}

String _normalizeSearchText(String value) {
  return value.toLowerCase().trim();
}
