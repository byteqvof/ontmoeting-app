import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_location.dart';
import '../controllers/activity_chat_notice_controller.dart';
import '../pages/create_activity_page.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    this.location,
    this.categories = const [],
    this.selected = HomeNavDestination.discover,
    super.key,
  });

  final HomeLocation? location;
  final List<HomeCategory> categories;
  final HomeNavDestination selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final chatNotices = sl<ActivityChatNoticeController>();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.cream.withValues(alpha: 0),
            colors.cream,
            colors.cream,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .86),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: .72)),
              boxShadow: [
                BoxShadow(
                  color: colors.ink.withValues(alpha: .10),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _HomeNavItem(
                    icon: Icons.explore_rounded,
                    label: 'Ontdek',
                    selected: selected == HomeNavDestination.discover,
                    onTap: selected == HomeNavDestination.discover
                        ? null
                        : () => context.go(AppRoutes.home),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: chatNotices.unreadCountListenable,
                    builder: (context, unreadCount, _) {
                      return _HomeNavItem(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Berichten',
                        selected: selected == HomeNavDestination.messages,
                        badgeCount: selected == HomeNavDestination.messages
                            ? 0
                            : unreadCount,
                        onTap: selected == HomeNavDestination.messages
                            ? null
                            : () {
                                chatNotices.clearUnread();
                                context.go(AppRoutes.activityMessages);
                              },
                      );
                    },
                  ),
                  _HomeCreateButton(location: location, categories: categories),
                  _HomeNavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Agenda',
                    selected: selected == HomeNavDestination.agenda,
                    onTap: selected == HomeNavDestination.agenda
                        ? null
                        : () => context.go(AppRoutes.activityAgenda),
                  ),
                  _HomeNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profiel',
                    selected: selected == HomeNavDestination.profile,
                    onTap: selected == HomeNavDestination.profile
                        ? null
                        : () => context.go(AppRoutes.profile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum HomeNavDestination { discover, messages, agenda, profile }

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.badgeCount = 0,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TochRadius.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: selected
                      ? colors.green
                      : colors.green700.withValues(alpha: .45),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: _UnreadBadge(count: badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? colors.green
                    : colors.green700.withValues(alpha: .45),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final label = count > 9 ? '9+' : count.toString();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.orange,
        borderRadius: BorderRadius.circular(TochRadius.pill),
        border: Border.all(color: colors.card, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
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

class _HomeCreateButton extends StatelessWidget {
  const _HomeCreateButton({required this.location, required this.categories});

  final HomeLocation? location;
  final List<HomeCategory> categories;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Expanded(
      child: Center(
        child: Material(
          color: colors.green,
          borderRadius: BorderRadius.circular(TochRadius.md),
          child: InkWell(
            onTap: () {
              final currentLocation = location;
              if (currentLocation == null || categories.isEmpty) {
                context.go(AppRoutes.home);
                return;
              }
              context.push(
                AppRoutes.createActivity,
                extra: CreateActivityPageArgs(
                  location: currentLocation,
                  categories: categories,
                ),
              );
            },
            borderRadius: BorderRadius.circular(TochRadius.md),
            child: Ink(
              width: 52,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TochRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: colors.green.withValues(alpha: .28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
