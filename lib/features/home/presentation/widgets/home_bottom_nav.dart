import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

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
            child: const SizedBox(
              height: 64,
              child: Row(
                children: [
                  _HomeNavItem(
                    icon: Icons.explore_rounded,
                    label: 'Ontdek',
                    selected: true,
                  ),
                  _HomeNavItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Berichten',
                  ),
                  _HomeCreateButton(),
                  _HomeNavItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Agenda',
                  ),
                  _HomeNavItem(icon: Icons.person_rounded, label: 'Profiel'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 23,
            color: selected
                ? colors.green
                : colors.green700.withValues(alpha: .45),
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
    );
  }
}

class _HomeCreateButton extends StatelessWidget {
  const _HomeCreateButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Expanded(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.green,
            borderRadius: BorderRadius.circular(TochRadius.md),
            boxShadow: [
              BoxShadow(
                color: colors.green.withValues(alpha: .28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const SizedBox(
            width: 52,
            height: 40,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
