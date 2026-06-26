import 'package:flutter/material.dart';

import '../../../../app/widgets/toch_design_system.dart';

class HomeDiscoveryControls extends StatelessWidget {
  const HomeDiscoveryControls({
    required this.timeFilters,
    required this.selectedTimeFilter,
    required this.onTimeSelected,
    super.key,
  });

  final List<String> timeFilters;
  final String selectedTimeFilter;
  final ValueChanged<String> onTimeSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
        scrollDirection: Axis.horizontal,
        itemCount: timeFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = timeFilters[index];
          final selected = filter == selectedTimeFilter;
          return TochPill(
            label: filter,
            active: selected,
            onTap: () => onTimeSelected(filter),
          );
        },
      ),
    );
  }
}
