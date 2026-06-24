import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class HomeFeedSummary extends StatelessWidget {
  const HomeFeedSummary({required this.activityCount, super.key});

  final int activityCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Vlakbij',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            '$activityCount activiteiten',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.green700.withValues(alpha: .70),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
