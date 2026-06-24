import '../../domain/entities/meeting_location_suggestion.dart';

class MeetingLocationSuggestionModel extends MeetingLocationSuggestion {
  const MeetingLocationSuggestionModel({
    required super.id,
    required super.label,
    required super.addressLine,
    required super.city,
    required super.type,
    required super.latitude,
    required super.longitude,
    super.postcode,
    super.source,
  });

  factory MeetingLocationSuggestionModel.fromJson(Map<String, dynamic> json) {
    return MeetingLocationSuggestionModel(
      id: _stringValue(json['id']),
      label: _stringValue(json['label']),
      addressLine: _stringValue(json['address_line'] ?? json['addressLine']),
      city: _stringValue(json['city']),
      type: _stringValue(json['type']),
      latitude: _doubleValue(json['latitude']),
      longitude: _doubleValue(json['longitude']),
      postcode: _nullableString(json['postcode']),
      source: _stringValue(json['source'], fallback: 'pdok'),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
}

double _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
