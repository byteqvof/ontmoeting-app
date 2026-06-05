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
        icon: Icons.event_available_rounded,
        title: 'Avondvissen aan de Maas',
        subtitle: 'Vissen · 3,2 km',
        supporting: 'jij + Rick · Je gaat',
      ),
      OnboardingHeroKind.nearby => const _HeroData(
        icon: Icons.map_rounded,
        title: 'Activiteiten vlakbij',
        subtitle: 'Koffie · wandelen · gaming',
        supporting: '5 ontmoetingen rond Maastricht',
      ),
      OnboardingHeroKind.trust => const _HeroData(
        icon: Icons.verified_user_rounded,
        title: 'Echte mensen',
        subtitle: 'Profielen geverifieerd',
        supporting: '96 opkomstscore',
      ),
    };

    return _PlaceholderImage(data: data, compact: compact);
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.data, required this.compact});

  final _HeroData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.green100,
          borderRadius: BorderRadius.circular(TochRadius.lg),
          border: Border.all(color: colors.line),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? TochSpacing.md : TochSpacing.lg),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.cream.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(TochRadius.md),
                  ),
                  child: CustomPaint(
                    painter: _PlaceholderPatternPainter(colors),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(TochRadius.lg),
                      border: Border.all(color: colors.line),
                      boxShadow: [
                        BoxShadow(
                          color: colors.green.withValues(alpha: .14),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        compact ? TochSpacing.md : TochSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.orange.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(
                                TochRadius.md,
                              ),
                            ),
                            child: SizedBox.square(
                              dimension: compact ? 54 : 64,
                              child: Icon(
                                data.icon,
                                color: colors.orange,
                                size: compact ? 30 : 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: TochSpacing.md),
                          Text(
                            data.subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.green700,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: colors.green),
                          ),
                          const SizedBox(height: TochSpacing.md),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.green,
                              borderRadius: BorderRadius.circular(
                                TochRadius.pill,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              child: Text(
                                data.supporting,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.cream,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.card.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(TochRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      'placeholder',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.green700,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroData {
  const _HeroData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.supporting,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String supporting;
}

class _PlaceholderPatternPainter extends CustomPainter {
  const _PlaceholderPatternPainter(this.colors);

  final TochTokens colors;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = colors.green200
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = colors.orange.withValues(alpha: .72);

    for (var x = -size.height; x < size.width; x += 34) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        linePaint,
      );
    }

    for (final point in [
      Offset(size.width * .16, size.height * .24),
      Offset(size.width * .82, size.height * .28),
      Offset(size.width * .24, size.height * .78),
      Offset(size.width * .76, size.height * .72),
    ]) {
      canvas.drawCircle(point, 6, dotPaint);
      canvas.drawCircle(point, 2.4, Paint()..color = colors.cream);
    }
  }

  @override
  bool shouldRepaint(covariant _PlaceholderPatternPainter oldDelegate) => false;
}
