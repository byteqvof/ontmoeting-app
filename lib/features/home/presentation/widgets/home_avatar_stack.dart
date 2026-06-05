import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_participant.dart';

class HomeAvatarStack extends StatelessWidget {
  const HomeAvatarStack({
    required this.participants,
    this.maxVisibleAvatars = 3,
    this.onProfilePressed,
    super.key,
  });

  final List<HomeParticipant> participants;
  final int maxVisibleAvatars;
  final ValueChanged<String>? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final safeMaxVisible = maxVisibleAvatars < 1 ? 1 : maxVisibleAvatars;
    final visible = participants.take(safeMaxVisible).toList();
    final overflowCount = participants.length - visible.length;
    final itemCount = visible.length + (overflowCount > 0 ? 1 : 0);

    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 22.0 + (itemCount * 21.0),
      height: 30,
      child: Stack(
        children: [
          for (var index = 0; index < visible.length; index++)
            _StackedAvatar(
              left: index * 21.0,
              label: visible[index].initials,
              avatarUrl: visible[index].avatarUrl,
              profileId: visible[index].id,
              onProfilePressed: onProfilePressed,
              backgroundColor: index.isEven
                  ? colors.green
                  : colors.categoryVisel,
              foregroundColor: Colors.white,
              borderColor: colors.card,
            ),
          if (overflowCount > 0)
            _StackedAvatar(
              left: visible.length * 21.0,
              label: '+$overflowCount',
              avatarUrl: null,
              profileId: '',
              onProfilePressed: null,
              backgroundColor: colors.card,
              foregroundColor: colors.green700.withValues(alpha: .72),
              borderColor: colors.card,
            ),
        ],
      ),
    );
  }
}

class _StackedAvatar extends StatelessWidget {
  const _StackedAvatar({
    required this.left,
    required this.label,
    required this.avatarUrl,
    required this.profileId,
    required this.onProfilePressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  final double left;
  final String label;
  final String? avatarUrl;
  final String profileId;
  final ValueChanged<String>? onProfilePressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final canOpenProfile = profileId.isNotEmpty && onProfilePressed != null;

    return Positioned(
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: canOpenProfile ? () => onProfilePressed!(profileId) : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.4),
          ),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: backgroundColor,
            foregroundImage: avatarUrl == null
                ? null
                : NetworkImage(avatarUrl!),
            child: Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
