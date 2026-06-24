import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/activity_agenda.dart';
import '../../domain/entities/activity_chat_notice.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/usecases/get_activity_agenda.dart';
import '../controllers/activity_chat_notice_controller.dart';
import '../widgets/home_bottom_nav.dart';

class ActivityAgendaPage extends StatefulWidget {
  const ActivityAgendaPage({super.key});

  @override
  State<ActivityAgendaPage> createState() => _ActivityAgendaPageState();
}

class _ActivityAgendaPageState extends State<ActivityAgendaPage> {
  final GetActivityAgenda _getActivityAgenda = sl();

  ActivityAgenda? _agenda;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  Future<void> _loadAgenda() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _getActivityAgenda(const NoParams());
    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (agenda) {
        setState(() {
          _agenda = agenda;
          _isLoading = false;
        });
      },
    );
  }

  void _openActivity(HomeActivity activity) {
    context.push(AppRoutes.activityDetailPath(activity.id), extra: activity);
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
              children: [
                _PageHeader(
                  title: 'Agenda',
                  icon: Icons.calendar_month_rounded,
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: colors.green,
                    backgroundColor: colors.card,
                    onRefresh: _loadAgenda,
                    child: _AgendaBody(
                      agenda: _agenda,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      onRetry: _loadAgenda,
                      onActivityPressed: _openActivity,
                    ),
                  ),
                ),
                const HomeBottomNav(selected: HomeNavDestination.agenda),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AgendaBody extends StatelessWidget {
  const _AgendaBody({
    required this.agenda,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onActivityPressed,
  });

  final ActivityAgenda? agenda;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final ValueChanged<HomeActivity> onActivityPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingState(message: 'Agenda laden');
    }

    if (errorMessage != null) {
      return _ErrorState(message: errorMessage!, onRetry: onRetry);
    }

    final currentAgenda = agenda;
    if (currentAgenda == null || currentAgenda.totalCount == 0) {
      return const _EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'Nog niets in je agenda',
        message: 'Organiseer iets of meld je aan bij een activiteit.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
      children: [
        _ActivitySection(
          title: 'Ik organiseer',
          activities: currentAgenda.activeHostedActivities,
          emptyMessage: 'Je organiseert nog geen activiteiten.',
          onActivityPressed: onActivityPressed,
        ),
        const SizedBox(height: TochSpacing.md),
        _ActivitySection(
          title: 'Ik ga mee',
          activities: currentAgenda.activeJoinedActivities,
          emptyMessage: 'Je bent nog nergens aangemeld.',
          onActivityPressed: onActivityPressed,
        ),
        const SizedBox(height: TochSpacing.md),
        _ActivitySection(
          title: 'Afgerond',
          activities: currentAgenda.uniqueCompletedActivities,
          emptyMessage: 'Afgeronde activiteiten verschijnen hier.',
          onActivityPressed: onActivityPressed,
        ),
      ],
    );
  }
}

class ActivityMessagesPage extends StatefulWidget {
  const ActivityMessagesPage({super.key});

  @override
  State<ActivityMessagesPage> createState() => _ActivityMessagesPageState();
}

class _ActivityMessagesPageState extends State<ActivityMessagesPage>
    with WidgetsBindingObserver {
  final GetActivityAgenda _getActivityAgenda = sl();
  final ActivityChatNoticeController _chatNotices = sl();

  ActivityAgenda? _agenda;
  StreamSubscription<ActivityChatNotice>? _noticeSubscription;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatNotices.clearUnread();
    _noticeSubscription = _chatNotices.notices.listen((notice) {
      _chatNotices.clearUnread();
      _applyChatNotice(notice);
    });
    _loadAgenda();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _noticeSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_loadAgenda(showLoading: false));
    }
  }

  Future<void> _loadAgenda({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final result = await _getActivityAgenda(const NoParams());
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
      (agenda) {
        setState(() {
          _agenda = agenda;
          _isLoading = false;
        });
      },
    );
  }

<<<<<<< HEAD
  void _applyChatNotice(ActivityChatNotice notice) {
    final currentAgenda = _agenda;
    if (currentAgenda == null) {
      unawaited(_loadAgenda(showLoading: false));
      return;
    }

    final update = _agendaWithChatNotice(currentAgenda, notice);
    if (!update.didUpdate) {
      unawaited(_loadAgenda(showLoading: false));
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _agenda = update.agenda;
    });
  }

  void _openChat(HomeActivity activity) {
    context.push(AppRoutes.activityChatPath(activity.id), extra: activity);
=======
  Future<void> _openChat(HomeActivity activity) async {
    _chatNotices.markActivityRead(activity.id);
    setState(() {
      _agenda = _agenda?.withChatMarkedRead(activity.id);
    });
    await context.push(AppRoutes.activityChatPath(activity.id), extra: activity);
    if (!mounted) {
      return;
    }
    await _loadAgenda();
>>>>>>> codex/beta-round-2-polish
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
              children: [
                _PageHeader(
                  title: 'Berichten',
                  icon: Icons.chat_bubble_rounded,
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: colors.green,
                    backgroundColor: colors.card,
                    onRefresh: _loadAgenda,
                    child: _MessagesBody(
                      agenda: _agenda,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      onRetry: _loadAgenda,
                      onActivityPressed: _openChat,
                    ),
                  ),
                ),
                const HomeBottomNav(selected: HomeNavDestination.messages),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

({ActivityAgenda agenda, bool didUpdate}) _agendaWithChatNotice(
  ActivityAgenda agenda,
  ActivityChatNotice notice,
) {
  var didUpdate = false;

  List<HomeActivity> updateActivities(List<HomeActivity> activities) {
    return [
      for (final activity in activities)
        if (activity.id == notice.activityId)
          _activityWithChatNotice(activity, notice).also((_) {
            didUpdate = true;
          })
        else
          activity,
    ];
  }

  return (
    agenda: ActivityAgenda(
      hostedActivities: updateActivities(agenda.hostedActivities),
      joinedActivities: updateActivities(agenda.joinedActivities),
      completedActivities: updateActivities(agenda.completedActivities),
    ),
    didUpdate: didUpdate,
  );
}

HomeActivity _activityWithChatNotice(
  HomeActivity activity,
  ActivityChatNotice notice,
) {
  return activity.copyWith(
    chatLastMessage: notice.body,
    chatLastMessageAt: notice.createdAt,
    chatLastSenderName: notice.senderName,
    chatLastMessageType: 'user',
    chatUnreadCount: activity.chatUnreadCount + 1,
  );
}

extension _Also<T> on T {
  T also(void Function(T value) action) {
    action(this);
    return this;
  }
}

class _MessagesBody extends StatelessWidget {
  const _MessagesBody({
    required this.agenda,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onActivityPressed,
  });

  final ActivityAgenda? agenda;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final ValueChanged<HomeActivity> onActivityPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingState(message: 'Berichten laden');
    }

    if (errorMessage != null) {
      return _ErrorState(message: errorMessage!, onRetry: onRetry);
    }

    final activities = agenda?.chatActivities ?? const <HomeActivity>[];
    if (activities.isEmpty) {
      return const _EmptyState(
        icon: Icons.forum_rounded,
        title: 'Nog geen chats',
        message: 'Chats verschijnen zodra je organiseert of ergens meegaat.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
      children: [
        for (final activity in activities)
          Padding(
            padding: const EdgeInsets.only(bottom: TochSpacing.sm),
            child: _ActivityTile(
              activity: activity,
              trailingIcon: Icons.chat_bubble_rounded,
              showChatSummary: true,
              onPressed: () => onActivityPressed(activity),
            ),
          ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.title,
    required this.activities,
    required this.emptyMessage,
    required this.onActivityPressed,
  });

  final String title;
  final List<HomeActivity> activities;
  final String emptyMessage;
  final ValueChanged<HomeActivity> onActivityPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '${activities.length}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.green700.withValues(alpha: .72),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: TochSpacing.sm),
        if (activities.isEmpty)
          _InlineEmptyMessage(message: emptyMessage)
        else
          for (final activity in activities)
            Padding(
              padding: const EdgeInsets.only(bottom: TochSpacing.sm),
              child: _ActivityTile(
                activity: activity,
                trailingIcon: Icons.chevron_right_rounded,
                onPressed: () => onActivityPressed(activity),
              ),
            ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.trailingIcon,
    required this.onPressed,
    this.showChatSummary = false,
  });

  final HomeActivity activity;
  final IconData trailingIcon;
  final VoidCallback onPressed;
  final bool showChatSummary;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final borderRadius = BorderRadius.circular(TochRadius.md);
    final hasUnread = showChatSummary && activity.chatUnreadCount > 0;
    final lastMessage = activity.chatLastMessage?.trim();
    final lastSender = activity.chatLastSenderName?.trim();
    final isSystemPreview = activity.chatLastMessageType == 'system';
    final preview =
        showChatSummary && lastMessage != null && lastMessage.isNotEmpty
        ? [
            if (!isSystemPreview && lastSender != null && lastSender.isNotEmpty)
              '$lastSender:',
            lastMessage,
          ].join(' ')
        : [
            activity.locationName,
            if (activity.isOwnedByCurrentUser)
              'jij organiseert'
            else if (activity.isJoined)
              'jij gaat mee',
          ].where((part) => part.isNotEmpty).join(' Â· ');

    return Material(
      color: colors.card,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: colors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: activity.category.backgroundColor,
                    borderRadius: BorderRadius.circular(TochRadius.md),
                  ),
                  child: SizedBox.square(
                    dimension: 42,
                    child: Icon(
                      activity.category.icon,
                      color: activity.category.color,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: TochSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.ink,
                          height: 1.12,
                          fontWeight: hasUnread
                              ? FontWeight.w900
                              : FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        [
                          if (activity.dateLabel.isNotEmpty) activity.dateLabel,
                          if (activity.timeLabel.isNotEmpty) activity.timeLabel,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.green700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (showChatSummary)
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: hasUnread
                                    ? colors.ink
                                    : colors.green700.withValues(alpha: .72),
                                fontWeight: hasUnread
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                        )
                      else
                        Text(
                          [
                            activity.locationName,
                            if (activity.isOwnedByCurrentUser)
                              'jij organiseert'
                            else if (activity.isJoined)
                              'jij gaat mee',
                          ].where((part) => part.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.green700.withValues(alpha: .72),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: TochSpacing.xs),
                if (hasUnread)
                  _UnreadBadge(count: activity.chatUnreadCount)
                else if (showChatSummary && activity.chatLastMessageAt != null)
                  Text(
                    _formatInboxTime(activity.chatLastMessageAt!),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.green700.withValues(alpha: .62),
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Icon(
                    trailingIcon,
                    color: colors.green700.withValues(alpha: .45),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final label = count > 99 ? '99+' : count.toString();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.orange,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _formatInboxTime(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (isToday) {
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}';
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 18, 14),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.green100,
              borderRadius: BorderRadius.circular(TochRadius.md),
            ),
            child: SizedBox.square(
              dimension: 38,
              child: Icon(icon, color: colors.green, size: 21),
            ),
          ),
          const SizedBox(width: TochSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TochSpacing.xl),
      children: [
        const SizedBox(height: 160),
        Center(child: CircularProgressIndicator(color: context.toch.green)),
        const SizedBox(height: TochSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TochSpacing.xl),
      children: [
        const SizedBox(height: 130),
        Icon(Icons.error_outline_rounded, color: context.toch.orange, size: 42),
        const SizedBox(height: TochSpacing.md),
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TochSpacing.xl),
      children: [
        const SizedBox(height: 130),
        Icon(icon, color: colors.green, size: 42),
        const SizedBox(height: TochSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: TochSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _InlineEmptyMessage extends StatelessWidget {
  const _InlineEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.md),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Row(
          children: [
            Icon(Icons.event_busy_rounded, color: colors.green700),
            const SizedBox(width: TochSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
