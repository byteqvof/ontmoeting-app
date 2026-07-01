import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_participant.dart';
import '../widgets/home_category_style.dart';

class ActivityChatMembersPage extends StatefulWidget {
  const ActivityChatMembersPage({required this.activity, super.key});

  final HomeActivity activity;

  @override
  State<ActivityChatMembersPage> createState() =>
      _ActivityChatMembersPageState();
}

class _ActivityChatMembersPageState extends State<ActivityChatMembersPage> {
  late HomeActivity _activity = widget.activity;

  @override
  void didUpdateWidget(covariant ActivityChatMembersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activity != oldWidget.activity) {
      _activity = widget.activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;
    final members = _chatMembersFor(_activity, currentUserId: currentUserId);

    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
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
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _MembersHeader(
                      activity: _activity,
                      memberCount: members.length,
                      onBackPressed: () => _goBack(context),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList.list(
                      children: [
                        _ActivitySummary(activity: _activity),
                        const SizedBox(height: TochSpacing.md),
                        _ViewActivityButton(
                          activity: _activity,
                          onActivityUpdated: _applyActivityUpdate,
                        ),
                        const SizedBox(height: TochSpacing.md),
                        _MembersList(
                          members: members,
                          onMemberPressed: (member) {
                            if (member.isCurrentUser) {
                              context.push(AppRoutes.profile);
                              return;
                            }
                            context.push(
                              AppRoutes.profilePath(member.profileId),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyActivityUpdate(HomeActivity activity) {
    if (activity.id != _activity.id || !mounted) {
      return;
    }
    setState(() {
      _activity = activity;
    });
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop(_activity);
      return;
    }
    context.go(AppRoutes.activityMessages);
  }
}

class _MembersHeader extends StatelessWidget {
  const _MembersHeader({
    required this.activity,
    required this.memberCount,
    required this.onBackPressed,
  });

  final HomeActivity activity;
  final int memberCount;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 16, 22),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBackPressed,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.cream,
                    foregroundColor: colors.ink,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                const SizedBox.square(dimension: 48),
              ],
            ),
            const SizedBox(height: TochSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: activity.category.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 86,
                child: Icon(
                  activity.category.icon,
                  color: activity.category.color,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: TochSpacing.md),
            Text(
              activity.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$memberCount deelnemers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.green700.withValues(alpha: .72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.activity});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final dateTime = [
      activity.dateLabel,
      activity.timeLabel,
    ].where((part) => part.isNotEmpty).join(' · ');
    final location = activity.isPrivateLocation
        ? 'Locatie gedeeld na deelname'
        : activity.locationName;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Column(
          children: [
            if (dateTime.isNotEmpty)
              _SummaryRow(icon: Icons.schedule_rounded, label: dateTime),
            if (dateTime.isNotEmpty && location.isNotEmpty)
              const SizedBox(height: TochSpacing.sm),
            if (location.isNotEmpty)
              _SummaryRow(icon: Icons.place_rounded, label: location),
          ],
        ),
      ),
    );
  }
}

class _ViewActivityButton extends StatelessWidget {
  const _ViewActivityButton({
    required this.activity,
    required this.onActivityUpdated,
  });

  final HomeActivity activity;
  final ValueChanged<HomeActivity> onActivityUpdated;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          final updatedActivity = await context.push<HomeActivity>(
            AppRoutes.activityDetailPath(activity.id),
            extra: activity,
          );
          if (updatedActivity != null) {
            onActivityUpdated(updatedActivity);
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TochRadius.md),
          ),
        ),
        icon: const Icon(Icons.event_rounded),
        label: const Text('Bekijk activiteit'),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Row(
      children: [
        Icon(icon, color: colors.green, size: 20),
        const SizedBox(width: TochSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({required this.members, required this.onMemberPressed});

  final List<_ChatMember> members;
  final ValueChanged<_ChatMember> onMemberPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 7),
            child: Text(
              'Chatleden',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (var index = 0; index < members.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.only(left: 76),
                child: Divider(height: 1, color: colors.line),
              ),
            _MemberTile(
              member: members[index],
              onPressed: () => onMemberPressed(members[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.onPressed});

  final _ChatMember member;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: member.profileId.isEmpty && !member.isCurrentUser
            ? null
            : onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.green100,
                foregroundColor: colors.green,
                foregroundImage: member.avatarUrl == null
                    ? null
                    : NetworkImage(member.avatarUrl!),
                child: member.avatarUrl == null
                    ? Text(
                        member.initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: TochSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        if (member.isHost) ...[
                          const SizedBox(width: TochSpacing.xs),
                          _HostBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      member.roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.green700.withValues(alpha: .65),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.green700.withValues(alpha: .45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HostBadge extends StatelessWidget {
  const _HostBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.green100,
        borderRadius: BorderRadius.circular(TochRadius.pill),
        border: Border.all(color: colors.green200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          'host',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.green,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

List<_ChatMember> _chatMembersFor(
  HomeActivity activity, {
  String? currentUserId,
}) {
  final members = <_ChatMember>[];
  final seenIds = <String>{};

  void addMember(_ChatMember member) {
    if (member.profileId.isEmpty || seenIds.contains(member.profileId)) {
      return;
    }
    seenIds.add(member.profileId);
    members.add(member);
  }

  final currentId = currentUserId ?? '';

  HomeParticipant? hostParticipant;
  for (final participant in activity.participants) {
    if (participant.id == activity.hostId) {
      hostParticipant = participant;
      break;
    }
  }

  addMember(
    _ChatMember.fromHost(
      activity,
      participant: hostParticipant,
      currentUserId: currentUserId,
    ),
  );

  final sortedParticipants = [...activity.participants]
    ..sort((left, right) {
      if (left.isHost != right.isHost) {
        return left.isHost ? -1 : 1;
      }
      return left.displayName.compareTo(right.displayName);
    });

  for (final participant in sortedParticipants) {
    addMember(
      _ChatMember.fromParticipant(participant, currentUserId: currentUserId),
    );
  }

  final shouldIncludeCurrentUser =
      activity.isJoined && (currentId.isEmpty || !seenIds.contains(currentId));
  if (shouldIncludeCurrentUser) {
    members.add(_ChatMember.currentUser(profileId: currentId));
  }

  return members;
}

class _ChatMember {
  const _ChatMember({
    required this.profileId,
    required this.displayName,
    required this.initials,
    required this.isHost,
    this.isCurrentUser = false,
    this.avatarUrl,
  });

  factory _ChatMember.fromHost(
    HomeActivity activity, {
    HomeParticipant? participant,
    String? currentUserId,
  }) {
    final isCurrentUser =
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        activity.hostId == currentUserId;
    final displayName = participant?.displayName.isNotEmpty == true
        ? participant!.displayName
        : activity.hostFullName.isNotEmpty
        ? activity.hostFullName
        : activity.hostName;

    return _ChatMember(
      profileId: activity.hostId,
      displayName: isCurrentUser ? 'Jij' : displayName,
      initials: participant?.initials ?? _initialsFor(displayName),
      isHost: true,
      isCurrentUser: isCurrentUser,
      avatarUrl: participant?.avatarUrl ?? activity.hostAvatarUrl,
    );
  }

  factory _ChatMember.fromParticipant(
    HomeParticipant participant, {
    String? currentUserId,
  }) {
    final isCurrentUser =
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        participant.id == currentUserId;

    return _ChatMember(
      profileId: participant.id,
      displayName: isCurrentUser ? 'Jij' : participant.displayName,
      initials: participant.initials,
      isHost: participant.isHost,
      isCurrentUser: isCurrentUser,
      avatarUrl: participant.avatarUrl,
    );
  }

  factory _ChatMember.currentUser({required String profileId}) {
    return _ChatMember(
      profileId: profileId,
      displayName: 'Jij',
      initials: 'JIJ',
      isHost: false,
      isCurrentUser: true,
    );
  }

  final String profileId;
  final String displayName;
  final String initials;
  final bool isHost;
  final bool isCurrentUser;
  final String? avatarUrl;

  String get roleLabel {
    if (isHost) {
      return isCurrentUser ? 'Jij organiseert' : 'Organisator';
    }
    return isCurrentUser ? 'Jij gaat mee' : 'Deelnemer';
  }
}

String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}
