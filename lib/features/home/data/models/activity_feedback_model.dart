import '../../domain/entities/activity_feedback.dart';

class ActivityFeedbackModel extends ActivityFeedback {
  const ActivityFeedbackModel({
    required super.id,
    required super.activityId,
    required super.reviewerId,
    required super.targetProfileId,
    required super.targetName,
    required super.targetInitials,
    required super.rating,
    required super.comment,
    required super.createdAt,
    super.targetAvatarUrl,
  });

  factory ActivityFeedbackModel.fromJson(Map<String, dynamic> json) {
    final target = _mapValue(json['target']);
    final targetName = _stringValue(
      target['display_name'] ?? target['displayName'],
      fallback: 'Iemand',
    );

    return ActivityFeedbackModel(
      id: _stringValue(json['id']),
      activityId: _stringValue(json['activity_id'] ?? json['activityId']),
      reviewerId: _stringValue(json['reviewer_id'] ?? json['reviewerId']),
      targetProfileId: _stringValue(
        json['target_profile_id'] ?? json['targetProfileId'] ?? target['id'],
      ),
      targetName: targetName,
      targetInitials: _stringValue(
        target['initials'],
        fallback: _initialsFor(targetName),
      ),
      targetAvatarUrl: _nullableString(
        target['avatar_url'] ?? target['avatarUrl'],
      ),
      rating: _intValue(json['rating']),
      comment: _stringValue(json['comment']),
      createdAt:
          _dateTimeOrNull(json['created_at'] ?? json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
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

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
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
