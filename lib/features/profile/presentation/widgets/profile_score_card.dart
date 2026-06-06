import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/profile.dart';

class ProfileScoreCard extends StatelessWidget {
  const ProfileScoreCard({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return _ProfileCard(
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.green100,
              borderRadius: BorderRadius.circular(TochRadius.md),
            ),
            child: SizedBox.square(
              dimension: 52,
              child: Icon(Icons.shield_rounded, color: colors.green, size: 27),
            ),
          ),
          const SizedBox(width: TochSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reputatie',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.trust.reputationLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.green700.withValues(alpha: .68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${profile.trust.reputationScore}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colors.green,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: child,
      ),
    );
  }
}
