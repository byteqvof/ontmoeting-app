import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';

class ActivityDetailInfoCard extends StatelessWidget {
  const ActivityDetailInfoCard({required this.activity, super.key});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: activity.dateLabel,
          ),
          const _DetailDivider(),
          _InfoRow(icon: Icons.schedule_rounded, label: activity.timeLabel),
          const _DetailDivider(),
          _InfoRow(icon: Icons.near_me_rounded, label: activity.meetingPoint),
          const _DetailDivider(),
          _InfoRow(
            icon: Icons.location_on_rounded,
            label: activity.locationName,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.green100,
            borderRadius: BorderRadius.circular(TochRadius.md),
          ),
          child: SizedBox.square(
            dimension: 42,
            child: Icon(icon, color: colors.green, size: 21),
          ),
        ),
        const SizedBox(width: TochSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

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

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TochSpacing.sm),
      child: Divider(height: 1, color: context.toch.line),
    );
  }
}
