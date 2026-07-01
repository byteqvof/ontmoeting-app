import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../domain/entities/home_activity.dart';
import '../widgets/home_category_style.dart';

class ActivityJoinConfirmationPage extends StatelessWidget {
  const ActivityJoinConfirmationPage({
    required this.activity,
    this.onOpenChat,
    this.onBackToDiscover,
    super.key,
  });

  final HomeActivity activity;
  final VoidCallback? onOpenChat;
  final VoidCallback? onBackToDiscover;

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
                      final compact = constraints.maxHeight < 660;

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          compact ? 14 : 24,
                          24,
                          compact ? 12 : 20,
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
                              style: Theme.of(context).textTheme.displayMedium
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
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: .78),
                                    fontWeight: FontWeight.w800,
                                    height: 1.35,
                                  ),
                            ),
                            SizedBox(height: compact ? 14 : 28),
                            _JoinedActivityCard(
                              activity: activity,
                              compact: compact,
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    onOpenChat ?? () => _openChat(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.card,
                                  foregroundColor: colors.green,
                                  minimumSize: Size.fromHeight(
                                    compact ? 50 : 56,
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
                            SizedBox(height: compact ? 8 : 10),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed:
                                    onBackToDiscover ??
                                    () => context.go(AppRoutes.home),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: .10,
                                  ),
                                  foregroundColor: Colors.white.withValues(
                                    alpha: .78,
                                  ),
                                  minimumSize: Size.fromHeight(
                                    compact ? 48 : 52,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: .20),
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
      AppRoutes.activityChatPath(activity.id, from: 'joined'),
      extra: activity,
    );
  }
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
        padding: EdgeInsets.all(compact ? 14 : 24),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: SizedBox.square(
            dimension: compact ? 66 : 92,
            child: Icon(
              Icons.check_rounded,
              color: color,
              size: compact ? 46 : 60,
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
