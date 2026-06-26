import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../domain/entities/home_activity.dart';

class ActivityDetailInfoCard extends StatelessWidget {
  const ActivityDetailInfoCard({required this.activity, super.key});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetaCard(
            icon: Icons.calendar_today_rounded,
            label: 'Wanneer',
            value: '${activity.dateLabel}\n${activity.timeLabel}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetaCard(
            icon: Icons.place_outlined,
            label: 'Waar',
            value: activity.meetingPoint.isEmpty
                ? activity.locationName
                : activity.meetingPoint,
          ),
        ),
      ],
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.md),
        boxShadow: TochShadows.card(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.green100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox.square(
                dimension: 36,
                child: Icon(icon, color: colors.green, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TochSectionLabel(label),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
