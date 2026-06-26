import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.locationName,
    required this.onLocationTap,
    required this.hasActiveFilters,
    required this.onFilterTap,
    super.key,
  });

  final String locationName;
  final VoidCallback onLocationTap;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TochSectionLabel('Vlakbij in'),
                  const SizedBox(height: 2),
                  TextButton(
                    onPressed: onLocationTap,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.ink,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 230),
                          child: Text(
                            locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  letterSpacing: 0,
                                ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.ink,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TochRoundButton(
                    icon: Icons.search_rounded,
                    tooltip: 'Zoeken',
                    onPressed: () => context.push(AppRoutes.search),
                  ),
                  const SizedBox(width: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TochRoundButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Filters',
                        onPressed: onFilterTap,
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          right: 3,
                          top: 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.card, width: 2),
                            ),
                            child: const SizedBox.square(dimension: 10),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
