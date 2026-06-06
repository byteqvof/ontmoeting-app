import '../../domain/entities/activity_chat_notice.dart';

class ActivityChatNoticeModel extends ActivityChatNotice {
  const ActivityChatNoticeModel({
    required super.id,
    required super.activityId,
    required super.senderId,
    required super.body,
    required super.createdAt,
    required super.isMine,
    super.senderName,
    super.senderInitials,
    super.senderAvatarUrl,
    super.activityTitle,
  });

  static ActivityChatNoticeModel? fromRealtimeRecord(
    Map<String, dynamic> record, {
    required String? currentUserId,
  }) {
    final id = _stringValue(record['id']);
    final activityId = _stringValue(
      record['activity_id'] ?? record['activityId'],
    );
    final senderId = _stringValue(record['sender_id'] ?? record['senderId']);
    final sender = _mapValue(record['sender']);
    final senderName = _stringValue(
      sender['display_name'] ?? sender['displayName'],
      fallback: 'Iemand',
    );
    final body = _stringValue(record['body']).trim();
    if (id.isEmpty || activityId.isEmpty || senderId.isEmpty || body.isEmpty) {
      return null;
    }

    return ActivityChatNoticeModel(
      id: id,
      activityId: activityId,
      senderId: senderId,
      senderName: senderName,
      senderInitials: _stringValue(
        sender['initials'],
        fallback: _initialsFor(senderName),
      ),
      senderAvatarUrl: _nullableString(
        sender['avatar_url'] ?? sender['avatarUrl'],
      ),
      activityTitle: _stringValue(
        record['activity_title'] ?? record['activityTitle'],
        fallback: 'Nieuwe chat',
      ),
      body: body,
      createdAt:
          _dateTimeOrNull(record['created_at'] ?? record['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isMine:
          currentUserId != null &&
          currentUserId.isNotEmpty &&
          senderId == currentUserId,
    );
  }
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
}

DateTime? _dateTimeOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  return (DateTime.tryParse(text) ??
          DateTime.tryParse(text.replaceFirst(' ', 'T')))
      ?.toLocal();
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(0, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
