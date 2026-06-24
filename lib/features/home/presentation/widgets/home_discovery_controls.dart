import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_category.dart';

class HomeDiscoveryControls extends StatefulWidget {
  const HomeDiscoveryControls({
    required this.timeFilters,
    required this.selectedTimeFilter,
    required this.onTimeSelected,
    required this.distances,
    required this.selectedDistanceKm,
    required this.onDistanceSelected,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onCategorySelected,
    required this.hasActiveFilters,
    required this.onAdvancedFiltersPressed,
    super.key,
  });

  final List<String> timeFilters;
  final String selectedTimeFilter;
  final ValueChanged<String> onTimeSelected;
  final List<int> distances;
  final int selectedDistanceKm;
  final ValueChanged<int> onDistanceSelected;
  final List<HomeCategory> categories;
  final List<String> selectedCategoryIds;
  final ValueChanged<String> onCategorySelected;
  final bool hasActiveFilters;
  final VoidCallback onAdvancedFiltersPressed;

  @override
  State<HomeDiscoveryControls> createState() => _HomeDiscoveryControlsState();
}

class _HomeDiscoveryControlsState extends State<HomeDiscoveryControls>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.green100,
                    borderRadius: BorderRadius.circular(TochRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: widget.timeFilters.map((filter) {
                        final selected = filter == widget.selectedTimeFilter;
                        return Expanded(
                          child: TextButton(
                            onPressed: () => widget.onTimeSelected(filter),
                            style: TextButton.styleFrom(
                              foregroundColor: selected
                                  ? Colors.white
                                  : colors.green,
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
              ),
              const SizedBox(width: 8),
              _FilterToggleButton(
                expanded: _expanded,
                hasActiveFilters: widget.hasActiveFilters,
                onPressed: () {
                  setState(() => _expanded = !_expanded);
                },
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _ExpandedFilterChips(
                    distances: widget.distances,
                    selectedDistanceKm: widget.selectedDistanceKm,
                    onDistanceSelected: widget.onDistanceSelected,
                    categories: widget.categories,
                    selectedCategoryIds: widget.selectedCategoryIds,
                    onCategorySelected: widget.onCategorySelected,
                    onAdvancedFiltersPressed: widget.onAdvancedFiltersPressed,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({
    required this.expanded,
    required this.hasActiveFilters,
    required this.onPressed,
  });

  final bool expanded;
  final bool hasActiveFilters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return SizedBox(
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              expanded ? Icons.keyboard_arrow_up_rounded : Icons.tune_rounded,
              size: 18,
            ),
            label: const Text('Filter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.ink,
              backgroundColor: colors.card,
              side: BorderSide(color: colors.line),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
              shape: const StadiumBorder(),
            ),
          ),
          if (hasActiveFilters)
            Positioned(
              top: 7,
              right: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 7),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandedFilterChips extends StatelessWidget {
  const _ExpandedFilterChips({
    required this.distances,
    required this.selectedDistanceKm,
    required this.onDistanceSelected,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onCategorySelected,
    required this.onAdvancedFiltersPressed,
  });

  final List<int> distances;
  final int selectedDistanceKm;
  final ValueChanged<int> onDistanceSelected;
  final List<HomeCategory> categories;
  final List<String> selectedCategoryIds;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onAdvancedFiltersPressed;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories.take(5).toList();

    return SizedBox(
      height: 58,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _DistanceChip(
              distanceKm: selectedDistanceKm,
              selected: true,
              onSelected: onDistanceSelected,
            ),
            _MoreFiltersChip(onPressed: onAdvancedFiltersPressed),
            for (final distance in distances.where(
              (d) => d != selectedDistanceKm,
            ))
              _DistanceChip(
                distanceKm: distance,
                selected: false,
                onSelected: onDistanceSelected,
              ),
            const SizedBox(width: 4),
            _CategoryChip(
              label: 'Alles',
              selected: selectedCategoryIds.isEmpty,
              color: Theme.of(context).extension<TochTokens>()!.green,
              onSelected: () => onCategorySelected('all'),
            ),
            for (final category in visibleCategories)
              _CategoryChip(
                label: category.label,
                selected: selectedCategoryIds.contains(category.id),
                color: category.color,
                onSelected: () => onCategorySelected(category.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({
    required this.distanceKm,
    required this.selected,
    required this.onSelected,
  });

  final int distanceKm;
  final bool selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        avatar: Icon(
          Icons.near_me_rounded,
          size: 15,
          color: selected ? Colors.white : colors.green,
        ),
        label: Text('$distanceKm km'),
        onSelected: (_) => onSelected(distanceKm),
        selectedColor: colors.green,
        backgroundColor: colors.card,
        side: BorderSide(color: selected ? colors.green : colors.line),
        labelStyle: TextStyle(
          color: selected ? Colors.white : colors.ink,
          fontWeight: FontWeight.w900,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        avatar: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 8),
        ),
        label: Text(label),
        onSelected: (_) => onSelected(),
        selectedColor: colors.green,
        backgroundColor: colors.card,
        side: BorderSide(color: selected ? colors.green : colors.line),
        labelStyle: TextStyle(
          color: selected ? Colors.white : colors.ink,
          fontWeight: FontWeight.w900,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _MoreFiltersChip extends StatelessWidget {
  const _MoreFiltersChip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: ActionChip(
        avatar: Icon(Icons.filter_list_rounded, size: 16, color: colors.green),
        label: const Text('Meer filters'),
        onPressed: onPressed,
        backgroundColor: colors.card,
        side: BorderSide(color: colors.line),
        labelStyle: TextStyle(color: colors.ink, fontWeight: FontWeight.w900),
        shape: const StadiumBorder(),
      ),
    );
  }
}
