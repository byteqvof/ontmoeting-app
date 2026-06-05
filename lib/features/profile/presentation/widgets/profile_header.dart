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
            if (profile.isVerified)
              Positioned(
                right: -2,
                bottom: 2,
                child: Icon(
                  Icons.verified_rounded,
                  color: const Color(0xFF2E7E5C),
                  size: 28,
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
          '${profile.cityName} · lid sinds ${_memberSinceLabel(profile.memberSince)}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.green700.withValues(alpha: .7),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
