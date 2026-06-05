import '../../domain/entities/profile_activity.dart';
import '../../domain/entities/profile_interest.dart';
import 'profile_model.dart';

class ProfileActivityModel extends ProfileActivity {
  const ProfileActivityModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.dateLabel,
    required super.timeLabel,
    required super.locationName,
    required super.meetingPoint,
    required super.status,
    required super.availableSpots,
    required super.spotsLabel,
  });

  factory ProfileActivityModel.fromJson(Map<String, dynamic> json) {
    final category = _categoryFromJson(_mapValue(json['category']));
    final startAt = _dateTimeOrNull(
      json['startAt'] ?? json['start_at'] ?? json['starts_at'],
    );
    final status = _stringValue(json['status'], fallback: 'published');
    final maxParticipants = _optionalIntValue(
      json['maxParticipants'] ?? json['max_participants'] ?? json['capacity'],
    );
    final participantCount = _optionalIntValue(
      json['participantCount'] ??
          json['participant_count'] ??
          json['participants_count'],
    );
    final availableSpots =
        _optionalIntValue(json['availableSpots'] ?? json['available_spots']) ??
        _availableSpotsFrom(maxParticipants, participantCount);

    return ProfileActivityModel(
      id: _stringValue(json['id']),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      category: category,
      dateLabel: _stringValue(
        json['dateLabel'] ?? json['date_label'],
        fallback: startAt == null ? '' : _formatDateLabel(startAt),
      ),
      timeLabel: _stringValue(
        json['timeLabel'] ?? json['time_label'],
        fallback: startAt == null ? '' : _formatTimeLabel(startAt),
      ),
      locationName: _stringValue(
        json['locationName'] ??
            json['location_name'] ??
            json['city_name'] ??
            json['city'] ??
            json['address_line'],
      ),
      meetingPoint: _stringValue(
        json['meetingPoint'] ??
            json['meeting_point'] ??
            json['address_line'] ??
            json['address'] ??
            json['city'],
      ),
      status: status,
      availableSpots: availableSpots,
      spotsLabel: _stringValue(
        json['spotsLabel'] ?? json['spots_label'],
        fallback: _spotsLabelFor(status, availableSpots),
      ),
    );
  }
}

ProfileInterest _categoryFromJson(Map<String, dynamic> json) {
  final slug = _stringValue(json['slug'], fallback: 'activity');

  return ProfileInterestModel(
    id: _stringValue(json['id'], fallback: slug),
    label: _stringValue(json['label'] ?? json['title'], fallback: 'Activiteit'),
    iconKey: _stringValue(json['iconKey'] ?? json['icon_key']),
    foregroundColorHex: _stringValue(
      json['foreground_color'] ?? json['color_hex'] ?? json['colorHex'],
      fallback: '#1E5740',
    ),
    backgroundColorHex: _stringValue(
      json['background_color'] ??
          json['background_color_hex'] ??
          json['backgroundColorHex'],
      fallback: '#E6EFE9',
    ),
  );
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

int? _optionalIntValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

int _availableSpotsFrom(int? maxParticipants, int? participantCount) {
  if (maxParticipants == null || maxParticipants <= 0) {
    return 0;
  }
  final remaining = maxParticipants - (participantCount ?? 0);
  return remaining < 0 ? 0 : remaining;
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

String _formatDateLabel(DateTime date) {
  const weekdays = [
    'maandag',
    'dinsdag',
    'woensdag',
    'donderdag',
    'vrijdag',
    'zaterdag',
    'zondag',
  ];
  const months = [
    'jan',
    'feb',
    'mrt',
    'apr',
    'mei',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];

  return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
}

String _formatTimeLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _spotsLabelFor(String status, int availableSpots) {
  return switch (status) {
    'draft' => 'concept',
    'cancelled' => 'geannuleerd',
    'archived' => 'gearchiveerd',
    _ => availableSpots == 1 ? 'nog 1 plek' : 'nog $availableSpots plekken',
  };
}
