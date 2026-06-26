import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../domain/entities/home_activity.dart';

class ActivityDetailHero extends StatelessWidget {
  const ActivityDetailHero({
    required this.activity,
    this.onBackPressed,
    this.onEditPressed,
    super.key,
  });

  final HomeActivity activity;
  final VoidCallback? onBackPressed;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final skin = tochCategorySkin('${activity.category.id} ${activity.category.label}');

    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TochPhotoPanel(
            title: activity.title,
            categoryLabel: activity.category.label,
            icon: activity.category.icon,
            skin: skin,
            distanceLabel: activity.distanceLabel,
            live: _isLive(activity),
            height: 280,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .12),
                  Colors.black.withValues(alpha: .58),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TochRoundButton(
                        icon: Icons.arrow_back_rounded,
                        dark: true,
                        size: 40,
                        onPressed: onBackPressed ?? () => context.pop(),
                      ),
                      const Spacer(),
                      TochRoundButton(
                        icon: Icons.ios_share_rounded,
                        dark: true,
                        size: 40,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      if (onEditPressed != null) ...[
                        TochRoundButton(
                          icon: Icons.edit_rounded,
                          dark: true,
                          size: 40,
                          onPressed: onEditPressed,
                        ),
                        const SizedBox(width: 8),
                      ],
                      TochRoundButton(
                        icon: Icons.bookmark_border_rounded,
                        dark: true,
                        size: 40,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TochPill(
                        label: activity.category.label,
                        icon: activity.category.icon,
                        compact: true,
                        backgroundColor: skin.color.withValues(alpha: .86),
                        foregroundColor: Colors.white,
                      ),
                      if (_isLive(activity))
                        const TochPill(
                          label: 'Live',
                          compact: true,
                          backgroundColor: Color(0xFFE0913A),
                          foregroundColor: Colors.white,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .40),
                          borderRadius: BorderRadius.circular(TochRadius.pill),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            activity.distanceLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.card,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isLive(HomeActivity activity) {
  final start = activity.startsAt;
  if (start == null || activity.isCompleted) {
    return false;
  }
  final now = DateTime.now();
  return !start.isAfter(now) && now.difference(start).inHours < 5;
}
