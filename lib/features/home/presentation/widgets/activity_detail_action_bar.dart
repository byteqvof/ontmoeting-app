import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';

class ActivityDetailActionBar extends StatelessWidget {
  const ActivityDetailActionBar({required this.activity, super.key});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final isOwnActivity = activity.isOwnedByCurrentUser;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isOwnActivity ? null : () {},
                  icon: Icon(_joinIconFor(activity)),
                  label: Text(_joinLabelFor(activity)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isOwnActivity
                        ? colors.green700.withValues(alpha: .55)
                        : colors.green,
                    side: BorderSide(
                      color: isOwnActivity ? colors.line : colors.green200,
                      width: 1.5,
                    ),
                    minimumSize: const Size(0, 52),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TochSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text('Open de chat'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _joinIconFor(HomeActivity activity) {
  if (activity.isOwnedByCurrentUser) {
    return Icons.event_available_rounded;
  }
  return activity.isJoined ? Icons.close_rounded : Icons.add_rounded;
}

String _joinLabelFor(HomeActivity activity) {
  if (activity.isOwnedByCurrentUser) {
    return 'Jouw activiteit';
  }
  return activity.isJoined ? 'Afmelden' : 'Ga mee';
}
