import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

enum OnboardingHeroKind { activity, nearby, trust }

class OnboardingHero extends StatelessWidget {
  const OnboardingHero({required this.kind, this.compact = false, super.key});

  final OnboardingHeroKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final data = switch (kind) {
      OnboardingHeroKind.activity => const _HeroData(
        icon: Icons.phishing_rounded,
        label: 'Vissen',
        title: 'Avondvissen\naan de Maas',
        badge: 'Je gaat mee',
        accent: Color(0xFF347E70),
      ),
      OnboardingHeroKind.nearby => const _HeroData(
        icon: Icons.map_rounded,
        label: 'Vlakbij',
        title: 'Koffie in\nhet centrum',
        badge: '3 plekken vrij',
        accent: Color(0xFFE0913A),
      ),
      OnboardingHeroKind.trust => const _HeroData(
        icon: Icons.verified_user_rounded,
        label: 'Profiel',
        title: 'Telefoon\nbevestigd',
        badge: 'Echte accounts',
        accent: Color(0xFF7E5C9E),
      ),
    };

    return Center(
      child: Transform.rotate(
        angle: kind == OnboardingHeroKind.activity ? -.055 : .035,
        child: _FloatingActivityCard(data: data, compact: compact),
      ),
    );
  }
}

class _FloatingActivityCard extends StatelessWidget {
  const _FloatingActivityCard({required this.data, required this.compact});

  final _HeroData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final width = compact ? 238.0 : 274.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .24),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: compact ? 148 : 178,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data.accent.withValues(alpha: .92),
                    colors.greenPressed,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _HeroTexturePainter(data.accent),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 18,
                    right: 18,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: SizedBox.square(
                            dimension: 48,
                            child: Icon(
                              data.icon,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data.label,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: .72,
                                      ),
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              Text(
                                data.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      height: 1,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.green,
                  borderRadius: BorderRadius.circular(TochRadius.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: colors.green,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          data.badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroData {
  const _HeroData({
    required this.icon,
    required this.label,
    required this.title,
    required this.badge,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String title;
  final String badge;
  final Color accent;
}

class _HeroTexturePainter extends CustomPainter {
  const _HeroTexturePainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var i = 0; i < 8; i++) {
      final y = size.height * (.16 + i * .11);
      final path = Path()..moveTo(-20, y);
      for (var x = -20.0; x <= size.width + 20; x += 42) {
        path.quadraticBezierTo(x + 16, y + math.sin(i + x) * 9, x + 42, y);
      }
      canvas.drawPath(path, paint);
    }

    canvas.drawCircle(
      Offset(size.width * .78, size.height * .16),
      40,
      Paint()..color = accent.withValues(alpha: .28),
    );
  }

  @override
  bool shouldRepaint(covariant _HeroTexturePainter oldDelegate) => false;
}
