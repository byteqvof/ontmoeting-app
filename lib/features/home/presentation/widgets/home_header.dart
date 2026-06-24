import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.locationName,
    required this.onLocationTap,
    super.key,
  });

  final String locationName;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wat is er te doen in',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.green700.withValues(alpha: .70),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              TextButton.icon(
                onPressed: onLocationTap,
                style: TextButton.styleFrom(
                  foregroundColor: colors.ink,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.location_on_outlined,
                  color: colors.green,
                  size: 20,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      locationName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.green700.withValues(alpha: .72),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Zoeken',
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: colors.card,
              foregroundColor: colors.green,
              side: BorderSide(color: colors.line),
              fixedSize: const Size.square(42),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }
}
