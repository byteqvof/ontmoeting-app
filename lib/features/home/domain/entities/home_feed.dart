import 'package:equatable/equatable.dart';

import 'home_activity.dart';
import 'home_category.dart';

class HomeFeed extends Equatable {
  const HomeFeed({
    required this.locationName,
    required this.selectedTimeFilter,
    required this.selectedDistanceKm,
    required this.timeFilters,
    required this.distanceFilters,
    required this.categories,
    required this.activities,
  });

  final String locationName;
  final String selectedTimeFilter;
  final int selectedDistanceKm;
  final List<String> timeFilters;
  final List<int> distanceFilters;
  final List<HomeCategory> categories;
  final List<HomeActivity> activities;

  HomeFeed copyWith({
    String? locationName,
    String? selectedTimeFilter,
    int? selectedDistanceKm,
    List<String>? timeFilters,
    List<int>? distanceFilters,
    List<HomeCategory>? categories,
    List<HomeActivity>? activities,
  }) {
    return HomeFeed(
      locationName: locationName ?? this.locationName,
      selectedTimeFilter: selectedTimeFilter ?? this.selectedTimeFilter,
      selectedDistanceKm: selectedDistanceKm ?? this.selectedDistanceKm,
      timeFilters: timeFilters ?? this.timeFilters,
      distanceFilters: distanceFilters ?? this.distanceFilters,
      categories: categories ?? this.categories,
      activities: activities ?? this.activities,
    );
  }

  @override
  List<Object?> get props => [
    locationName,
    selectedTimeFilter,
    selectedDistanceKm,
    timeFilters,
    distanceFilters,
    categories,
    activities,
  ];
}
