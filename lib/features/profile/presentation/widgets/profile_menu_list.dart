import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class ProfileMenuList extends StatelessWidget {
  const ProfileMenuList({
    required this.isOwnProfile,
    required this.onSignOutPressed,
    super.key,
  });

  final bool isOwnProfile;
  final VoidCallback onSignOutPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MenuItem(label: 'Account & verificatie'),
        const _MenuItem(label: 'Privacy en locatie'),
        const _MenuItem(label: 'Meldingen'),
        const _MenuItem(label: 'Help & contact'),
        if (isOwnProfile) ...[
          const SizedBox(height: TochSpacing.sm),
          _MenuItem(
            label: 'Uitloggen',
            icon: Icons.logout_rounded,
            isDestructive: true,
            onTap: onSignOutPressed,
          ),
        ],
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    this.icon,
    this.isDestructive = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final foregroundColor = isDestructive ? colors.orange : colors.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: foregroundColor, size: 20),
                  const SizedBox(width: TochSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isDestructive)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.green700.withValues(alpha: .5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
