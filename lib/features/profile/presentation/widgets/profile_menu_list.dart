import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class ProfileMenuList extends StatelessWidget {
  const ProfileMenuList({
    required this.isOwnProfile,
    required this.onSignOutPressed,
    this.onAccountVerificationPressed,
    this.onFriendsPressed,
    this.onPrivacyPressed,
    this.onNotificationsPressed,
    this.onHelpPressed,
    this.onDeleteAccountPressed,
    this.onReportProfilePressed,
    this.onBlockProfilePressed,
    this.friendsBadgeCount = 0,
    super.key,
  });

  final bool isOwnProfile;
  final VoidCallback onSignOutPressed;
  final VoidCallback? onAccountVerificationPressed;
  final VoidCallback? onFriendsPressed;
  final VoidCallback? onPrivacyPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onDeleteAccountPressed;
  final VoidCallback? onReportProfilePressed;
  final VoidCallback? onBlockProfilePressed;
  final int friendsBadgeCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isOwnProfile)
          _MenuItem(
            label: 'Account & verificatie',
            icon: Icons.verified_user_outlined,
            onTap: onAccountVerificationPressed,
          ),
        if (isOwnProfile)
          _MenuItem(
            label: 'Vrienden',
            icon: Icons.group_outlined,
            onTap: onFriendsPressed,
            badgeCount: friendsBadgeCount,
          ),
        _MenuItem(
          label: 'Privacy en locatie',
          icon: Icons.lock_outline_rounded,
          onTap: onPrivacyPressed,
        ),
        _MenuItem(
          label: 'Meldingen',
          icon: Icons.notifications_outlined,
          onTap: onNotificationsPressed,
        ),
        _MenuItem(
          label: 'Info over TOCH',
          icon: Icons.info_outline_rounded,
          onTap: onHelpPressed,
        ),
        if (isOwnProfile) ...[
          const SizedBox(height: TochSpacing.sm),
          _MenuItem(
            label: 'Uitloggen',
            icon: Icons.logout_rounded,
            isDestructive: true,
            onTap: onSignOutPressed,
          ),
          _MenuItem(
            label: 'Account verwijderen',
            icon: Icons.delete_forever_rounded,
            isDestructive: true,
            onTap: onDeleteAccountPressed,
          ),
        ] else ...[
          const SizedBox(height: TochSpacing.sm),
          _MenuItem(
            label: 'Profiel rapporteren',
            icon: Icons.flag_rounded,
            onTap: onReportProfilePressed,
          ),
          _MenuItem(
            label: 'Gebruiker blokkeren',
            icon: Icons.block_rounded,
            isDestructive: true,
            onTap: onBlockProfilePressed,
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
    this.badgeCount = 0,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isDestructive;
  final int badgeCount;
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
                if (badgeCount > 0) ...[
                  const SizedBox(width: TochSpacing.sm),
                  _MenuBadge(count: badgeCount),
                ],
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

class _MenuBadge extends StatelessWidget {
  const _MenuBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final label = count > 9 ? '9+' : count.toString();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.orange,
        borderRadius: BorderRadius.circular(TochRadius.pill),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
