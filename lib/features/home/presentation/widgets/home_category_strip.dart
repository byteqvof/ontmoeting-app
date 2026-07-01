import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_category.dart';
import 'home_category_style.dart';

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
      height: 68,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 6),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: selected ? colors.greenDeep : colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? colors.greenDeep : colors.line),
          boxShadow: selected
              ? TochShadows.button(colors)
              : [
                  BoxShadow(
                    color: colors.ink.withValues(alpha: .05),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: .14)
                    : category.backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox.square(
                dimension: 32,
                child: Icon(
                  category.icon,
                  size: 18,
                  color: selected ? Colors.white : category.color,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              category.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? Colors.white : colors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
