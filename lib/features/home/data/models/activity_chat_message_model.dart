import '../../domain/entities/activity_chat_message.dart';

class ActivityChatMessageModel extends ActivityChatMessage {
  const ActivityChatMessageModel({
    required super.id,
    required super.activityId,
    required super.senderId,
    required super.senderName,
    required super.senderInitials,
    required super.body,
    required super.createdAt,
    required super.isMine,
    super.clientMessageId,
    super.senderAvatarUrl,
  });

  factory ActivityChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    required String? currentUserId,
  }) {
    final sender = _mapValue(json['sender']);
    final senderId = _stringValue(
      json['sender_id'] ?? json['senderId'] ?? sender['id'],
    );
    final senderName = _stringValue(
      sender['display_name'] ?? sender['displayName'],
      fallback: 'Iemand',
    );

    return ActivityChatMessageModel(
      id: _stringValue(json['id']),
      activityId: _stringValue(json['activity_id'] ?? json['activityId']),
      senderId: senderId,
      senderName: senderName,
      senderInitials: _stringValue(
        sender['initials'],
        fallback: _initialsFor(senderName),
      ),
      senderAvatarUrl: _nullableString(
        sender['avatar_url'] ?? sender['avatarUrl'],
      ),
      body: _stringValue(json['body']),
      clientMessageId: _nullableString(
        json['client_message_id'] ?? json['clientMessageId'],
      ),
      createdAt:
          _dateTimeOrNull(json['created_at'] ?? json['createdAt']) ??
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
