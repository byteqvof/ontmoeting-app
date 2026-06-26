import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
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
        onTap: () => context.push(AppRoutes.premium),
        borderRadius: BorderRadius.circular(TochRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF17201B),
            borderRadius: BorderRadius.circular(TochRadius.lg),
            boxShadow: TochShadows.raised(colors),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox.square(
                    dimension: 44,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: colors.orange,
                      size: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? 'toch+ actief' : 'toch+',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Meer ontdekken, eerder opvallen',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: .58),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.orange,
                    borderRadius: BorderRadius.circular(TochRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Text(
                      isPremium ? 'Bekijk' : 'Probeer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
