import 'package:equatable/equatable.dart';

class ActivityChatMessage extends Equatable {
  const ActivityChatMessage({
    required this.id,
    required this.activityId,
    required this.senderId,
    required this.senderName,
    required this.senderInitials,
    required this.body,
    required this.createdAt,
    required this.isMine,
    this.senderAvatarUrl,
  });

  final String id;
  final String activityId;
  final String senderId;
  final String senderName;
  final String senderInitials;
  final String? senderAvatarUrl;
  final String body;
  final DateTime createdAt;
  final bool isMine;

  @override
  List<Object?> get props => [
    id,
    activityId,
    senderId,
    senderName,
    senderInitials,
    senderAvatarUrl,
    body,
    createdAt,
    isMine,
  ];
}
