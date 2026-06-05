import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';

class ActivityDetailHero extends StatelessWidget {
  const ActivityDetailHero({
    required this.activity,
    this.onBackPressed,
    super.key,
  });

  final HomeActivity activity;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cream,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(TochRadius.lg),
        ),
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeroIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: onBackPressed ?? () => context.pop(),
                  ),
                  const Spacer(),
                  _HeroIconButton(
                    icon: Icons.ios_share_rounded,
                    onPressed: () {},
                  ),
                  const SizedBox(width: TochSpacing.xs),
                  _HeroIconButton(
                    icon: Icons.bookmark_border_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: TochSpacing.lg),
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: activity.category.backgroundColor,
                      borderRadius: BorderRadius.circular(TochRadius.md),
                    ),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        activity.category.icon,
                        color: activity.category.color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: TochSpacing.sm),
                  Expanded(
                    child: Text(
                      '${activity.category.label} · ${activity.distanceLabel}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.green700.withValues(alpha: .72),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TochSpacing.sm),
              Text(
                activity.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.ink,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: TochSpacing.lg),
              _MapPlaceholder(activity: activity),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.card,
        foregroundColor: colors.ink,
        fixedSize: const Size.square(42),
      ),
      icon: Icon(icon, size: 21),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return ClipRRect(
      borderRadius: BorderRadius.circular(TochRadius.lg),
      child: SizedBox(
        height: 152,
        width: double.infinity,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFE7EBE0)),
          child: Stack(
            children: [
              Positioned(
                left: -30,
                right: -20,
                top: 72,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFE0E6),
                    borderRadius: BorderRadius.circular(TochRadius.pill),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: -10,
                child: _MapRoad(angle: -.26, height: 210),
              ),
              Positioned(
                left: 164,
                top: -18,
                child: _MapRoad(angle: -.12, height: 220),
              ),
              Positioned(
                right: -18,
                top: 22,
                child: _MapRoad(angle: 1.42, height: 260),
              ),
              Positioned(
                left: 24,
                top: 18,
                child: _MapBlock(color: const Color(0xFFDBE6CC)),
              ),
              Positioned(
                right: 24,
                bottom: 16,
                child: _MapBlock(color: const Color(0xFFDBE6CC)),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.green,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                          bottomRight: Radius.circular(22),
                          bottomLeft: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.green.withValues(alpha: .24),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SizedBox.square(
                        dimension: 42,
                        child: Icon(
                          activity.category.icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(TochRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: Text(
                          activity.locationName,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapRoad extends StatelessWidget {
  const _MapRoad({required this.angle, required this.height});

  final double angle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 7,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFD8DACE),
          borderRadius: BorderRadius.circular(TochRadius.pill),
        ),
      ),
    );
  }
}

class _MapBlock extends StatelessWidget {
  const _MapBlock({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 58,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(TochRadius.sm),
      ),
    );
  }
}
