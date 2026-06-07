import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';

class ActivityDetailHostCard extends StatelessWidget {
  const ActivityDetailHostCard({
    required this.activity,
    this.onProfilePressed,
    super.key,
  });

  final HomeActivity activity;
  final ValueChanged<String>? onProfilePressed;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geplaatst door',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.green700.withValues(alpha: .7),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: TochSpacing.sm),
            Row(
              children: [
                _Avatar(
                  initials: _initialsFor(activity.hostFullName),
                  avatarUrl: activity.hostAvatarUrl,
                  profileId: activity.hostId,
                  onProfilePressed: onProfilePressed,
                ),
                const SizedBox(width: TochSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              activity.hostFullName,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (activity.hostIdentityVerified) ...[
                            const SizedBox(width: 5),
                            Tooltip(
                              message:
                                  'Deze gebruiker heeft zijn identiteit geverifieerd.',
                              child: Icon(
                                Icons.verified_rounded,
                                color: const Color(0xFF2E7E5C),
                                size: 17,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.hostSubtitle,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.green700.withValues(alpha: .72),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.green100,
                    borderRadius: BorderRadius.circular(TochRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Text(
                      '${activity.hostScore}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.avatarUrl,
    required this.profileId,
    required this.onProfilePressed,
  });

  final String initials;
  final String? avatarUrl;
  final String profileId;
  final ValueChanged<String>? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final canOpenProfile = profileId.isNotEmpty && onProfilePressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canOpenProfile ? () => onProfilePressed!(profileId) : null,
      child: CircleAvatar(
        radius: 26,
        backgroundColor: colors.green,
        foregroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
