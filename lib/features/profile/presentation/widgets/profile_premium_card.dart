import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class ProfilePremiumCard extends StatelessWidget {
  const ProfilePremiumCard({required this.isPremium, super.key});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(TochRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.ink,
            borderRadius: BorderRadius.circular(TochRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.md),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.orange.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(TochRadius.md),
                  ),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: colors.orange,
                      size: 25,
                    ),
                  ),
                ),
                const SizedBox(width: TochSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? 'toch+ actief' : 'toch+',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Groter bereik, geen reclame',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: .62),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: .54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
