import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      appBar: AppBar(
        title: const Text('Info over TOCH'),
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
              _InfoHero(),
              SizedBox(height: TochSpacing.md),
              _InfoTile(
                icon: Icons.explore_outlined,
                title: 'Ontdekken',
                body:
                    'Je ziet activiteiten in de buurt op basis van locatie, afstand, datum en filters. Je exacte live locatie wordt niet als eventlocatie opgeslagen.',
              ),
              _InfoTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Iets organiseren',
                body:
                    'Maak alleen aan wat je echt gaat doen. Kies een concrete meetingplek, tijd, groepsgrootte en eventuele doelgroep.',
              ),
              _InfoTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat',
                body:
                    'Chat is bedoeld om praktisch af te stemmen. Oude chats van afgelopen activiteiten worden gesloten en daarna opgeschoond.',
              ),
              _InfoTile(
                icon: Icons.verified_user_outlined,
                title: 'Verificatie',
                body:
                    'Telefoon bevestigd beperkt wegwerpaccounts. Identiteit bevestigd betekent alleen dat iemand zijn identiteit heeft geverifieerd.',
              ),
              _InfoTile(
                icon: Icons.tune_rounded,
                title: 'Filters',
                body:
                    'Gebruik afstand en datum voor snelle keuzes. Extra filters helpen als je zoekt op categorie, doelgroep, beschikbaarheid of sortering.',
              ),
              _InfoTile(
                icon: Icons.flag_outlined,
                title: 'Melden en blokkeren',
                body:
                    'Blokkeer iemand als je geen contact wilt. Meld gedrag of accounts die niet kloppen; rapporten zijn alleen voor moderatie zichtbaar.',
              ),
              _InfoTile(
                icon: Icons.notifications_outlined,
                title: 'Meldingen',
                body:
                    'Chatmeldingen gebruiken push als je dit toestaat. Je telefoonnummer, chattekst en exacte GPS gaan niet naar analytics.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoHero extends StatelessWidget {
  const _InfoHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.green,
        borderRadius: BorderRadius.circular(TochRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TOCH is voor laagdrempelig afspreken in de buurt.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.cream,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: TochSpacing.sm),
            Text(
              'Geen groot evenement, geen druk. Je deelt wat je toch al gaat doen en anderen kunnen aansluiten.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.cream.withValues(alpha: .88),
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.green100,
                  borderRadius: BorderRadius.circular(TochRadius.md),
                ),
                child: SizedBox.square(
                  dimension: 42,
                  child: Icon(icon, color: colors.green, size: 22),
                ),
              ),
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
