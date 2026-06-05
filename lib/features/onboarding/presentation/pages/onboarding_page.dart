import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_wordmark.dart';
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
      kicker: 'Het idee',
      title: 'Geen evenement.\nGewoon meedoen.',
      body:
          'Mensen delen wat ze toch al gaan doen. Jij sluit aan wanneer je zin hebt, zonder gedoe of druk.',
      hero: OnboardingHeroKind.activity,
    ),
    _OnboardingSlide(
      kicker: 'Ontdekken',
      title: 'Zie wat er vlakbij\ngebeurt.',
      body:
          'Vissen, koffie, wandelen, gamen. Spontane activiteiten bij jou in de buurt, vandaag of dit weekend.',
      hero: OnboardingHeroKind.nearby,
    ),
    _OnboardingSlide(
      kicker: 'Vertrouwen',
      title: 'Lage drempel.\nEchte mensen.',
      body:
          'Geverifieerde profielen en een eerlijke opkomstscore. Je weet met wie je afspreekt.',
      hero: OnboardingHeroKind.trust,
    ),
  ];

  void _skip() => context.go(AppRoutes.register);

  void _next() {
    if (_index == _slides.length - 1) {
      context.go(AppRoutes.register);
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final horizontalPadding = constraints.maxWidth < 390 ? 18.0 : 22.0;
            final heroHeight = (constraints.maxHeight * (compact ? .34 : .40))
                .clamp(260.0, compact ? 300.0 : 360.0);

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                20,
              ),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const TochWordmark(fontSize: 28),
                    TextButton(
                      onPressed: _skip,
                      child: const Text('Overslaan'),
                    ),
                  ],
                ),
                SizedBox(height: compact ? TochSpacing.sm : TochSpacing.md),
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
                SizedBox(height: compact ? TochSpacing.lg : TochSpacing.xl),
                Text(
                  slide.kicker,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.orange,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: TochSpacing.sm),
                Text(
                  slide.title,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: compact ? 36 : 42,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: TochSpacing.sm),
                Text(slide.body, style: Theme.of(context).textTheme.bodyLarge),
                SizedBox(height: compact ? TochSpacing.lg : TochSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(_slides.length, (index) {
                          final selected = index == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            margin: const EdgeInsets.only(right: 8),
                            height: 7,
                            width: selected ? 24 : 7,
                            decoration: BoxDecoration(
                              color: selected ? colors.green : colors.line,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                      label: Text(isLast ? 'Aan de slag' : 'Verder'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
