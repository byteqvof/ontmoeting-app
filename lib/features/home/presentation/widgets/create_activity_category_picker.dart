import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_category.dart';
import '../bloc/create_activity_bloc.dart';
import 'home_category_style.dart';

class CreateActivityCategoryPicker extends StatelessWidget {
  const CreateActivityCategoryPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final category in state.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CategoryOption(
                    category: category,
                    selected: state.categoryId == category.id,
                    onPressed: () {
                      context.read<CreateActivityBloc>().add(
                        CreateActivityCategorySelected(category.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onPressed,
  });

  final HomeCategory category;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return SizedBox(
      width: 76,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: colors.ink,
          padding: EdgeInsets.zero,
          minimumSize: const Size(76, 86),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TochRadius.lg),
          ),
        ),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: category.backgroundColor,
                borderRadius: BorderRadius.circular(18),
                border: selected
                    ? Border.all(color: colors.green, width: 2)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: colors.green.withValues(alpha: .16),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ]
                    : null,
              ),
              child: SizedBox.square(
                dimension: 64,
                child: Icon(category.icon, color: category.color, size: 27),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? colors.green
                    : colors.green700.withValues(alpha: .72),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
