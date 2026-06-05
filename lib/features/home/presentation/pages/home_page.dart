import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/home_bloc.dart';
import '../widgets/home_activity_card.dart';
import '../widgets/home_bottom_nav.dart';
import '../widgets/home_category_strip.dart';
import '../widgets/home_distance_filter.dart';
import '../widgets/home_feed_summary.dart';
import '../widgets/home_header.dart';
import '../widgets/home_map_preview.dart';
import '../widgets/home_time_filters.dart';

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
                  onLocationTap: () {
                    context.read<HomeBloc>().add(const HomeLocationRequested());
                  },
                ),
                HomeTimeFilters(
                  filters: state.feed.timeFilters,
                  selectedFilter: state.selectedTimeFilter,
                  onSelected: (filter) {
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
                HomeCategoryStrip(
                  categories: state.feed.categories,
                  selectedCategoryId: state.selectedCategoryId,
                  onSelected: (categoryId) {
                    context.read<HomeBloc>().add(
                      HomeCategorySelected(categoryId),
                    );
                  },
                ),
                HomeMapPreview(activityCount: activities.length),
                HomeFeedSummary(activityCount: activities.length),
                if (activities.isEmpty)
                  const _EmptyActivities()
                else
                  ...activities.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                      child: HomeActivityCard(
                        activity: activity,
                        onProfilePressed: (profileId) {
                          context.push(AppRoutes.profilePath(profileId));
                        },
                        onPressed: () {
                          context.push(
                            AppRoutes.activityDetailPath(activity.id),
                            extra: activity,
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
                          const HomeLocationRequested(),
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
  const _EmptyActivities();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.toch.card,
          borderRadius: BorderRadius.circular(TochRadius.lg),
          border: Border.all(color: context.toch.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TochSpacing.lg),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, color: context.toch.green),
              const SizedBox(height: TochSpacing.sm),
              Text(
                'Geen activiteiten gevonden',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: TochSpacing.xs),
              Text(
                'Probeer een andere categorie of periode.',
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
