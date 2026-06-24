import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class PrivacyLocationPage extends StatelessWidget {
  const PrivacyLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      appBar: AppBar(
        title: const Text('Privacy en locatie'),
        backgroundColor: colors.cream,
        foregroundColor: colors.ink,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: const [
              _PrivacyTile(
                icon: Icons.my_location_rounded,
                title: 'Locatie gebruiken',
                body:
                    'TOCH gebruikt je locatie om activiteiten in de buurt te tonen. Je live locatie wordt niet als eventlocatie opgeslagen.',
              ),
              _PrivacyTile(
                icon: Icons.place_outlined,
                title: 'Meetingplek',
                body:
                    'Bij een activiteit wordt alleen de plek opgeslagen die de organisator zelf kiest, zoals een plein, cafe of adres.',
              ),
              _PrivacyTile(
                icon: Icons.phone_android_rounded,
                title: 'Telefoonstatus',
                body:
                    'Je telefoonnummer blijft in Supabase Auth. In de publieke database bewaren we alleen of je telefoon bevestigd is.',
              ),
              _PrivacyTile(
                icon: Icons.analytics_outlined,
                title: 'Analytics',
                body:
                    'Analytics mag geen telefoonnummer, chattekst, exacte GPS of vrije rapporttekst bevatten.',
              ),
              _PrivacyTile(
                icon: Icons.flag_outlined,
                title: 'Meldingen en blokkades',
                body:
                    'Rapporten, blokkades en moderatiegegevens zijn afgeschermd en niet publiek zichtbaar.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.only(bottom: TochSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(TochRadius.lg),
          border: Border.all(color: colors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TochSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.green, size: 24),
              const SizedBox(width: TochSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.green700.withValues(alpha: .72),
                        height: 1.35,
                        fontWeight: FontWeight.w700,
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
