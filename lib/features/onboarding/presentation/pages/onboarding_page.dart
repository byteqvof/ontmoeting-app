import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_wordmark.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_preferences.dart';
import '../widgets/onboarding_hero.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _index = 0;

  static const _slides = [
    _OnboardingSlide(
      kicker: 'Welkom bij TOCH',
      title: 'Wat doe jij\nvanavond?',
      body:
          'Ontdek wat er bij jou in de buurt gebeurt en doe gewoon mee. Zo simpel is het.',
      hero: OnboardingHeroKind.activity,
    ),
    _OnboardingSlide(
      kicker: 'Ontdek dichtbij',
      title: 'Geen planning.\nWel iets doen.',
      body:
          'Vissen, koffie, wandelen of gamen. Kies wat past bij vandaag, morgen of dit weekend.',
      hero: OnboardingHeroKind.nearby,
    ),
    _OnboardingSlide(
      kicker: 'Lage drempel',
      title: 'Echte mensen.\nMinder gedoe.',
      body:
          'Telefoonbevestiging, meldingen en duidelijke profielen helpen wegwerpaccounts beperken.',
      hero: OnboardingHeroKind.trust,
    ),
  ];

  Future<void> _finish() async {
    await sl<AppPreferences>().markInitialFtiSeen();
    if (mounted) {
      context.go(AppRoutes.register);
    }
  }

  void _skip() => _finish();

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }

    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];
    final colors = context.toch;
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: colors.green,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 740;
                final heroHeight = (constraints.maxHeight * .36).clamp(
                  compact ? 240.0 : 270.0,
                  compact ? 280.0 : 330.0,
                );

                return Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _GreenGrain())),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const TochWordmark(fontSize: 32, onDark: true),
                              TextButton(
                                onPressed: _skip,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: .12,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text('Overslaan'),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 8 : 18),
                          SizedBox(
                            height: heroHeight,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: OnboardingHero(
                                key: ValueKey(slide.hero),
                                kind: slide.hero,
                                compact: compact,
                              ),
                            ),
                          ),
                          const Spacer(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Column(
                              key: ValueKey(slide.title),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide.kicker,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colors.orange,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .8,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  slide.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: compact ? 40 : 46,
                                        height: .98,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  slide.body,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: .78,
                                        ),
                                        height: 1.35,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const _SocialProofStrip(),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: List.generate(_slides.length, (
                                    index,
                                  ) {
                                    final selected = index == _index;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      margin: const EdgeInsets.only(right: 8),
                                      height: 7,
                                      width: selected ? 26 : 7,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: .28,
                                              ),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              SizedBox(
                                height: 58,
                                child: ElevatedButton.icon(
                                  onPressed: _next,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: colors.green,
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  icon: Icon(
                                    isLast
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                  ),
                                  label: Text(
                                    isLast ? 'Aan de slag' : 'Verder',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialProofStrip extends StatelessWidget {
  const _SocialProofStrip();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Row(
      children: [
        const SizedBox(
          width: 84,
          height: 34,
          child: Stack(
            children: [
              Positioned(left: 0, child: _ProofAvatar(tone: 0)),
              Positioned(left: 24, child: _ProofAvatar(tone: 1)),
              Positioned(left: 48, child: _ProofAvatar(tone: 2)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Mensen in je buurt\ndoen al mee',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: .82),
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        Icon(Icons.favorite_rounded, color: colors.orange, size: 22),
      ],
    );
  }
}

class _ProofAvatar extends StatelessWidget {
  const _ProofAvatar({required this.tone});

  final int tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final avatarColor = switch (tone) {
      0 => const Color(0xFF347E70),
      1 => const Color(0xFF93623B),
      _ => const Color(0xFF5E8B3A),
    };

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
        border: Border.all(color: colors.green, width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
    );
  }
}

class _GreenGrain extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .035)
      ..strokeWidth = 1.2;
    for (var y = 16.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 18), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GreenGrain oldDelegate) => false;
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.kicker,
    required this.title,
    required this.body,
    required this.hero,
  });

  final String kicker;
  final String title;
  final String body;
  final OnboardingHeroKind hero;
}
