import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/pip_mascot.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/toch_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/activity_chat_message.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/usecases/get_activity_chat_messages.dart';
import '../../domain/usecases/mark_activity_chat_read.dart';
import '../../domain/usecases/send_activity_chat_message.dart';
import '../controllers/activity_chat_notice_controller.dart';
import '../controllers/activity_chat_realtime_controller.dart';
import '../widgets/activity_status_labels.dart';

class ActivityChatPage extends StatefulWidget {
  const ActivityChatPage({
    required this.activity,
    this.backFallbackRoute,
    super.key,
  });

  final HomeActivity activity;
  final String? backFallbackRoute;

  @override
  State<ActivityChatPage> createState() => _ActivityChatPageState();
}

class _ActivityChatPageState extends State<ActivityChatPage>
    with WidgetsBindingObserver {
  final GetActivityChatMessages _getMessages = sl();
  final SendActivityChatMessage _sendMessage = sl();
  final MarkActivityChatRead _markChatRead = sl();
  final ActivityChatNoticeController _chatNotices = sl();
  final ActivityChatRealtimeController _realtime = sl();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late HomeActivity _activity = widget.activity;
  List<ActivityChatMessage> _messages = const [];
  StreamSubscription<ActivityChatMessage>? _messageSubscription;
  bool _isLoading = true;
  bool _isCatchingUp = false;
  bool _isSending = false;
  bool _sendBlocked = false;
  String? _errorMessage;
  String? _lastMarkedMessageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatNotices.markActivityOpen(_activity.id);
    _messageSubscription = _realtime.messages.listen(_handleRealtimeMessage);
    AnalyticsService.instance.track('chat_opened');
    unawaited(_initializeChat());
  }

  @override
  void didUpdateWidget(covariant ActivityChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activity != oldWidget.activity) {
      _applyActivityUpdate(widget.activity);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatNotices.markActivityClosed(_activity.id);
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && _isCurrentRoute) {
      unawaited(_catchUpMessages());
    }
  }

  Future<void> _initializeChat() async {
    await _loadMessages();
    await _realtime.subscribeToActivity(_activity.id);
    await _catchUpMessages();
  }

  Future<void> _loadMessages({
    bool showLoading = true,
    DateTime? afterCreatedAt,
    String? afterId,
  }) async {
    if (!showLoading && !_isCurrentRoute) {
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final result = await _getMessages(
      GetActivityChatMessagesParams(
        activityId: _activity.id,
        afterCreatedAt: afterCreatedAt,
        afterId: afterId,
      ),
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          if (showLoading) {
            _isLoading = false;
          }
          _errorMessage = failure.message;
        });
      },
      (messages) {
        final nextMessages = afterCreatedAt == null && afterId == null
            ? messages
            : _mergeMessages(_messages, messages);
        final messagesChanged = !listEquals(_messages, nextMessages);
        setState(() {
          if (messagesChanged) {
            _messages = nextMessages;
          }
          if (showLoading) {
            _isLoading = false;
          }
          _errorMessage = null;
        });
        if (showLoading || messagesChanged) {
          _scrollToBottom();
        }
        _markLatestMessageRead();
      },
    );
  }

  bool get _isCurrentRoute => ModalRoute.of(context)?.isCurrent ?? true;

  Future<void> _catchUpMessages() async {
    if (_isCatchingUp || _messages.isEmpty) {
      return;
    }

    _isCatchingUp = true;
    final lastMessage = _messages.last;
    try {
      await _loadMessages(
        showLoading: false,
        afterCreatedAt: lastMessage.createdAt,
        afterId: lastMessage.id,
      );
    } finally {
      _isCatchingUp = false;
    }
  }

  void _handleRealtimeMessage(ActivityChatMessage message) {
    if (!mounted || message.activityId != _activity.id) {
      return;
    }

    final currentUserId = _currentUserId;
    final isOwnLeaveNotice =
        message.isSystem &&
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        message.senderId == currentUserId &&
        message.body.toLowerCase().contains('heeft zich afgemeld');

    final nextMessages = _mergeMessages(_messages, [message]);
    if (listEquals(_messages, nextMessages)) {
      return;
    }

    setState(() {
      _messages = nextMessages;
      _errorMessage = null;
      if (isOwnLeaveNotice) {
        _sendBlocked = true;
      }
    });
    _scrollToBottom();
    _markLatestMessageRead();
  }

  Future<void> _sendCurrentMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending || !_canSendMessages) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final result = await _sendMessage(
      SendActivityChatMessageParams(
        activityId: _activity.id,
        body: body,
        clientMessageId: createActivityChatClientMessageId(),
      ),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isSending = false;
          if (_isChatPermissionFailure(failure.message)) {
            _sendBlocked = true;
          }
        });
        AnalyticsService.instance.track('message_send_failed');
        showTochSnackBar(
          context,
          failure.message,
          type: TochSnackBarType.error,
        );
      },
      (message) {
        _messageController.clear();
        final nextMessages = _mergeMessages(_messages, [message]);
        setState(() {
          _messages = nextMessages;
          _isSending = false;
        });
        AnalyticsService.instance.track('message_sent');
        _scrollToBottom();
        _markLatestMessageRead();
      },
    );
  }

  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.id : null;
  }

  bool get _canSendMessages => _activity.canSendChat && !_sendBlocked;

  void _applyActivityUpdate(HomeActivity activity) {
    if (activity.id != _activity.id) {
      return;
    }
    if (!mounted) {
      _activity = activity;
      return;
    }

    setState(() {
      _activity = activity;
      if (activity.canSendChat) {
        _sendBlocked = false;
      } else {
        _sendBlocked = true;
      }
    });
  }

  void _markLatestMessageRead() {
    if (!_isCurrentRoute || _messages.isEmpty) {
      return;
    }

    final latestMessageId = _messages.last.id;
    if (latestMessageId.isEmpty || latestMessageId == _lastMarkedMessageId) {
      return;
    }

    _lastMarkedMessageId = latestMessageId;
    unawaited(
      _markChatRead(
        MarkActivityChatReadParams(
          activityId: _activity.id,
          messageId: latestMessageId,
        ),
      ).then((result) {
        result.fold((failure) {
          AppLogger.debug(
            'Marking activity chat read failed: ${failure.message}',
          );
          if (_lastMarkedMessageId == latestMessageId) {
            _lastMarkedMessageId = null;
          }
        }, (_) {});
      }),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _goBack(context);
      },
      child: Scaffold(
        backgroundColor: colors.cream,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SafeArea(
              child: Column(
                children: [
                  _ChatHeader(
                    activity: _activity,
                    currentUserId: currentUserId,
                    onBackPressed: () => _goBack(context),
                    onMembersPressed: _openMembers,
                  ),
                  _ChatActivitySummary(
                    activity: _activity,
                    onPressed: _openActivityDetail,
                  ),
                  Expanded(
                    child: _ChatBody(
                      messages: _messages,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      scrollController: _scrollController,
                      onRetry: _loadMessages,
                      onProfilePressed: (profileId) {
                        context.push(AppRoutes.profilePath(profileId));
                      },
                    ),
                  ),
                  _MessageComposer(
                    activity: _activity,
                    controller: _messageController,
                    isSending: _isSending,
                    canSend: _canSendMessages,
                    onSendPressed: _sendCurrentMessage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    final fallbackRoute = widget.backFallbackRoute;
    if (fallbackRoute != null && fallbackRoute.isNotEmpty) {
      context.go(fallbackRoute);
      return;
    }
    if (context.canPop()) {
      context.pop(_activity);
      return;
    }
    context.go(AppRoutes.activityMessages);
  }

  Future<void> _openMembers() async {
    final updatedActivity = await context.push<HomeActivity>(
      AppRoutes.activityChatMembersPath(_activity.id),
      extra: _activity,
    );
    if (!mounted || updatedActivity == null) {
      return;
    }

    _applyActivityUpdate(updatedActivity);
    await _loadMessages(showLoading: false);
  }

  Future<void> _openActivityDetail() async {
    final updatedActivity = await context.push<HomeActivity>(
      AppRoutes.activityDetailPath(_activity.id),
      extra: _activity,
    );
    if (!mounted || updatedActivity == null) {
      return;
    }
    _applyActivityUpdate(updatedActivity);
  }
}

List<ActivityChatMessage> _mergeMessages(
  List<ActivityChatMessage> current,
  Iterable<ActivityChatMessage> incoming,
) {
  final messagesById = <String, ActivityChatMessage>{
    for (final message in current)
      if (message.id.isNotEmpty) message.id: message,
  };
  for (final message in incoming) {
    if (message.id.isNotEmpty) {
      messagesById[message.id] = message;
    }
  }

  return messagesById.values.toList()..sort((left, right) {
    final createdCompare = left.createdAt.compareTo(right.createdAt);
    if (createdCompare != 0) {
      return createdCompare;
    }
    return left.id.compareTo(right.id);
  });
}

class MissingActivityChatPage extends StatelessWidget {
  const MissingActivityChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum_rounded, color: colors.green, size: 44),
                const SizedBox(height: TochSpacing.md),
                Text(
                  'Chat niet gevonden',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TochSpacing.sm),
                Text(
                  'Open de chat opnieuw vanuit een activiteit.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: TochSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Terug naar overzicht'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.activity,
    required this.currentUserId,
    required this.onBackPressed,
    required this.onMembersPressed,
  });

  final HomeActivity activity;
  final String? currentUserId;
  final VoidCallback onBackPressed;
  final VoidCallback onMembersPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cream,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TochRoundButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: onBackPressed,
              size: 38,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMembersPressed,
                  borderRadius: BorderRadius.circular(TochRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TochPill(
                          label: activity.category.label,
                          icon: activity.category.icon,
                          compact: true,
                          backgroundColor: activity.category.backgroundColor,
                          foregroundColor: activity.category.color,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          activity.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _chatHeaderSubtitle(
                            activity,
                            currentUserId: currentUserId,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.ink3,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Deelnemers',
              onPressed: onMembersPressed,
              style: IconButton.styleFrom(
                backgroundColor: colors.card,
                foregroundColor: colors.ink2,
                fixedSize: const Size.square(38),
              ),
              icon: const Icon(Icons.group_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatActivitySummary extends StatelessWidget {
  const _ChatActivitySummary({required this.activity, required this.onPressed});

  final HomeActivity activity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(TochRadius.md),
          boxShadow: TochShadows.card(colors),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: activity.category.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox.square(
                  dimension: 36,
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: activity.category.color,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (activity.dateLabel.isNotEmpty) activity.dateLabel,
                        if (activity.timeLabel.isNotEmpty) activity.timeLabel,
                      ].join(' - '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.meetingPoint.isEmpty
                          ? activity.locationName
                          : activity.meetingPoint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.ink3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  backgroundColor: colors.green100,
                  foregroundColor: colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Bekijk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _chatHeaderSubtitle(HomeActivity activity, {String? currentUserId}) {
  final membersLabel =
      '${_chatMemberCountFor(activity, currentUserId: currentUserId)} deelnemers';
  final dateTime = [
    activity.dateLabel,
    activity.timeLabel,
  ].where((part) => part.isNotEmpty).join(' · ');
  if (dateTime.isEmpty) {
    return membersLabel;
  }
  return '$membersLabel · $dateTime';
}

int _chatMemberCountFor(HomeActivity activity, {String? currentUserId}) {
  final memberIds = <String>{};
  if (activity.hostId.isNotEmpty) {
    memberIds.add(activity.hostId);
  }
  for (final participant in activity.participants) {
    if (participant.id.isNotEmpty) {
      memberIds.add(participant.id);
    }
  }

  final currentId = currentUserId ?? '';
  final shouldIncludeCurrentUser =
      activity.isJoined &&
      (currentId.isEmpty || !memberIds.contains(currentId));
  return memberIds.length + (shouldIncludeCurrentUser ? 1 : 0);
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({
    required this.messages,
    required this.isLoading,
    required this.errorMessage,
    required this.scrollController,
    required this.onRetry,
    required this.onProfilePressed,
  });

  final List<ActivityChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final ScrollController scrollController;
  final Future<void> Function() onRetry;
  final ValueChanged<String> onProfilePressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.toch.green),
      );
    }

    if (errorMessage != null) {
      return _ChatError(message: errorMessage!, onRetry: onRetry);
    }

    if (messages.isEmpty) {
      return const _ChatEmpty();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return _MessageBubble(
          message: messages[index],
          onProfilePressed: onProfilePressed,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onProfilePressed});

  final ActivityChatMessage message;
  final ValueChanged<String> onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    if (message.isSystem) {
      return _SystemMessage(message: message);
    }
    final bubbleColor = message.isMine ? colors.green : colors.card;
    final textColor = message.isMine ? Colors.white : colors.ink;
    final metaColor = message.isMine
        ? Colors.white.withValues(alpha: .72)
        : colors.green700.withValues(alpha: .62);

    return Padding(
      padding: const EdgeInsets.only(bottom: TochSpacing.sm),
      child: Row(
        mainAxisAlignment: message.isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMine) ...[
            _InitialsAvatar(
              message: message,
              onProfilePressed: onProfilePressed,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(message.isMine ? 18 : 5),
                    bottomRight: Radius.circular(message.isMine ? 5 : 18),
                  ),
                  border: message.isMine
                      ? null
                      : Border.all(color: colors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!message.isMine) ...[
                        Text(
                          message.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.green,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        message.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          height: 1.32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: metaColor),
                      ),
                    ],
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

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.message});

  final ActivityChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.only(bottom: TochSpacing.sm),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.green100.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(TochRadius.pill),
            border: Border.all(color: colors.green200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Text(
              message.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.green700.withValues(alpha: .78),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.message,
    required this.onProfilePressed,
  });

  final ActivityChatMessage message;
  final ValueChanged<String> onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final canOpenProfile = message.senderId.isNotEmpty;

    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: colors.green100,
      foregroundColor: colors.green,
      backgroundImage: message.senderAvatarUrl == null
          ? null
          : NetworkImage(message.senderAvatarUrl!),
      child: message.senderAvatarUrl == null
          ? Text(
              message.senderInitials,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            )
          : null,
    );

    return Tooltip(
      message: canOpenProfile ? 'Bekijk profiel' : message.senderName,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: canOpenProfile
              ? () => onProfilePressed(message.senderId)
              : null,
          child: avatar,
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.activity,
    required this.controller,
    required this.isSending,
    required this.canSend,
    required this.onSendPressed,
  });

  final HomeActivity activity;
  final TextEditingController controller;
  final bool isSending;
  final bool canSend;
  final VoidCallback onSendPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cream,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canSend) ...[
              _ReadOnlyChatNotice(activity: activity),
              const SizedBox(height: TochSpacing.sm),
            ],
            Row(
              children: [
                IconButton(
                  tooltip: 'Toevoegen',
                  onPressed: canSend ? () {} : null,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.card,
                    foregroundColor: colors.ink3,
                    fixedSize: const Size.square(40),
                    disabledBackgroundColor: colors.surface2,
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: canSend,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: canSend ? 'Bericht' : 'Chat alleen lezen',
                      filled: true,
                      fillColor: colors.card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TochRadius.pill),
                        borderSide: BorderSide(color: colors.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TochRadius.pill),
                        borderSide: BorderSide(color: colors.line),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TochRadius.pill),
                        borderSide: BorderSide(color: colors.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TochRadius.pill),
                        borderSide: BorderSide(color: colors.green, width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: !canSend || isSending ? null : onSendPressed,
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(42),
                    backgroundColor: colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.green100,
                    disabledForegroundColor: colors.green.withValues(
                      alpha: .45,
                    ),
                  ),
                  icon: isSending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyChatNotice extends StatelessWidget {
  const _ReadOnlyChatNotice({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.orangeSoft,
        borderRadius: BorderRadius.circular(TochRadius.md),
        border: Border.all(color: colors.orange.withValues(alpha: .28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: colors.orange, size: 18),
            const SizedBox(width: TochSpacing.xs),
            Expanded(
              child: Text(
                readOnlyChatNoticeText(activity),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.green700,
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

class _ChatError extends StatelessWidget {
  const _ChatError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TochSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PipMascot(expression: PipExpression.surprise, size: 108),
          const SizedBox(height: TochSpacing.md),
          Text(
            'Chat hapert even',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.toch.green,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: TochSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: TochSpacing.lg),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Opnieuw proberen'),
          ),
        ],
      ),
    );
  }
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TochSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PipMascot(expression: PipExpression.happy, size: 112),
          const SizedBox(height: TochSpacing.md),
          Text(
            'Nog geen berichten',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TochSpacing.sm),
          Text(
            'Start het gesprek met een korte afstemming.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

String _formatMessageTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool _isChatPermissionFailure(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('meld je eerst aan') ||
      normalized.contains('chat') && normalized.contains('openen');
}
