import 'package:equatable/equatable.dart';

class CreateActivityDraft extends Equatable {
  const CreateActivityDraft({
    required this.categoryId,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.addressLine,
    required this.city,
    required this.countryCode,
    required this.startsAt,
    required this.maxParticipants,
  });

  final String categoryId;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String addressLine;
  final String city;
  final String countryCode;
  final DateTime startsAt;
  final int maxParticipants;

  @override
  List<Object?> get props => [
    categoryId,
    title,
    description,
    latitude,
    longitude,
    addressLine,
    city,
    countryCode,
    startsAt,
    maxParticipants,
  ];
}
