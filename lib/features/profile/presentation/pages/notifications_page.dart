import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      appBar: AppBar(
        title: const Text('Meldingen'),
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
              _NotificationTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chatmeldingen',
                body:
                    'Je krijgt meldingen voor nieuwe chatberichten bij activiteiten waar je aan meedoet.',
              ),
              _NotificationTile(
                icon: Icons.event_available_outlined,
                title: 'Activiteiten',
                body:
                    'Activiteitsmeldingen gebruiken we voor updates rond activiteiten, zoals wijzigingen of herinneringen.',
              ),
              _NotificationTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push toestaan',
                body:
                    'Pushmeldingen werken alleen als je toestemming geeft op je telefoon. Je kunt dit later in Android-instellingen aanpassen.',
              ),
              _NotificationTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Geen gevoelige inhoud',
                body:
                    'Meldingen en analytics bevatten geen telefoonnummer, chattekst, exacte GPS of vrije rapporttekst.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
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
