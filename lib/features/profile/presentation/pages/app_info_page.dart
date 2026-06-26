import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _StoryHero(colors: colors)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 118),
                    sliver: SliverList.list(
                      children: const [
                        TochSectionLabel('Waarom TOCH?'),
                        SizedBox(height: 12),
                        _BodyParagraph(
                          'Veel mensen kennen genoeg mensen, maar missen toch net iemand om iets mee te doen. De stap is vaak te groot, het moment gaat voorbij.',
                        ),
                        _BodyParagraph(
                          'TOCH is anders. Geen matches afwachten en geen groot evenement opzetten. Je kijkt wat er vandaag bij jou in de buurt gebeurt en sluit gewoon aan.',
                        ),
                        _QuoteBlock(
                          quote: 'Contact hoeft niet ingewikkeld te zijn.',
                          attribution: 'Ons uitgangspunt',
                        ),
                        _BodyParagraph(
                          'We geloven dat de meeste mensen gewoon iets willen doen. Een avondje vissen, een wandeling maken of samen koffie drinken. TOCH maakt die kleine uitnodiging zichtbaar.',
                        ),
                        Divider(height: 42),
                        TochSectionLabel('Hoe het werkt'),
                        SizedBox(height: 12),
                        _BodyParagraph(
                          'Iemand organiseert iets simpels. Jij ziet het. Je meldt je aan. De activiteit begint, jullie ontmoeten elkaar, en daarna verdwijnt de app weer naar de achtergrond.',
                        ),
                        _BigQuote(),
                        _BodyParagraph(
                          'Geen verplichtingen, geen abonnement nodig om mee te doen, geen data die doorverkocht wordt. Gewoon mensen bij mensen brengen.',
                        ),
                        _ClosingCard(),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                    decoration: BoxDecoration(
                      color: colors.cream.withValues(alpha: .96),
                      boxShadow: [
                        BoxShadow(
                          color: colors.ink.withValues(alpha: .08),
                          blurRadius: 24,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: TochPrimaryButton(
                      label: 'Ik ga toch - ga je mee?',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.pop(),
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

class _StoryHero extends StatelessWidget {
  const _StoryHero({required this.colors});

  final TochTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.green,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TochRoundButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => context.pop(),
                dark: true,
              ),
              const SizedBox(height: 40),
              Text(
                'Ons verhaal',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.orange,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Eenzaamheid los\nje niet online op.',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 42,
                  height: 1,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'TOCH is gemaakt omdat contact simpeler moet. Echt contact, offline.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: .74),
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _StoryChip(icon: Icons.phishing_rounded, label: 'Vissen'),
                  _StoryChip(
                    icon: Icons.directions_walk_rounded,
                    label: 'Wandelen',
                  ),
                  _StoryChip(icon: Icons.coffee_rounded, label: 'Koffie'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryChip extends StatelessWidget {
  const _StoryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(TochRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyParagraph extends StatelessWidget {
  const _BodyParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colors.ink2,
          fontWeight: FontWeight.w700,
          height: 1.52,
        ),
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.quote, required this.attribution});

  final String quote;
  final String attribution;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.greenPressed,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"$quote"',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '- $attribution',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.orange,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigQuote extends StatelessWidget {
  const _BigQuote();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        '"Ik ga toch.\nGa je mee?"',
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          color: colors.green,
          fontSize: 36,
          height: 1.03,
        ),
      ),
    );
  }
}

class _ClosingCard extends StatelessWidget {
  const _ClosingCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.green100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'TOCH is gebouwd vanuit Maastricht, voor iedereen die gewoon wil doen. Elke dag zijn er mensen vlakbij die hetzelfde voelen. Sluit aan.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.green,
            fontWeight: FontWeight.w900,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
