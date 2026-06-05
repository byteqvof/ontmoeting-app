import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_category.dart';

class HomeCategoryStrip extends StatelessWidget {
  const HomeCategoryStrip({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    super.key,
  });

  final List<HomeCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == selectedCategoryId;
          return _HomeCategoryChip(
            category: category,
            selected: selected,
            onTap: () => onSelected(category.id),
          );
        },
      ),
    );
  }
}

class _HomeCategoryChip extends StatelessWidget {
  const _HomeCategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final HomeCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TochRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: selected ? colors.ink : colors.card,
          borderRadius: BorderRadius.circular(TochRadius.pill),
          border: Border.all(color: selected ? colors.ink : colors.line),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: selected ? .12 : .04),
              blurRadius: selected ? 18 : 8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: selected ? Colors.white : category.color,
            ),
            const SizedBox(width: 7),
            Text(
              category.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? Colors.white : colors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
