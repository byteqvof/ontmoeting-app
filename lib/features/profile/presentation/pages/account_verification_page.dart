import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/account_trust_service.dart';
import '../../domain/entities/profile_trust.dart';

class AccountVerificationPage extends StatefulWidget {
  const AccountVerificationPage({super.key});

  @override
  State<AccountVerificationPage> createState() =>
      _AccountVerificationPageState();
}

class _AccountVerificationPageState extends State<AccountVerificationPage> {
  late Future<ProfileTrust> _trustFuture = _loadTrust();

  Future<ProfileTrust> _loadTrust() {
    return sl<AccountTrustService>().syncTrust();
  }

  void _refresh() {
    setState(() {
      _trustFuture = _loadTrust();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(
                    children: [
                      TochRoundButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vertrouwen & veiligheid',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colors.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<ProfileTrust>(
                  future: _trustFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Center(
                        child: CircularProgressIndicator(color: colors.green),
                      );
                    }

                    if (snapshot.hasError || snapshot.data == null) {
                      return _TrustLoadError(onRetry: _refresh);
                    }

                    final trust = snapshot.data!;
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
                      children: [
                        _TrustScoreCard(trust: trust),
                        const SizedBox(height: TochSpacing.md),
                        const _SectionTitle('Jouw verificaties'),
                        _VerificationListCard(trust: trust),
                        const SizedBox(height: TochSpacing.md),
                        const _SectionTitle('Veiligheidstips'),
                        const _SafetyTipsCard(),
                        const SizedBox(height: TochSpacing.md),
                        const _SafetyNote(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustScoreCard extends StatelessWidget {
  const _TrustScoreCard({required this.trust});

  final ProfileTrust trust;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final progress = trust.reputationScore.clamp(0, 100) / 100;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        boxShadow: TochShadows.card(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          children: [
            SizedBox.square(
              dimension: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 10,
                    color: colors.line,
                  ),
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    color: colors.green,
                    backgroundColor: Colors.transparent,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${trust.reputationScore}',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: colors.green,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                        ),
                        Text(
                          'score',
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
            const SizedBox(height: 14),
            Text(
              trust.reputationLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              'Gebaseerd op echte deelname, opkomst en moderatiegegevens.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.ink3,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationListCard extends StatelessWidget {
  const _VerificationListCard({required this.trust});

  final ProfileTrust trust;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        boxShadow: TochShadows.card(colors),
      ),
      child: Column(
        children: [
          _StatusRow(
            icon: Icons.phone_android_rounded,
            title: 'Telefoonnummer',
            value: trust.phoneStatusLabel,
            isConfirmed: trust.phoneVerified,
            helper: 'Helpt wegwerpaccounts, spam en bots beperken.',
          ),
          _DividerLine(),
          _StatusRow(
            icon: Icons.badge_outlined,
            title: 'Identiteit',
            value: trust.identityStatusLabel,
            isConfirmed: trust.identityVerified,
            helper:
                'Deze gebruiker heeft zijn identiteit geverifieerd. Dit zegt niets over gedrag.',
          ),
          _DividerLine(),
          _StatusRow(
            icon: Icons.trending_up_rounded,
            title: 'Reputatie',
            value: '${trust.reputationLabel} - ${trust.reputationScore}/100',
            isConfirmed: trust.reputationScore > 0,
            helper: 'Transparant opgebouwd uit afgeronde interacties.',
          ),
          _DividerLine(),
          _StatusRow(
            icon: Icons.cake_outlined,
            title: 'Leeftijd',
            value: trust.ageVerified
                ? 'Leeftijd bevestigd'
                : 'Leeftijd niet bevestigd',
            isConfirmed: trust.ageVerified,
            helper: 'Wordt pas actief bij echte identiteitscontrole.',
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isConfirmed,
    required this.helper,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isConfirmed;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: isConfirmed ? colors.green100 : colors.orangeSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox.square(
              dimension: 38,
              child: Icon(
                icon,
                color: isConfirmed ? colors.green : colors.orange,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.ink4,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  helper,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.ink3,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: isConfirmed ? colors.green100 : colors.orangeSoft,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 28,
              child: Icon(
                isConfirmed ? Icons.check_rounded : Icons.info_outline_rounded,
                color: isConfirmed ? colors.green : colors.orange,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyTipsCard extends StatelessWidget {
  const _SafetyTipsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        boxShadow: TochShadows.card(colors),
      ),
      child: const Column(
        children: [
          _TipRow(
            icon: Icons.place_outlined,
            title: 'Ontmoet op openbare plekken',
            text: 'Kies voor eerste ontmoetingen een toegankelijke plek.',
          ),
          _DividerLine(),
          _TipRow(
            icon: Icons.verified_user_outlined,
            title: 'Verificatie is echtheid',
            text: 'Het bevestigt accountgegevens, maar garandeert geen gedrag.',
          ),
          _DividerLine(),
          _TipRow(
            icon: Icons.flag_outlined,
            title: 'Meld wat niet klopt',
            text: 'Gebruik melden bij intimidatie, spam of ongepast gedrag.',
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.green100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox.square(
              dimension: 36,
              child: Icon(icon, color: colors.green, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.ink3,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
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

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8E6E1),
        borderRadius: BorderRadius.circular(TochRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFC0492F),
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bij een noodsituatie: bel altijd 112. TOCH-medewerkers zijn geen vervanging voor hulpdiensten. We bewaren alleen noodzakelijke verificatiestatussen.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFC0492F),
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.toch.ink,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: context.toch.line);
  }
}

class _TrustLoadError extends StatelessWidget {
  const _TrustLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.xl),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(TochRadius.lg),
            boxShadow: TochShadows.card(colors),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, color: colors.green, size: 40),
                const SizedBox(height: TochSpacing.md),
                Text(
                  'Status laden lukt niet',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: TochSpacing.md),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Opnieuw proberen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
