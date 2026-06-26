import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class HomeFeedSummary extends StatelessWidget {
  const HomeFeedSummary({required this.activityCount, super.key});

  final int activityCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.orange,
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(dimension: 7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activityCount > 0 ? 'Nu live' : 'Activiteiten',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$activityCount',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.ink4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
