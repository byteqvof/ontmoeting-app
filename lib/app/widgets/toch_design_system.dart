import 'package:flutter/material.dart';

import '../theme/toch_theme.dart';

class TochScreen extends StatelessWidget {
  const TochScreen({
    required this.child,
    this.backgroundColor,
    this.bottom,
    super.key,
  });

  final Widget child;
  final Color? backgroundColor;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: backgroundColor ?? colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
      bottomNavigationBar: bottom,
    );
  }
}

class TochRoundButton extends StatelessWidget {
  const TochRoundButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.dark = false,
    this.size = 42,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: dark
            ? Colors.black.withValues(alpha: .34)
            : colors.card,
        foregroundColor: dark ? Colors.white : colors.ink2,
        fixedSize: Size.square(size),
        shadowColor: colors.ink.withValues(alpha: .16),
        elevation: dark ? 0 : 3,
      ),
      icon: Icon(icon, size: size < 42 ? 19 : 21),
    );
  }
}

class TochPill extends StatelessWidget {
  const TochPill({
    required this.label,
    this.icon,
    this.active = false,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool active;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final background = backgroundColor ?? (active ? colors.green : colors.card);
    final foreground = foregroundColor ?? (active ? Colors.white : colors.ink2);

    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TochRadius.pill),
        boxShadow: active
            ? TochShadows.button(colors)
            : TochShadows.card(colors),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 5 : 9,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 14 : 16, color: foreground),
              SizedBox(width: compact ? 5 : 7),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TochRadius.pill),
      child: child,
    );
  }
}

class TochSectionLabel extends StatelessWidget {
  const TochSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colors.ink4,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
      ),
    );
  }
}

class TochPrimaryButton extends StatelessWidget {
  const TochPrimaryButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.light = false,
    this.danger = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool light;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final background = danger
        ? const Color(0xFFF8E6E1)
        : light
        ? colors.card
        : colors.green;
    final foreground = danger
        ? const Color(0xFFC0492F)
        : light
        ? colors.green
        : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shadowColor: colors.green.withValues(alpha: .24),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}

class TochCategorySkin {
  const TochCategorySkin({
    required this.color,
    required this.tint,
    required this.gradient,
  });

  final Color color;
  final Color tint;
  final List<Color> gradient;
}

TochCategorySkin tochCategorySkin(String idOrLabel) {
  final key = idOrLabel.toLowerCase();
  if (key.contains('vis') || key.contains('viss')) {
    return const TochCategorySkin(
      color: Color(0xFF347E70),
      tint: Color(0xFFE1EDEA),
      gradient: [Color(0xFF347E70), Color(0xFF1E5740)],
    );
  }
  if (key.contains('wandel') || key.contains('buiten')) {
    return const TochCategorySkin(
      color: Color(0xFF5E8B3A),
      tint: Color(0xFFEAF1DF),
      gradient: [Color(0xFF6E9B45), Color(0xFF46702A)],
    );
  }
  if (key.contains('koffie') || key.contains('eten')) {
    return const TochCategorySkin(
      color: Color(0xFF93623B),
      tint: Color(0xFFF0E7DE),
      gradient: [Color(0xFFA6724A), Color(0xFF79502E)],
    );
  }
  if (key.contains('sport')) {
    return const TochCategorySkin(
      color: Color(0xFFD2703C),
      tint: Color(0xFFF8E8DC),
      gradient: [Color(0xFFE0833F), Color(0xFFC25E28)],
    );
  }
  if (key.contains('game')) {
    return const TochCategorySkin(
      color: Color(0xFF4C6357),
      tint: Color(0xFFE2E9E5),
      gradient: [Color(0xFF5A7466), Color(0xFF374E44)],
    );
  }
  if (key.contains('motor')) {
    return const TochCategorySkin(
      color: Color(0xFF6F7268),
      tint: Color(0xFFEAEAE5),
      gradient: [Color(0xFF7E8175), Color(0xFF56594F)],
    );
  }
  return const TochCategorySkin(
    color: Color(0xFF347E70),
    tint: Color(0xFFE1EDEA),
    gradient: [Color(0xFF347E70), Color(0xFF1E5740)],
  );
}

class TochPhotoPanel extends StatelessWidget {
  const TochPhotoPanel({
    required this.title,
    required this.categoryLabel,
    required this.icon,
    required this.skin,
    this.distanceLabel,
    this.live = false,
    this.height = 176,
    this.showLiveBadge = true,
    this.showDistance = true,
    this.showCategory = true,
    this.showTitle = true,
    super.key,
  });

  final String title;
  final String categoryLabel;
  final IconData icon;
  final TochCategorySkin skin;
  final String? distanceLabel;
  final bool live;
  final double height;
  final bool showLiveBadge;
  final bool showDistance;
  final bool showCategory;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final showTopMeta =
        (showLiveBadge && live) || (showDistance && distanceLabel != null);
    final showBottomMeta = showCategory || showTitle;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: skin.gradient,
              ),
            ),
          ),
          CustomPaint(painter: _TochPhotoTexturePainter()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .04),
                  Colors.black.withValues(alpha: .58),
                ],
              ),
            ),
          ),
          if (showTopMeta || showBottomMeta)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTopMeta)
                    Row(
                      children: [
                        if (showLiveBadge && live)
                          const TochPill(
                            label: 'Live',
                            active: true,
                            compact: true,
                            backgroundColor: Color(0xFFE0913A),
                            foregroundColor: Colors.white,
                          ),
                        const Spacer(),
                        if (showDistance && distanceLabel != null)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .38),
                              borderRadius: BorderRadius.circular(
                                TochRadius.pill,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                distanceLabel!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  const Spacer(),
                  if (showCategory)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: skin.color.withValues(alpha: .84),
                        borderRadius: BorderRadius.circular(TochRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 15, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              categoryLabel,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (showCategory && showTitle) const SizedBox(height: 8),
                  if (showTitle)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TochPhotoTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .08)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 38) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), line);
    }

    final circle = Paint()..color = Colors.white.withValues(alpha: .08);
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .22),
      size.shortestSide * .18,
      circle,
    );
    canvas.drawCircle(
      Offset(size.width * .2, size.height * .78),
      size.shortestSide * .24,
      circle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
