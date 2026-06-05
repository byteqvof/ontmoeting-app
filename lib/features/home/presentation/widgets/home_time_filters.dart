import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class HomeTimeFilters extends StatelessWidget {
  const HomeTimeFilters({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF2EEE5),
          borderRadius: BorderRadius.circular(TochRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: filters.map((filter) {
              final selected = filter == selectedFilter;
              return Expanded(
                child: TextButton(
                  onPressed: () => onSelected(filter),
                  style: TextButton.styleFrom(
                    foregroundColor: selected
                        ? colors.ink
                        : colors.green700.withValues(alpha: .72),
                    backgroundColor: selected
                        ? colors.card
                        : Colors.transparent,
                    minimumSize: const Size(0, 34),
                    padding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(filter),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
