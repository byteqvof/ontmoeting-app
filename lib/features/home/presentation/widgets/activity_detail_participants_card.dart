import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_activity.dart';

class ActivityDetailParticipantsCard extends StatelessWidget {
  const ActivityDetailParticipantsCard({required this.activity, super.key});

  final HomeActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final participants = _participantsFor(activity);

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
                  activity.isJoined ? 'jij gaat ook' : activity.spotsLabel,
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
                  .map((participant) => _ParticipantPill(participant))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantPill extends StatelessWidget {
  const _ParticipantPill(this.participant);

  final _ActivityParticipant participant;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final isFree = participant.isAvailableSlot;
    final backgroundColor = isFree
        ? colors.cream
        : participant.isCurrentUser
        ? colors.green100
        : colors.card;
    final borderColor = isFree ? colors.line : colors.green200;

    return DecoratedBox(
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
                color: isFree ? Colors.transparent : colors.green,
                shape: BoxShape.circle,
                border: isFree ? Border.all(color: colors.line) : null,
              ),
              child: SizedBox.square(
                dimension: 31,
                child: Center(
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
            ),
            const SizedBox(width: 7),
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
    );
  }
}

List<_ActivityParticipant> _participantsFor(HomeActivity activity) {
  final participants = <_ActivityParticipant>[
    for (final name in activity.participantNames)
      _ActivityParticipant(
        initials: _initialsFor(name),
        label: name == activity.hostName ? 'host' : name,
      ),
  ];

  if (activity.isJoined) {
    participants.add(
      const _ActivityParticipant(
        initials: 'JIJ',
        label: 'jij',
        isCurrentUser: true,
      ),
    );
  }

  participants.addAll(
    List.generate(
      activity.availableSpots,
      (_) => const _ActivityParticipant(
        initials: '',
        label: 'vrij',
        isAvailableSlot: true,
      ),
    ),
  );

  return participants;
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first.characters.take(2).toString().toUpperCase();
  }
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

class _ActivityParticipant {
  const _ActivityParticipant({
    required this.initials,
    required this.label,
    this.isCurrentUser = false,
    this.isAvailableSlot = false,
  });

  final String initials;
  final String label;
  final bool isCurrentUser;
  final bool isAvailableSlot;
}
