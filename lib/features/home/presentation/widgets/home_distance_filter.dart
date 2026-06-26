import 'package:flutter/material.dart';

import '../../../../app/widgets/toch_design_system.dart';

class HomeDistanceFilter extends StatelessWidget {
  const HomeDistanceFilter({
    required this.distances,
    required this.selectedDistanceKm,
    required this.onSelected,
    super.key,
  });

  final List<int> distances;
  final int selectedDistanceKm;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
        scrollDirection: Axis.horizontal,
        itemCount: distances.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final distance = distances[index];
          return TochPill(
            label: '$distance km',
            icon: Icons.near_me_rounded,
            active: distance == selectedDistanceKm,
            onTap: () => onSelected(distance),
          );
        },
      ),
    );
  }
}
