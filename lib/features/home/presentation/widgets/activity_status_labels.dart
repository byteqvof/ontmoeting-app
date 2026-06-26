import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_participant.dart';

String activityPrimaryActionLabel(
  HomeActivity activity, {
  String? currentUserId,
}) {
  if (activity.isCompleted) {
    return _completedActivityLabel(activity, currentUserId: currentUserId);
  }
  if (activity.isOwnedByCurrentUser) {
    if (!activity.hasStarted) {
      return 'Nog niet begonnen';
    }
    return 'Afronden';
  }
  if (activity.isParticipationPending) {
    return 'Wacht op akkoord';
  }
  if (!activity.isJoined && activity.availableSpots <= 0) {
    return 'Vol';
  }
  return activity.isJoined ? 'Afmelden' : 'Ga mee';
}

String readOnlyChatNoticeText(HomeActivity activity) {
  if (activity.isCompleted) {
    return 'Deze activiteit is afgerond. Je kunt de chat nog teruglezen.';
  }
  if (activity.participationStatus == 'cancelled' || !activity.isJoined) {
    return 'Je bent afgemeld voor deze activiteit. Je kunt de chat nog teruglezen.';
  }
  return 'Deze chat is nu alleen lezen.';
}

String _completedActivityLabel(HomeActivity activity, {String? currentUserId}) {
  if (activity.isOwnedByCurrentUser) {
    return 'Afgerond';
  }
  if (!activity.isJoined) {
    return 'Afgelopen';
  }

  final participant = currentUserId == null || currentUserId.isEmpty
      ? null
      : _participantById(activity, currentUserId);

  return switch (participant?.attendanceStatus) {
    'present' => 'Je was erbij',
    'absent' => 'Niet aanwezig',
    _ => 'Geweest',
  };
}

HomeParticipant? _participantById(HomeActivity activity, String profileId) {
  for (final participant in activity.participants) {
    if (participant.id == profileId) {
      return participant;
    }
  }
  return null;
}
