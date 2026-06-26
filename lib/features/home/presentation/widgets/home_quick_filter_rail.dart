import 'package:flutter/material.dart';

import '../../../../app/widgets/toch_design_system.dart';
import '../../domain/entities/home_category.dart';

class HomeQuickFilterRail extends StatelessWidget {
  const HomeQuickFilterRail({
    required this.timeFilters,
    required this.selectedTimeFilter,
    required this.onTimeSelected,
    required this.distances,
    required this.selectedDistanceKm,
    required this.onDistanceSelected,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onAdvancedFilters,
    super.key,
  });

  final List<String> timeFilters;
  final String selectedTimeFilter;
  final ValueChanged<String> onTimeSelected;
  final List<int> distances;
  final int selectedDistanceKm;
  final ValueChanged<int> onDistanceSelected;
  final List<HomeCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onAdvancedFilters;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories
        .where((category) => category.id != 'all')
        .take(4)
        .toList();
    final nearestDistance = distances.isEmpty ? selectedDistanceKm : distances.first;

    final chips = <Widget>[
      for (final filter in timeFilters.take(2))
        TochPill(
          label: filter,
          active: filter == selectedTimeFilter,
          onTap: () => onTimeSelected(filter),
        ),
      TochPill(
        label: 'Dichtbij',
        active: selectedDistanceKm == nearestDistance,
        onTap: () => onDistanceSelected(nearestDistance),
      ),
      TochPill(
        label: 'Plek vrij',
        active: false,
        onTap: onAdvancedFilters,
      ),
      for (final category in visibleCategories)
        TochPill(
          label: category.label,
          icon: category.icon,
          active: selectedCategoryId == category.id,
          onTap: () => onCategorySelected(category.id),
        ),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => chips[index],
      ),
    );
  }
}
