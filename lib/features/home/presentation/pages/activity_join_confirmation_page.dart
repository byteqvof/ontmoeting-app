import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../domain/entities/home_activity.dart';
import '../widgets/home_category_style.dart';

class ActivityJoinConfirmationPage extends StatefulWidget {
  const ActivityJoinConfirmationPage({
    required this.activity,
    this.onOpenChat,
    this.onBackToDiscover,
    this.requestPushPermission,
    super.key,
  });

  final HomeActivity activity;
  final VoidCallback? onOpenChat;
  final VoidCallback? onBackToDiscover;
  final Future<PushNotificationPermissionResult> Function()?
  requestPushPermission;

  @override
  State<ActivityJoinConfirmationPage> createState() =>
      _ActivityJoinConfirmationPageState();
}

class _ActivityJoinConfirmationPageState
    extends State<ActivityJoinConfirmationPage> {
  bool _isRequestingPush = false;
  PushNotificationPermissionResult? _pushResult;

  Future<void> _requestPushPermission() async {
    if (_isRequestingPush) {
      return;
    }

    setState(() {
      _isRequestingPush = true;
      _pushResult = null;
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
      _pushResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.greenDeep,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.green, colors.greenPressed, colors.greenDeep],
            stops: const [0, .48, 1],
          ),
        ),
        child: Stack(
          children: [
            const _ConfettiLayer(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 820;

                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                24,
                                compact ? 10 : 24,
                                24,
                                compact ? 8 : 20,
                              ),
                              child: Column(
                                children: [
                                  const Spacer(),
                                  _CheckMarkHero(
                                    color: colors.green,
                                    compact: compact,
                                  ),
                                  SizedBox(height: compact ? 12 : 26),
                                  Text(
                                    'Je gaat!',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontSize: compact ? 34 : 40,
                                          height: 1,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  SizedBox(height: compact ? 8 : 12),
                                  Text(
                                    'Je aanmelding is bevestigd. De groepschat staat klaar.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: .78,
                                          ),
                                          fontWeight: FontWeight.w800,
                                          height: 1.35,
                                        ),
                                  ),
                                  SizedBox(height: compact ? 10 : 28),
                                  _JoinedActivityCard(
                                    activity: widget.activity,
                                    compact: compact,
                                  ),
                                  SizedBox(height: compact ? 8 : 14),
                                  _ChatNotificationOptInCard(
                                    compact: compact,
                                    isBusy: _isRequestingPush,
                                    result: _pushResult,
                                    onPressed: _requestPushPermission,
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed:
                                          widget.onOpenChat ??
                                          () => _openChat(context),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colors.card,
                                        foregroundColor: colors.green,
                                        minimumSize: Size.fromHeight(
                                          compact ? 46 : 56,
                                        ),
                                        shape: const StadiumBorder(),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                      ),
                                      label: const Text('Open de chat'),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 6 : 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TextButton(
                                      onPressed:
                                          widget.onBackToDiscover ??
                                          () => _backToDiscover(context),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withValues(alpha: .10),
                                        foregroundColor: Colors.white
                                            .withValues(alpha: .78),
                                        minimumSize: Size.fromHeight(
                                          compact ? 44 : 52,
                                        ),
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: .20,
                                          ),
                                          width: 1.5,
                                        ),
                                        shape: const StadiumBorder(),
                                        textStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      child: const Text('Terug naar ontdekken'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    context.go(
      AppRoutes.activityChatPath(widget.activity.id, from: 'joined'),
      extra: widget.activity,
    );
  }

  void _backToDiscover(BuildContext context) {
    if (context.canPop()) {
      context.pop(widget.activity);
      return;
    }
    context.go(AppRoutes.home);
  }
}

class _ChatNotificationOptInCard extends StatelessWidget {
  const _ChatNotificationOptInCard({
    required this.compact,
    required this.isBusy,
    required this.result,
    required this.onPressed,
  });

  final bool compact;
  final bool isBusy;
  final PushNotificationPermissionResult? result;
  final VoidCallback onPressed;

  bool get _isEnabled =>
      result == PushNotificationPermissionResult.authorized ||
      result == PushNotificationPermissionResult.provisional;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        border: Border.all(color: Colors.white.withValues(alpha: .20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const SizedBox.square(
                    dimension: 42,
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis geen chatbericht',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Zet meldingen aan voor updates van deze groepschat.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: .74),
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 8),
              Text(
                _chatNotificationMessage(result!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _isEnabled
                      ? colors.green100
                      : Colors.white.withValues(alpha: .74),
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: isBusy || _isEnabled ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: .72),
                foregroundColor: colors.green,
                disabledForegroundColor: colors.green,
                minimumSize: Size(0, compact ? 36 : 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              child: isBusy
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.green,
                      ),
                    )
                  : Text(_isEnabled ? 'Aangezet' : 'Chatmeldingen aanzetten'),
            ),
          ],
        ),
      ),
    );
  }
}

String _chatNotificationMessage(PushNotificationPermissionResult result) {
  return switch (result) {
    PushNotificationPermissionResult.authorized => 'Chatmeldingen staan aan.',
    PushNotificationPermissionResult.provisional =>
      'Chatmeldingen zijn voorlopig toegestaan.',
    PushNotificationPermissionResult.denied =>
      'Meldingen zijn geweigerd. Je kunt dit later aanpassen.',
    PushNotificationPermissionResult.unavailable =>
      'Meldingen zijn nu niet beschikbaar.',
    PushNotificationPermissionResult.failed =>
      'Meldingen aanzetten lukt nu niet. Probeer het later opnieuw.',
  };
}

class _CheckMarkHero extends StatelessWidget {
  const _CheckMarkHero({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .07),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 24),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: SizedBox.square(
            dimension: compact ? 58 : 92,
            child: Icon(
              Icons.check_rounded,
              color: color,
              size: compact ? 40 : 60,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiLayer extends StatelessWidget {
  const _ConfettiLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          _ConfettiPiece(top: 82, left: 48, color: TochColors.orange),
          _ConfettiPiece(top: 136, right: 48, color: Colors.white, small: true),
          _ConfettiPiece(top: 212, left: 86, color: TochColors.green200),
          _ConfettiPiece(top: 244, right: 34, color: TochColors.orangeSoft),
          _ConfettiPiece(top: 310, left: 30, color: TochColors.orange),
          _ConfettiPiece(top: 96, right: 118, color: TochColors.verified),
        ],
      ),
    );
  }
}

class _ConfettiPiece extends StatelessWidget {
  const _ConfettiPiece({
    required this.top,
    required this.color,
    this.left,
    this.right,
    this.small = false,
  });

  final double top;
  final double? left;
  final double? right;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: small ? .5 : -.35,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: small ? .58 : .84),
            borderRadius: BorderRadius.circular(3),
          ),
          child: SizedBox(width: small ? 9 : 11, height: small ? 12 : 22),
        ),
      ),
    );
  }
}

class _JoinedActivityCard extends StatelessWidget {
  const _JoinedActivityCard({required this.activity, required this.compact});

  final HomeActivity activity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        boxShadow: TochShadows.raised(colors),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, compact ? 12 : 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact) ...[
              Row(
                children: [
                  TochPill(
                    label: activity.category.label,
                    icon: activity.category.icon,
                    compact: true,
                    backgroundColor: activity.category.backgroundColor,
                    foregroundColor: activity.category.color,
                  ),
                  const SizedBox(width: 8),
                  TochPill(
                    label: 'Bevestigd',
                    compact: true,
                    backgroundColor: colors.green100,
                    foregroundColor: colors.verified,
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Text(
              activity.title,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
            Divider(height: 1, color: colors.line),
            SizedBox(height: compact ? 8 : 12),
            _SuccessMetaRow(
              icon: Icons.calendar_today_rounded,
              label: [
                if (activity.dateLabel.isNotEmpty) activity.dateLabel,
                if (activity.timeLabel.isNotEmpty) activity.timeLabel,
              ].join(' - '),
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              _SuccessMetaRow(
                icon: Icons.place_outlined,
                label: activity.meetingPoint.isEmpty
                    ? activity.locationName
                    : activity.meetingPoint,
              ),
              const SizedBox(height: 12),
              Text(
                'Jij + ${activity.participants.length} anderen gaan mee',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.ink3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessMetaRow extends StatelessWidget {
  const _SuccessMetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Row(
      children: [
        Icon(icon, color: colors.ink4, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.ink3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
