import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/activity_chat_notice.dart';
import '../controllers/activity_chat_notice_controller.dart';

class ActivityChatNoticeHost extends StatefulWidget {
  const ActivityChatNoticeHost({required this.child, super.key});

  final Widget child;

  @override
  State<ActivityChatNoticeHost> createState() => _ActivityChatNoticeHostState();
}

class _ActivityChatNoticeHostState extends State<ActivityChatNoticeHost>
    with SingleTickerProviderStateMixin {
  final ActivityChatNoticeController _controller = sl();
  StreamSubscription<ActivityChatNotice>? _noticeSubscription;
  late final AnimationController _toastController;
  Timer? _dismissTimer;
  ActivityChatNotice? _visibleNotice;

  @override
  void initState() {
    super.initState();
    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 360),
    );
    _noticeSubscription = _controller.notices.listen(_showNotice);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAuthState(context.read<AuthBloc>().state);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _noticeSubscription?.cancel();
    _toastController.dispose();
    unawaited(_controller.stop());
    super.dispose();
  }

  void _syncAuthState(AuthState state) {
    if (state is AuthAuthenticated) {
      unawaited(_controller.start());
      return;
    }
    unawaited(_controller.stop());
  }

  void _showNotice(ActivityChatNotice notice) {
    if (!mounted || _controller.isActivityOpen(notice.activityId)) {
      return;
    }

    AppLogger.debug('Showing chat notice overlay');
    _dismissTimer?.cancel();
    setState(() {
      _visibleNotice = notice;
    });
    _toastController.forward(from: 0);
    _dismissTimer = Timer(const Duration(seconds: 5), _dismissNotice);
  }

  Future<void> _dismissNotice() async {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (!_toastController.isDismissed) {
      await _toastController.reverse();
    }
    if (mounted) {
      setState(() {
        _visibleNotice = null;
      });
    }
  }

  void _openMessages() {
    _controller.clearUnread();
    unawaited(_dismissNotice());
    context.go(AppRoutes.activityMessages);
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotice = _visibleNotice;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _syncAuthState(state),
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          if (visibleNotice != null)
            Positioned(
              top: topInset + 12,
              left: 14,
              right: 14,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _toastController,
                  curve: Curves.easeOut,
                  reverseCurve: Curves.easeIn,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.18),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _toastController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 452),
                      child: ActivityChatNoticeToast(
                        notice: visibleNotice,
                        onOpen: _openMessages,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ActivityChatNoticeToast extends StatelessWidget {
  const ActivityChatNoticeToast({
    required this.notice,
    required this.onOpen,
    super.key,
  });

  final ActivityChatNotice notice;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: .96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.line),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: .12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              _NoticeAvatar(notice: notice),
              const SizedBox(width: TochSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notice.activityTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colors.green,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'nu',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.green700.withValues(alpha: .45),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.ink.withValues(alpha: .78),
                          height: 1.22,
                        ),
                        children: [
                          TextSpan(
                            text: '${notice.senderName}: ',
                            style: TextStyle(
                              color: colors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(text: notice.preview),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TochSpacing.sm),
              _NoticeActionButton(onPressed: onOpen),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeAvatar extends StatelessWidget {
  const _NoticeAvatar({required this.notice});

  final ActivityChatNotice notice;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final avatarUrl = notice.senderAvatarUrl;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.orange,
        boxShadow: [
          BoxShadow(
            color: colors.orange.withValues(alpha: .35),
            blurRadius: 0,
            spreadRadius: 3,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 25,
        backgroundColor: colors.orange,
        foregroundColor: Colors.white,
        backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
        child: avatarUrl == null
            ? Text(
                notice.senderInitials.isEmpty ? '?' : notice.senderInitials,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              )
            : null,
      ),
    );
  }
}

class _NoticeActionButton extends StatelessWidget {
  const _NoticeActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Material(
      color: colors.green,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox.square(
          dimension: 42,
          child: Center(
            child: Text(
              'ig',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
