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
    this.groupType = 'open',
    this.minReputationLevel = 'new_member',
    this.requiresIdentityVerified = false,
    this.isPrivateLocation = false,
    this.targetAgeBands = const [],
    this.targetGenders = const [],
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
  final String groupType;
  final String minReputationLevel;
  final bool requiresIdentityVerified;
  final bool isPrivateLocation;
  final List<String> targetAgeBands;
  final List<String> targetGenders;

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
    groupType,
    minReputationLevel,
    requiresIdentityVerified,
    isPrivateLocation,
    targetAgeBands,
    targetGenders,
  ];
}
