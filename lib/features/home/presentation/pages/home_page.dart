import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/usecases/get_activity_agenda.dart';
import '../bloc/home_bloc.dart';
import 'create_activity_page.dart';
import '../widgets/home_activity_card.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_discovery_controls.dart';
import '../widgets/home_distance_filter.dart';
import '../widgets/home_feed_summary.dart';
import '../widgets/home_filter_sheet.dart';
import '../widgets/home_header.dart';
import '../widgets/home_map_preview.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: BlocListener<HomeBloc, HomeState>(
            listenWhen: (previous, current) {
              final previousError = previous is HomeLoaded
                  ? previous.participationError
                  : null;
              final currentError = current is HomeLoaded
                  ? current.participationError
                  : null;
              final previousConfirmation = previous is HomeLoaded
                  ? previous.joinedActivityConfirmation
                  : null;
              final currentConfirmation = current is HomeLoaded
                  ? current.joinedActivityConfirmation
                  : null;
              return currentError != null && currentError != previousError ||
                  currentConfirmation != null &&
                      currentConfirmation != previousConfirmation;
            },
            listener: (context, state) {
              if (state is! HomeLoaded) {
                return;
              }
              final error = state.participationError;
              if (error != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
                return;
              }

              final confirmation = state.joinedActivityConfirmation;
              if (confirmation == null) {
                return;
              }
              context.read<HomeBloc>().add(
                const HomeParticipationConfirmationConsumed(),
              );
              context.push(
                AppRoutes.activityJoinConfirmationPath(confirmation.id),
                extra: confirmation,
              );
            },
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                return switch (state) {
                  HomeInitial() ||
                  HomeLoading() ||
                  HomeResolvingLocation() => const _LocationLoading(),
                  HomeLoadingFeed(:final location) => _FeedLoading(
                    cityName: location.cityName,
                  ),
                  HomeLocationBlocked(:final message) => _LocationBlocked(
                    message: message,
                  ),
                  HomeError(:final message) => _HomeError(message: message),
                  HomeLoaded() => _HomeFeed(state: state),
                };
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeFeed extends StatelessWidget {
  const _HomeFeed({required this.state});

  final HomeLoaded state;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<HomeBloc>();
    final current = bloc.state;
    if (current is! HomeLoaded || current.isRefreshing) {
      return;
    }

    final refreshCompleted = bloc.stream.firstWhere((nextState) {
      return nextState is HomeLoaded && !nextState.isRefreshing ||
          nextState is HomeError ||
          nextState is HomeLocationBlocked;
    });

    bloc.add(const HomeRefreshRequested());
    await refreshCompleted;
  }

  Future<void> _showFilters(BuildContext context) async {
    final filters = await showHomeFilterSheet(
      context: context,
      filters: state.filters,
      categories: state.feed.categories,
    );
    if (!context.mounted || filters == null) {
      return;
    }
    context.read<HomeBloc>().add(HomeFiltersApplied(filters));
  }

  @override
  Widget build(BuildContext context) {
    final activities = state.visibleActivities;
    final colors = context.toch;

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: colors.green,
            backgroundColor: colors.card,
            displacement: 28,
            strokeWidth: 3,
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 128),
              children: [
                HomeHeader(
                  locationName: state.feed.locationName,
                  hasActiveFilters: state.filters.hasAdvancedFilters,
                  onLocationTap: () {
                    context.read<HomeBloc>().add(
                      const HomeLocationRequested(forceRefresh: true),
                    );
                  },
                  onFilterTap: () => _showFilters(context),
                ),
                HomeDiscoveryControls(
                  timeFilters: state.feed.timeFilters,
                  selectedTimeFilter: state.selectedTimeFilter,
                  onTimeSelected: (filter) {
                    context.read<HomeBloc>().add(
                      HomeTimeFilterSelected(filter),
                    );
                  },
                ),
                HomeDistanceFilter(
                  distances: state.feed.distanceFilters,
                  selectedDistanceKm: state.selectedDistanceKm,
                  onSelected: (distanceKm) {
                    context.read<HomeBloc>().add(
                      HomeDistanceSelected(distanceKm),
                    );
                  },
                ),
                HomeFilterButton(
                  hasActiveFilters: state.filters.hasAdvancedFilters,
                  onPressed: () => _showFilters(context),
                ),
                HomeMapPreview(
                  location: state.location,
                  activities: activities,
                  filters: state.filters,
                ),
                const _HostedActivitiesOverview(),
                HomeFeedSummary(activityCount: activities.length),
                if (activities.isEmpty)
                  _EmptyActivities(
                    location: state.location,
                    categories: state.feed.categories,
                  )
                else
                  ...activities.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                      child: HomeActivityCard(
                        activity: activity,
                        isJoinPending: state.isParticipationPending(
                          activity.id,
                        ),
                        onJoinPressed: () {
                          context.read<HomeBloc>().add(
                            HomeActivityParticipationToggled(activity.id),
                          );
                        },
                        onProfilePressed: (profileId) {
                          context.push(AppRoutes.profilePath(profileId));
                        },
                        onPressed: () async {
                          final updatedActivity = await context
                              .push<HomeActivity>(
                                AppRoutes.activityDetailPath(activity.id),
                                extra: activity,
                              );
                          if (!context.mounted || updatedActivity == null) {
                            return;
                          }
                          context.read<HomeBloc>().add(
                            HomeActivityUpdated(updatedActivity),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: HomeBottomNav(
            location: state.location,
            categories: state.feed.categories,
          ),
        ),
      ],
    );
  }
}

class _HostedActivitiesOverview extends StatefulWidget {
  const _HostedActivitiesOverview();

  @override
  State<_HostedActivitiesOverview> createState() =>
      _HostedActivitiesOverviewState();
}

class _HostedActivitiesOverviewState extends State<_HostedActivitiesOverview> {
  final GetActivityAgenda _getActivityAgenda = sl();

  List<HomeActivity> _hostedActivities = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHostedActivities();
  }

  Future<void> _loadHostedActivities() async {
    final result = await _getActivityAgenda(const NoParams());
    if (!mounted) {
      return;
    }

    result.fold(
      (_) {
        setState(() {
          _hostedActivities = const [];
          _isLoading = false;
        });
      },
      (agenda) {
        setState(() {
          _hostedActivities = _sortHostedActivities(
            agenda.activeHostedActivities,
          );
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _openActivity(HomeActivity activity) async {
    final updatedActivity = await context.push<HomeActivity>(
      AppRoutes.activityDetailPath(activity.id),
      extra: activity,
    );
    if (!mounted || updatedActivity == null) {
      return;
    }

    setState(() {
      _hostedActivities = _sortHostedActivities([
        for (final hosted in _hostedActivities)
          if (hosted.id == updatedActivity.id) updatedActivity else hosted,
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _hostedActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    return _HostedActivitiesSection(
      activities: _hostedActivities,
      onActivityPressed: _openActivity,
      onAgendaPressed: () => context.push(AppRoutes.activityAgenda),
    );
  }
}

List<HomeActivity> _sortHostedActivities(Iterable<HomeActivity> activities) {
  return activities.where((activity) => !activity.isCompleted).toList()
    ..sort((left, right) {
      final leftStart = left.startsAt;
      final rightStart = right.startsAt;
      if (leftStart == null && rightStart == null) {
        return 0;
      }
      if (leftStart == null) {
        return 1;
      }
      if (rightStart == null) {
        return -1;
      }
      return leftStart.compareTo(rightStart);
    });
}

class _HostedActivitiesSection extends StatelessWidget {
  const _HostedActivitiesSection({
    required this.activities,
    required this.onActivityPressed,
    required this.onAgendaPressed,
  });

  final List<HomeActivity> activities;
  final ValueChanged<HomeActivity> onActivityPressed;
  final VoidCallback onAgendaPressed;

  @override
  Widget build(BuildContext context) {
    final visibleActivities = activities.take(2).toList();
    final remainingCount = activities.length - visibleActivities.length;
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Jij organiseert',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onAgendaPressed,
                style: TextButton.styleFrom(
                  foregroundColor: colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Agenda'),
              ),
            ],
          ),
          const SizedBox(height: TochSpacing.xs),
          for (final activity in visibleActivities)
            Padding(
              padding: const EdgeInsets.only(bottom: TochSpacing.xs),
              child: _HostedActivityTile(
                activity: activity,
                onPressed: () => onActivityPressed(activity),
              ),
            ),
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+$remainingCount meer in je agenda',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.green700.withValues(alpha: .72),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HostedActivityTile extends StatelessWidget {
  const _HostedActivityTile({required this.activity, required this.onPressed});

  final HomeActivity activity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final borderRadius = BorderRadius.circular(TochRadius.md);

    return Material(
      color: colors.card,
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
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: activity.category.backgroundColor,
                    borderRadius: BorderRadius.circular(TochRadius.sm),
                  ),
                  child: SizedBox.square(
                    dimension: 38,
                    child: Icon(
                      activity.category.icon,
                      color: activity.category.color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: TochSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${activity.dateLabel} · ${activity.timeLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.green700.withValues(alpha: .72),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TochSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.green700.withValues(alpha: .68),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationLoading extends StatelessWidget {
  const _LocationLoading();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: context.toch.green),
              const SizedBox(height: TochSpacing.lg),
              Text(
                'Je locatie ophalen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: TochSpacing.xs),
              Text(
                'We gebruiken je plaats om activiteiten dichtbij te tonen.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading({required this.cityName});

  final String cityName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: context.toch.green),
              const SizedBox(height: TochSpacing.lg),
              Text(
                'Activiteiten laden',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: TochSpacing.xs),
              Text(
                'We zoeken rond $cityName.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationBlocked extends StatelessWidget {
  const _LocationBlocked({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.xl),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(TochRadius.lg),
              border: Border.all(color: colors.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(TochSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.green100,
                      borderRadius: BorderRadius.circular(TochRadius.lg),
                    ),
                    child: SizedBox.square(
                      dimension: 64,
                      child: Icon(
                        Icons.location_off_rounded,
                        color: colors.green,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: TochSpacing.lg),
                  Text(
                    'Locatie is nodig',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: TochSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: TochSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<HomeBloc>().add(
                          const HomeLocationRequested(forceRefresh: true),
                        );
                      },
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('Locatie toestaan'),
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

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: context.toch.orange,
                size: 42,
              ),
              const SizedBox(height: TochSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyActivities extends StatelessWidget {
  const _EmptyActivities({required this.location, required this.categories});

  final HomeLocation location;
  final List<HomeCategory> categories;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.green, const Color(0xFF163D2C)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: .10),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 14),
              ),
              const SizedBox(height: TochSpacing.md),
              Text(
                'Rustig in de buurt?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: TochSpacing.xs),
              Text(
                'Soms gebeurt er nog niet veel vlakbij. Plaats zelf iets - koffie, wandelen of iets kleins. Grote kans dat iemand toch meegaat.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .82),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: TochSpacing.md),
              ElevatedButton(
                onPressed: categories.isEmpty
                    ? null
                    : () {
                        context.push(
                          AppRoutes.createActivity,
                          extra: CreateActivityPageArgs(
                            location: location,
                            categories: categories,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.orange,
                  foregroundColor: const Color(0xFF163D2C),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Plaats een activiteit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
