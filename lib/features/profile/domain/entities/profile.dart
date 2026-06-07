import 'package:equatable/equatable.dart';

import 'profile_interest.dart';
import 'profile_trust.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.cityName,
    this.ageBand,
    this.gender,
    required this.memberSince,
    required this.avatarUrl,
    required this.attendanceScore,
    required this.activitiesJoinedCount,
    required this.activitiesHostedCount,
    required this.rating,
    required this.isVerified,
    required this.isPremium,
    this.trust = ProfileTrust.empty,
    required this.interests,
  });

  final String id;
  final String displayName;
  final String initials;
  final String cityName;
  final String? ageBand;
  final String? gender;
  final DateTime memberSince;
  final String? avatarUrl;
  final int attendanceScore;
  final int activitiesJoinedCount;
  final int activitiesHostedCount;
  final double rating;
  final bool isVerified;
  final bool isPremium;
  final ProfileTrust trust;
  final List<ProfileInterest> interests;

  @override
  List<Object?> get props => [
    id,
    displayName,
    initials,
    cityName,
    ageBand,
    gender,
    memberSince,
    avatarUrl,
    attendanceScore,
    activitiesJoinedCount,
    activitiesHostedCount,
    rating,
    isVerified,
    isPremium,
    trust,
    interests,
  ];
}
