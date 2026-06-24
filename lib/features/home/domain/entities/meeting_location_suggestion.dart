import 'package:equatable/equatable.dart';

class MeetingLocationSuggestion extends Equatable {
  const MeetingLocationSuggestion({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.postcode,
    this.source = 'pdok',
  });

  final String id;
  final String label;
  final String addressLine;
  final String city;
  final String type;
  final double latitude;
  final double longitude;
  final String? postcode;
  final String source;

  @override
  List<Object?> get props => [
    id,
    label,
    addressLine,
    city,
    type,
    latitude,
    longitude,
    postcode,
    source,
  ];
}
