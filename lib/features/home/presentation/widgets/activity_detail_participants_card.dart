import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/domain/usecases/get_profile.dart';
import '../../domain/entities/home_activity.dart';

class ActivityDetailParticipantsCard extends StatefulWidget {
  const ActivityDetailParticipantsCard({
    required this.activity,
    this.onProfilePressed,
    super.key,
  });

  final HomeActivity activity;
  final ValueChanged<String>? onProfilePressed;

  @override
  State<ActivityDetailParticipantsCard> createState() =>
      _ActivityDetailParticipantsCardState();
}

class _ActivityDetailParticipantsCardState
    extends State<ActivityDetailParticipantsCard> {
  final GetProfile _getProfile = sl();

  Profile? _currentProfile;
  bool _didLoadCurrentProfile = false;

  @override
  void initState() {
    super.initState();
    if (widget.activity.isJoined) {
      unawaited(_loadCurrentProfile());
    }
  }

  @override
  void didUpdateWidget(ActivityDetailParticipantsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activity.isJoined && !_didLoadCurrentProfile) {
      unawaited(_loadCurrentProfile());
    }
  }

  Future<void> _loadCurrentProfile() async {
    _didLoadCurrentProfile = true;
    final result = await _getProfile(const GetProfileParams());
    if (!mounted) {
      return;
    }

    result.fold((_) {}, (profile) {
      setState(() {
        _currentProfile = profile;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final participants = _participantsFor(
      widget.activity,
      currentProfile: _currentProfile,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Wie gaan er',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  widget.activity.isJoined
                      ? 'jij gaat ook'
                      : widget.activity.spotsLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.green700.withValues(alpha: .72),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TochSpacing.md),
            Wrap(
              spacing: TochSpacing.sm,
              runSpacing: TochSpacing.sm,
              children: participants
                  .map(
                    (participant) => _ParticipantPill(
                      participant,
                      onProfilePressed: widget.onProfilePressed,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantPill extends StatelessWidget {
  const _ParticipantPill(this.participant, {required this.onProfilePressed});

  final _ActivityParticipant participant;
  final ValueChanged<String>? onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final isFree = participant.isAvailableSlot;
    final isHost = participant.isHost;
    final backgroundColor = isFree
        ? colors.cream
        : isHost
        ? const Color(0xFFFFF6D8)
        : participant.isCurrentUser
        ? colors.green100
        : colors.card;
    final borderColor = isFree
        ? colors.line
        : isHost
        ? const Color(0xFFD8A928)
        : colors.green200;
    final avatarBackgroundColor = isFree
        ? Colors.transparent
        : isHost
        ? const Color(0xFFB88900)
        : colors.green;
    final canOpenProfile =
        participant.profileId.isNotEmpty && onProfilePressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canOpenProfile
          ? () => onProfilePressed!(participant.profileId)
          : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(TochRadius.pill),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: avatarBackgroundColor,
                  shape: BoxShape.circle,
                  border: isFree ? Border.all(color: colors.line) : null,
                ),
                child: CircleAvatar(
                  radius: 15.5,
                  backgroundColor: avatarBackgroundColor,
                  foregroundImage: participant.avatarUrl == null
                      ? null
                      : NetworkImage(participant.avatarUrl!),
                  child: Text(
                    participant.initials,
                    style: TextStyle(
                      color: isFree
                          ? colors.green700.withValues(alpha: .55)
                          : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              if (isHost) ...[
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 15,
                  color: const Color(0xFF9A6A00),
                ),
                const SizedBox(width: 3),
              ],
              Text(
                participant.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isFree
                      ? colors.green700.withValues(alpha: .65)
                      : colors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<_ActivityParticipant> _participantsFor(
  HomeActivity activity, {
  Profile? currentProfile,
}) {
  final participants = <_ActivityParticipant>[];
  final hostId = activity.hostId.trim();
  if (hostId.isNotEmpty) {
    participants.add(
      _ActivityParticipant(
        profileId: hostId,
        initials: _safeInitials(_initialsFor(activity.hostFullName)),
        label: activity.hostFullName.isEmpty
            ? activity.hostName
            : activity.hostFullName,
        avatarUrl: activity.hostAvatarUrl,
        isHost: true,
      ),
    );
  }

  for (final participant in activity.participants) {
    if (participant.id.isNotEmpty && participant.id == hostId) {
      continue;
    }
    participants.add(
      _ActivityParticipant(
        profileId: participant.id,
        initials: participant.initials,
        label: participant.displayName,
        avatarUrl: participant.avatarUrl,
        isHost: participant.isHost,
      ),
    );
  }

  final currentProfileId = currentProfile?.id.trim() ?? '';
  final hasCurrentProfile =
      currentProfileId.isNotEmpty &&
      participants.any(
        (participant) => participant.profileId == currentProfileId,
      );
  if (activity.isJoined && !hasCurrentProfile) {
    participants.add(
      _ActivityParticipant(
        profileId: currentProfile?.id ?? '',
        initials: _safeInitials(currentProfile?.initials),
        label: 'jij',
        avatarUrl: currentProfile?.avatarUrl,
        isCurrentUser: true,
      ),
    );
  }

  participants.addAll(
    List.generate(
      activity.availableSpots,
      (_) => const _ActivityParticipant(
        profileId: '',
        initials: '',
        label: 'vrij',
        avatarUrl: null,
        isAvailableSlot: true,
      ),
    ),
  );

  return participants;
}

String _safeInitials(String? initials) {
  final normalized = initials?.trim();
  if (normalized == null || normalized.isEmpty) {
    return 'IK';
  }
  return normalized;
}

class _ActivityParticipant {
  const _ActivityParticipant({
    required this.profileId,
    required this.initials,
    required this.label,
    required this.avatarUrl,
    this.isCurrentUser = false,
    this.isHost = false,
    this.isAvailableSlot = false,
  });

  final String profileId;
  final String initials;
  final String label;
  final String? avatarUrl;
  final bool isCurrentUser;
  final bool isHost;
  final bool isAvailableSlot;
}

String _initialsFor(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return '';
  }
  if (words.length == 1) {
    return words.first.characters.take(2).toString().toUpperCase();
  }
  return words
      .take(2)
      .map((word) => word.characters.first)
      .join()
      .toUpperCase();
}
