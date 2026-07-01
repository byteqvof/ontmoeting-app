import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../core/utils/toch_category_icons.dart';
import '../../domain/entities/profile_interest.dart';

class ProfileInterestsCard extends StatelessWidget {
  const ProfileInterestsCard({required this.interests, super.key});

  final List<ProfileInterest> interests;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final uniqueInterests = _uniqueInterests(interests);

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
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
                'Interesses',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.green700.withValues(alpha: .68),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: TochSpacing.sm),
              Wrap(
                spacing: TochSpacing.xs,
                runSpacing: TochSpacing.xs,
                children: uniqueInterests.map((interest) {
                  return _InterestChip(interest: interest);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.interest});

  final ProfileInterest interest;

  @override
  Widget build(BuildContext context) {
    final foreground = _colorFromHex(
      interest.foregroundColorHex,
      fallback: context.toch.green,
    );
    final background = _colorFromHex(
      interest.backgroundColorHex,
      fallback: context.toch.green100,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TochRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tochCategoryIcon(
                id: interest.id,
                label: interest.label,
                iconKey: interest.iconKey,
              ),
              color: foreground,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              interest.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<ProfileInterest> _uniqueInterests(List<ProfileInterest> interests) {
  final seen = <String>{};
  final unique = <ProfileInterest>[];

  for (final interest in interests) {
    final key = interest.id.trim().toLowerCase().isEmpty
        ? interest.label.trim().toLowerCase()
        : interest.id.trim().toLowerCase();
    if (key.isEmpty || !seen.add(key)) {
      continue;
    }
    unique.add(interest);
  }

  return unique;
}

Color _colorFromHex(String hex, {required Color fallback}) {
  final normalized = hex.replaceFirst('#', '').trim();
  if (normalized.length != 6 && normalized.length != 8) {
    return fallback;
  }

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return fallback;
  }

  return Color(normalized.length == 6 ? 0xFF000000 | value : value);
}
