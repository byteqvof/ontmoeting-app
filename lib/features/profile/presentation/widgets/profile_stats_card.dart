import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/profile.dart';

class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({required this.profile, super.key});

  final Profile profile;

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
        padding: const EdgeInsets.symmetric(
          horizontal: TochSpacing.xs,
          vertical: TochSpacing.md,
        ),
        child: Row(
          children: [
            _StatItem(
              value: '${profile.activitiesJoinedCount}',
              label: 'meegedaan',
            ),
            _Divider(color: colors.line),
            _StatItem(
              value: '${profile.activitiesHostedCount}',
              label: 'geplaatst',
            ),
            _Divider(color: colors.line),
            _StatItem(
              value: profile.rating.toStringAsFixed(1).replaceAll('.', ','),
              label: 'beoordeling',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.green700.withValues(alpha: .68),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: color);
  }
}
