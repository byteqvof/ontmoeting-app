import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../../../core/widgets/toch_snack_bar.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.greenPressed,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.greenPressed,
                        colors.green,
                        colors.cream,
                        colors.cream,
                      ],
                      stops: const [0, .34, .34, 1],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: Row(
                        children: [
                          TochRoundButton(
                            icon: Icons.close_rounded,
                            onPressed: () => context.pop(),
                            dark: true,
                          ),
                          Expanded(
                            child: Text(
                              'Stop wanneer je wil',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: .76),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 42),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
                        children: [
                          Row(
                            children: [
                              Text(
                                'toch+',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 58,
                                      height: .92,
                                    ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: colors.orange,
                                size: 30,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Meer ontdekken, eerder opvallen. Voor wie er vaker op uit wil.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: .74),
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 34),
                          const _PremiumFeatureCard(),
                          const SizedBox(height: 18),
                          const _PricingOption(
                            title: 'Per jaar',
                            subtitle: 'EUR 39,99 - bespaar 33%',
                            price: 'EUR 3,33/mnd',
                            selected: true,
                            tag: 'populair',
                          ),
                          const SizedBox(height: 10),
                          const _PricingOption(
                            title: 'Per maand',
                            subtitle: 'maandelijks opzegbaar',
                            price: 'EUR 4,99/mnd',
                          ),
                          const SizedBox(height: 22),
                          TochPrimaryButton(
                            label: 'Probeer 7 dagen gratis',
                            icon: Icons.auto_awesome_rounded,
                            onPressed: () {
                              showTochSnackBar(
                                context,
                                'toch+ betalingen staan nog niet live in beta.',
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Daarna EUR 39,99/jaar. Je kunt altijd stoppen.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.ink3,
                                  fontWeight: FontWeight.w800,
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
      ),
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  const _PremiumFeatureCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: TochShadows.raised(colors),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            _PremiumFeatureRow(
              icon: Icons.explore_rounded,
              title: 'Groter bereik',
              body: 'Zie activiteiten verder weg dan je standaard afstand.',
            ),
            _PremiumFeatureRow(
              icon: Icons.auto_awesome_rounded,
              title: 'Jouw plek bovenaan',
              body: 'Je activiteit valt extra op in de feed.',
            ),
            _PremiumFeatureRow(
              icon: Icons.notifications_active_outlined,
              title: 'Slimme meldingen',
              body: 'Hoor het zodra er iets is dat bij je past.',
            ),
            _PremiumFeatureRow(
              icon: Icons.share_location_rounded,
              title: 'Locatie delen',
              body: 'Deel je route met een gekozen contact zodra dit live is.',
              last: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeatureRow extends StatelessWidget {
  const _PremiumFeatureRow({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.green100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox.square(
              dimension: 46,
              child: Icon(icon, color: colors.green, size: 22),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.ink3,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
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

class _PricingOption extends StatelessWidget {
  const _PricingOption({
    required this.title,
    required this.subtitle,
    required this.price,
    this.selected = false,
    this.tag,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? colors.green : Colors.transparent,
          width: selected ? 2 : 1,
        ),
        boxShadow: TochShadows.card(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        TochPill(
                          label: tag!,
                          compact: true,
                          active: true,
                          backgroundColor: colors.orange,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.ink3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? colors.green : colors.line,
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
