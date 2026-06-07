import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/profile.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: colors.green,
              foregroundImage: profile.avatarUrl == null
                  ? null
                  : NetworkImage(profile.avatarUrl!),
              child: Text(
                profile.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (profile.trust.identityVerified)
              Positioned(
                right: -2,
                bottom: 2,
                child: Tooltip(
                  message: 'Deze gebruiker heeft zijn identiteit geverifieerd.',
                  child: Icon(
                    Icons.verified_rounded,
                    color: const Color(0xFF2E7E5C),
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: TochSpacing.sm),
        Text(
          profile.displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${profile.cityName} - lid sinds ${_memberSinceLabel(profile.memberSince)}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.green700.withValues(alpha: .7),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TochSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: TochSpacing.xs,
          runSpacing: TochSpacing.xs,
          children: [
            _StatusPill(
              label: profile.trust.phoneStatusLabel,
              icon: Icons.phone_android_rounded,
              isConfirmed: profile.trust.phoneVerified,
            ),
            _StatusPill(
              label: profile.trust.reputationLabel,
              icon: Icons.trending_up_rounded,
              isConfirmed: profile.trust.reputationScore > 0,
            ),
            if (profile.trust.identityVerified)
              const _StatusPill(
                label: 'Identiteit bevestigd',
                icon: Icons.badge_outlined,
                isConfirmed: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.isConfirmed,
  });

  final String label;
  final IconData icon;
  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isConfirmed ? colors.green100 : colors.orangeSoft,
        borderRadius: BorderRadius.circular(TochRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isConfirmed ? colors.green : colors.orange,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _memberSinceLabel(DateTime date) {
  const months = [
    'januari',
    'februari',
    'maart',
    'april',
    'mei',
    'juni',
    'juli',
    'augustus',
    'september',
    'oktober',
    'november',
    'december',
  ];
  return '${months[date.month - 1]} ${date.year}';
}
