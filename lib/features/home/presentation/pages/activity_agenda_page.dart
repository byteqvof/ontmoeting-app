import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/pip_mascot.dart';
import '../../../../app/widgets/toch_design_system.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/activity_agenda.dart';
import '../../domain/entities/activity_chat_notice.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_participant.dart';
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
  _AgendaTab _selectedTab = _AgendaTab.joined;
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

  Future<void> _openActivity(HomeActivity activity) async {
    final updated = await context.push<HomeActivity>(
      AppRoutes.activityDetailPath(activity.id),
      extra: activity,
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _agenda = _agenda?.withActivityUpdated(updated);
    });
  }

  Future<void> _editActivity(HomeActivity activity) async {
    final updated = await context.push<HomeActivity>(
      AppRoutes.editActivityPath(activity.id),
      extra: activity,
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _agenda = _agenda?.withActivityUpdated(updated);
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
              children: [
                _PageHeader(
                  title: 'Agenda',
                  bottom: _AgendaTabBar(
                    selected: _selectedTab,
                    agenda: _agenda,
                    onChanged: (tab) => setState(() => _selectedTab = tab),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: colors.green,
                    backgroundColor: colors.card,
                    onRefresh: _loadAgenda,
                    child: _AgendaBody(
                      agenda: _agenda,
                      selectedTab: _selectedTab,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                      onRetry: _loadAgenda,
                      onActivityPressed: _openActivity,
                      onActivityEditPressed: _editActivity,
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

  Future<void> _openChat(HomeActivity activity) async {
    _chatNotices.markActivityRead(activity.id);
    setState(() {
      _agenda = _agenda?.withChatMarkedRead(activity.id);
    });
    await context.push(
      AppRoutes.activityChatPath(activity.id),
      extra: activity,
    );
    if (!mounted) {
      return;
    }
    await _loadAgenda();
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
                const _PageHeader(title: 'Berichten'),
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

enum _AgendaTab {
  joined('Gaat mee'),
  hosted('Organiseert'),
  completed('Geweest');

  const _AgendaTab(this.label);

  final String label;
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, this.bottom});

  final String title;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          if (bottom != null) ...[const SizedBox(height: 16), bottom!],
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _AgendaTabBar extends StatelessWidget {
  const _AgendaTabBar({
    required this.selected,
    required this.onChanged,
    required this.agenda,
  });

  final _AgendaTab selected;
  final ValueChanged<_AgendaTab> onChanged;
  final ActivityAgenda? agenda;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in _AgendaTab.values) ...[
            TochPill(
              label: '${tab.label} ${_countFor(tab, agenda)}',
              active: selected == tab,
              onTap: () => onChanged(tab),
            ),
            if (tab != _AgendaTab.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

int _countFor(_AgendaTab tab, ActivityAgenda? agenda) {
  if (agenda == null) {
    return 0;
  }
  return switch (tab) {
    _AgendaTab.joined => agenda.activeJoinedActivities.length,
    _AgendaTab.hosted => agenda.activeHostedActivities.length,
    _AgendaTab.completed => agenda.uniqueCompletedActivities.length,
  };
}

class _AgendaBody extends StatelessWidget {
  const _AgendaBody({
    required this.agenda,
    required this.selectedTab,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onActivityPressed,
    required this.onActivityEditPressed,
  });

  final ActivityAgenda? agenda;
  final _AgendaTab selectedTab;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final ValueChanged<HomeActivity> onActivityPressed;
  final ValueChanged<HomeActivity> onActivityEditPressed;

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
        expression: PipExpression.thinking,
        title: 'Nog niets in je agenda',
        message: 'Organiseer iets of meld je aan bij een activiteit.',
      );
    }

    final activities = switch (selectedTab) {
      _AgendaTab.joined => currentAgenda.activeJoinedActivities,
      _AgendaTab.hosted => currentAgenda.activeHostedActivities,
      _AgendaTab.completed => currentAgenda.uniqueCompletedActivities,
    };

    if (activities.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 86, 20, 140),
        children: [
          _SoftEmptyCard(
            icon: Icons.calendar_today_rounded,
            title: selectedTab == _AgendaTab.completed
                ? 'Nog niets geweest'
                : 'Geen activiteiten hier',
            message: selectedTab == _AgendaTab.hosted
                ? 'Activiteiten die jij organiseert verschijnen hier.'
                : 'Zodra er iets in deze lijst hoort, zie je het hier.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 130),
      children: [
        _DateSectionLabel(
          label: selectedTab == _AgendaTab.completed
              ? 'Afgelopen'
              : _agendaSectionLabel(activities.first),
        ),
        const SizedBox(height: 8),
        for (final activity in activities)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AgendaActivityCard(
              activity: activity,
              selectedTab: selectedTab,
              onPressed: () => onActivityPressed(activity),
              onEditPressed:
                  selectedTab == _AgendaTab.hosted &&
                      activity.isOwnedByCurrentUser &&
                      !activity.isCompleted
                  ? () => onActivityEditPressed(activity)
                  : null,
              onChatPressed: activity.canSendChat
                  ? () => context.push(
                      AppRoutes.activityChatPath(activity.id),
                      extra: activity,
                    )
                  : null,
            ),
          ),
        const SizedBox(height: 8),
        _ExploreMoreCard(onPressed: () => context.go(AppRoutes.home)),
      ],
    );
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
        expression: PipExpression.happy,
        title: 'Nog geen chats',
        message: 'Chats verschijnen zodra je organiseert of ergens meegaat.',
      );
    }

    final people = _networkPeopleFrom(activities);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 130),
      children: [
        if (people.isNotEmpty) ...[
          const _SectionLabel('Jouw netwerk'),
          SizedBox(
            height: 96,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return _NetworkPersonCard(person: people[index]);
              },
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemCount: people.length,
            ),
          ),
          const SizedBox(height: 6),
        ],
        const _SectionLabel('Activiteiten'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final activity in activities)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ChatThreadCard(
                    activity: activity,
                    onPressed: () => onActivityPressed(activity),
                  ),
                ),
              const _ChatExpiryNote(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgendaActivityCard extends StatelessWidget {
  const _AgendaActivityCard({
    required this.activity,
    required this.onPressed,
    required this.selectedTab,
    this.onEditPressed,
    this.onChatPressed,
  });

  final HomeActivity activity;
  final VoidCallback onPressed;
  final _AgendaTab selectedTab;
  final VoidCallback? onEditPressed;
  final VoidCallback? onChatPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(TochRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TochRadius.lg),
            boxShadow: TochShadows.card(colors),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isToday(activity) ? colors.green100 : colors.card,
                    border: Border(right: BorderSide(color: colors.line)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _agendaDayLabel(activity),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.ink4,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _timeHour(activity.timeLabel),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        _timeMinute(activity.timeLabel),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.ink3,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusPill(activity: activity),
                        const SizedBox(height: 7),
                        Text(
                          activity.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              color: colors.ink4,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                activity.meetingPoint.isEmpty
                                    ? activity.locationName
                                    : activity.meetingPoint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: colors.ink3,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniAvatarStack(activity: activity),
                            ),
                            if (onChatPressed != null)
                              TextButton.icon(
                                onPressed: onChatPressed,
                                style: TextButton.styleFrom(
                                  backgroundColor: colors.green100,
                                  foregroundColor: colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: const StadiumBorder(),
                                ),
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                ),
                                label: const Text('Chat'),
                              ),
                          ],
                        ),
                        if (selectedTab == _AgendaTab.hosted &&
                            activity.isOwnedByCurrentUser) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onPressed,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.green,
                                    side: BorderSide(color: colors.green200),
                                    minimumSize: const Size(0, 42),
                                    shape: const StadiumBorder(),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.manage_accounts_rounded,
                                    size: 17,
                                  ),
                                  label: const Text('Beheer'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: onEditPressed,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.green,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: colors.green100,
                                    disabledForegroundColor: colors.green700
                                        .withValues(alpha: .45),
                                    minimumSize: const Size(0, 42),
                                    shape: const StadiumBorder(),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    size: 17,
                                  ),
                                  label: const Text('Bewerk'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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

class _ChatThreadCard extends StatelessWidget {
  const _ChatThreadCard({required this.activity, required this.onPressed});

  final HomeActivity activity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final hasUnread = activity.chatUnreadCount > 0;
    final preview = _chatPreview(activity);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(TochRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: activity.category.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox.square(
                  dimension: 46,
                  child: Icon(
                    activity.category.icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusPill(activity: activity, compact: true),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: hasUnread
                                      ? FontWeight.w900
                                      : FontWeight.w800,
                                  height: 1.15,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activity.chatLastMessageAt == null
                              ? ''
                              : _formatInboxTime(activity.chatLastMessageAt!),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.ink4,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _threadHostLine(activity),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.ink4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: hasUnread ? colors.ink : colors.ink3,
                                  fontWeight: hasUnread
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(count: activity.chatUnreadCount),
                        ],
                      ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.activity, this.compact = false});

  final HomeActivity activity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final completed = activity.isCompleted;
    final today = _isToday(activity);
    final background = completed
        ? colors.surface2
        : today
        ? colors.orangeSoft
        : colors.green100;
    final foreground = completed
        ? colors.ink4
        : today
        ? colors.orange
        : colors.green;
    final label = completed
        ? 'Afgelopen'
        : today
        ? 'Vandaag'
        : 'Aankomend';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TochRadius.pill),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (today && !completed) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: foreground,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 6),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontSize: compact ? 10.5 : 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAvatarStack extends StatelessWidget {
  const _MiniAvatarStack({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final participants = _displayParticipants(activity);
    if (participants.isEmpty) {
      return Text(
        activity.hostName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.toch.ink3,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return SizedBox(
      height: 26,
      child: Stack(
        children: [
          for (var index = 0; index < participants.take(5).length; index++)
            Positioned(
              left: index * 17,
              child: _SmallAvatar(participant: participants[index]),
            ),
        ],
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.participant});

  final HomeParticipant participant;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: participant.isHost ? colors.orange : colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: colors.card, width: 2),
      ),
      child: SizedBox.square(
        dimension: 26,
        child: Center(
          child: Text(
            participant.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkPersonCard extends StatelessWidget {
  const _NetworkPersonCard({required this.person});

  final HomeParticipant person;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return SizedBox(
      width: 74,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: person.isHost ? colors.orange : colors.green,
              shape: BoxShape.circle,
              border: Border.all(
                color: person.isHost ? colors.orangeSoft : colors.green100,
                width: 3,
              ),
            ),
            child: SizedBox.square(
              dimension: 58,
              child: Center(
                child: Text(
                  person.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            person.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.ink2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(TochRadius.pill),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatExpiryNote extends StatelessWidget {
  const _ChatExpiryNote();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(TochRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: colors.ink4, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Groepschats sluiten automatisch 24 uur na afloop van de activiteit.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.ink4,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSectionLabel extends StatelessWidget {
  const _DateSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.toch.ink4,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: _DateSectionLabel(label: label),
    );
  }
}

class _ExploreMoreCard extends StatelessWidget {
  const _ExploreMoreCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(TochRadius.lg),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TochRadius.lg),
            border: Border.all(color: colors.line, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: colors.ink4, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Meer activiteiten ontdekken',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.ink4,
                      fontWeight: FontWeight.w800,
                    ),
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

class _SoftEmptyCard extends StatelessWidget {
  const _SoftEmptyCard({
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        boxShadow: TochShadows.card(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, color: colors.green, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.ink3),
            ),
          ],
        ),
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
        const SizedBox(height: 150),
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
        const SizedBox(height: 118),
        const PipMascot(expression: PipExpression.surprise, size: 108),
        const SizedBox(height: TochSpacing.md),
        Text(
          'Dit lukte even niet',
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.expression,
    required this.title,
    required this.message,
  });

  final PipExpression expression;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TochSpacing.xl),
      children: [
        const SizedBox(height: 118),
        PipMascot(expression: expression, size: 112),
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

List<HomeParticipant> _displayParticipants(HomeActivity activity) {
  final host = HomeParticipant(
    id: activity.hostId,
    displayName: activity.hostName,
    initials: _initialsFor(activity.hostName),
    isHost: true,
    avatarUrl: activity.hostAvatarUrl,
  );
  return [host, ...activity.participants];
}

List<HomeParticipant> _networkPeopleFrom(List<HomeActivity> activities) {
  final byId = <String, HomeParticipant>{};
  for (final activity in activities) {
    if (activity.hostId.isNotEmpty) {
      byId.putIfAbsent(
        activity.hostId,
        () => HomeParticipant(
          id: activity.hostId,
          displayName: activity.hostName,
          initials: _initialsFor(activity.hostName),
          isHost: true,
          avatarUrl: activity.hostAvatarUrl,
        ),
      );
    }
    for (final participant in activity.participants) {
      if (participant.id.isNotEmpty) {
        byId.putIfAbsent(participant.id, () => participant);
      }
    }
  }
  return byId.values.take(10).toList();
}

String _initialsFor(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return 'T';
  }
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

String _agendaSectionLabel(HomeActivity activity) {
  if (_isToday(activity)) {
    return 'Vandaag - ${activity.dateLabel}';
  }
  if (activity.dateLabel.isNotEmpty) {
    return activity.dateLabel;
  }
  return 'Aankomend';
}

String _agendaDayLabel(HomeActivity activity) {
  final label = activity.dateLabel.trim();
  if (label.length >= 2) {
    return label.substring(0, 2).toUpperCase();
  }
  return 'NU';
}

bool _isToday(HomeActivity activity) {
  final startsAt = activity.startsAt;
  if (startsAt == null) {
    return activity.dateLabel.toLowerCase().contains('vandaag');
  }
  final local = startsAt.toLocal();
  final now = DateTime.now();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

String _timeHour(String value) {
  final parts = value.split(':');
  if (parts.isEmpty || parts.first.trim().isEmpty) {
    return '--';
  }
  return parts.first.trim().padLeft(2, '0');
}

String _timeMinute(String value) {
  final parts = value.split(':');
  if (parts.length < 2) {
    return ':--';
  }
  return ':${parts[1].trim().padLeft(2, '0')}';
}

String _threadHostLine(HomeActivity activity) {
  final count = _displayParticipants(activity).length;
  return '${activity.hostName} - $count deelnemers';
}

String _chatPreview(HomeActivity activity) {
  final lastMessage = activity.chatLastMessage?.trim();
  final lastSender = activity.chatLastSenderName?.trim();
  final isSystemPreview = activity.chatLastMessageType == 'system';
  if (lastMessage != null && lastMessage.isNotEmpty) {
    return [
      if (!isSystemPreview && lastSender != null && lastSender.isNotEmpty)
        '$lastSender:',
      lastMessage,
    ].join(' ');
  }
  return [
    activity.locationName,
    if (activity.isOwnedByCurrentUser)
      'jij organiseert'
    else if (activity.isJoined)
      'jij gaat mee',
  ].where((part) => part.isNotEmpty).join(' - ');
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
