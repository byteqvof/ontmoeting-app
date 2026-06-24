import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

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
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.green100,
          borderRadius: BorderRadius.circular(TochRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: timeFilters.map((filter) {
              final selected = filter == selectedTimeFilter;
              return Expanded(
                child: TextButton(
                  onPressed: () => onTimeSelected(filter),
                  style: TextButton.styleFrom(
                    foregroundColor: selected ? Colors.white : colors.green,
                    backgroundColor: selected
                        ? colors.green
                        : Colors.transparent,
                    minimumSize: const Size(0, 36),
                    padding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: FittedBox(child: Text(filter)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
