import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';

class ActivityDetailActionBar extends StatelessWidget {
  const ActivityDetailActionBar({
    required this.activity,
    this.onParticipationPressed,
    this.onCompletePressed,
    this.onChatPressed,
    this.isParticipationPending = false,
    this.isCompletionPending = false,
    super.key,
  });

  final HomeActivity activity;
  final VoidCallback? onParticipationPressed;
  final VoidCallback? onCompletePressed;
  final VoidCallback? onChatPressed;
  final bool isParticipationPending;
  final bool isCompletionPending;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final isOwnActivity = activity.isOwnedByCurrentUser;
    final isFull = !activity.isJoined && activity.availableSpots <= 0;
    final isPrimaryPending = isOwnActivity
        ? isCompletionPending
        : isParticipationPending;
    final isPrimaryDisabled =
        activity.isCompleted ||
        activity.isParticipationPending ||
        isPrimaryPending ||
        (isOwnActivity && !activity.canBeCompletedNow) ||
        (!isOwnActivity && isFull);

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
                  onPressed: isPrimaryDisabled
                      ? null
                      : isOwnActivity
                      ? onCompletePressed
                      : onParticipationPressed,
                  icon: isPrimaryPending
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.green,
                          ),
                        )
                      : Icon(_primaryIconFor(activity)),
                  label: Text(_primaryLabelFor(activity)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: activity.isCompleted || isFull
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
                  onPressed: onChatPressed,
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

IconData _primaryIconFor(HomeActivity activity) {
  if (activity.isCompleted) {
    return Icons.verified_rounded;
  }
  if (activity.isOwnedByCurrentUser) {
    if (!activity.hasStarted) {
      return Icons.schedule_rounded;
    }
    return Icons.event_available_rounded;
  }
  if (activity.isParticipationPending) {
    return Icons.hourglass_top_rounded;
  }
  if (!activity.isJoined && activity.availableSpots <= 0) {
    return Icons.block_rounded;
  }
  return activity.isJoined ? Icons.close_rounded : Icons.add_rounded;
}

String _primaryLabelFor(HomeActivity activity) {
  if (activity.isCompleted) {
    return 'Afgerond';
  }
  if (activity.isOwnedByCurrentUser) {
    if (!activity.hasStarted) {
      return 'Nog niet begonnen';
    }
    return 'Afronden';
  }
  if (activity.isParticipationPending) {
    return 'Wacht op akkoord';
  }
  if (!activity.isJoined && activity.availableSpots <= 0) {
    return 'Vol';
  }
  return activity.isJoined ? 'Afmelden' : 'Ga mee';
}
