import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/push_notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({this.requestPushPermission, super.key});

  final Future<PushNotificationPermissionResult> Function()?
  requestPushPermission;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isRequestingPush = false;
  String? _pushStatusMessage;

  Future<void> _requestPushPermission() async {
    if (_isRequestingPush) {
      return;
    }

    setState(() {
      _isRequestingPush = true;
      _pushStatusMessage = null;
    });

    final request =
        widget.requestPushPermission ??
        sl<PushNotificationService>()
            .requestPermissionAndRegisterForCurrentUser;

    final result = await request();
    if (!mounted) {
      return;
    }

    setState(() {
      _isRequestingPush = false;
      _pushStatusMessage = _pushMessageFor(result);
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
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      TochRoundButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => context.pop(),
                        size: 42,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Meldingen',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                    children: [
                      const _NotificationHero(),
                      const SizedBox(height: 18),
                      const _NotificationTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Chatmeldingen',
                        body:
                            'Je krijgt meldingen voor nieuwe chatberichten bij activiteiten waar je aan meedoet.',
                        active: true,
                      ),
                      const _NotificationTile(
                        icon: Icons.event_available_outlined,
                        title: 'Activiteiten',
                        body:
                            'Updates rond activiteiten, wijzigingen en herinneringen komen hier samen.',
                        active: true,
                      ),
                      _NotificationTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Push toestaan',
                        body:
                            'Push werkt alleen als je toestemming geeft op je telefoon. Je kunt dit later aanpassen in Android-instellingen.',
                        actionLabel: 'Push toestaan',
                        isBusy: _isRequestingPush,
                        statusMessage: _pushStatusMessage,
                        onActionPressed: _requestPushPermission,
                      ),
                      const _NotificationTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy',
                        body:
                            'Meldingen bevatten geen telefoonnummer, chattekst, exacte GPS of vrije rapporttekst.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _pushMessageFor(PushNotificationPermissionResult result) {
  return switch (result) {
    PushNotificationPermissionResult.authorized => 'Pushmeldingen staan aan.',
    PushNotificationPermissionResult.provisional =>
      'Pushmeldingen zijn voorlopig toegestaan.',
    PushNotificationPermissionResult.denied =>
      'Pushmeldingen zijn geweigerd. Je kunt dit later in de instellingen aanpassen.',
    PushNotificationPermissionResult.unavailable =>
      'Pushmeldingen zijn nu niet beschikbaar.',
    PushNotificationPermissionResult.failed =>
      'Pushmeldingen inschakelen lukt nu niet. Probeer het later opnieuw.',
  };
}

class _NotificationHero extends StatelessWidget {
  const _NotificationHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.green,
        borderRadius: BorderRadius.circular(30),
        boxShadow: TochShadows.card(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const SizedBox.square(
                dimension: 64,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis niks praktisch',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Alleen relevante updates rond activiteiten en chats.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: .78),
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    this.active = false,
    this.actionLabel,
    this.statusMessage,
    this.isBusy = false,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool active;
  final String? actionLabel;
  final String? statusMessage;
  final bool isBusy;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(26),
          boxShadow: TochShadows.card(colors),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: active ? colors.green100 : colors.surface2,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(icon, color: colors.green, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        if (active)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.ink3,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (statusMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        statusMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.green,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    if (actionLabel != null) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: isBusy ? null : onActionPressed,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: const StadiumBorder(),
                        ),
                        child: isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(actionLabel!),
                      ),
                    ],
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
