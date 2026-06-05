import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

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
    final colors = context.toch;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
        scrollDirection: Axis.horizontal,
        itemCount: distances.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final distance = distances[index];
          final selected = distance == selectedDistanceKm;

          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            avatar: Icon(
              Icons.near_me_rounded,
              size: 16,
              color: selected ? Colors.white : colors.green,
            ),
            label: Text('$distance km'),
            onSelected: (_) => onSelected(distance),
            selectedColor: colors.green,
            backgroundColor: colors.card,
            side: BorderSide(color: selected ? colors.green : colors.line),
            labelStyle: TextStyle(
              color: selected ? Colors.white : colors.ink,
              fontWeight: FontWeight.w900,
            ),
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}
