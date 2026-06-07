import 'package:equatable/equatable.dart';

class ActivityChatNotice extends Equatable {
  const ActivityChatNotice({
    required this.id,
    required this.activityId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    required this.isMine,
    this.senderName = 'Iemand',
    this.senderInitials = '',
    this.senderAvatarUrl,
    this.activityTitle = 'Nieuwe chat',
  });

  final String id;
  final String activityId;
  final String senderId;
  final String senderName;
  final String senderInitials;
  final String? senderAvatarUrl;
  final String activityTitle;
  final String body;
  final DateTime createdAt;
  final bool isMine;

  String get preview {
    final trimmed = body.trim();
    if (trimmed.length <= 90) {
      return trimmed;
    }
    return '${trimmed.substring(0, 87)}...';
  }

  @override
  List<Object?> get props => [
    id,
    activityId,
    senderId,
    senderName,
    senderInitials,
    senderAvatarUrl,
    activityTitle,
    body,
    createdAt,
    isMine,
  ];
}
