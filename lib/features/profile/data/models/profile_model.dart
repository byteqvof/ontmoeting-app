import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_interest.dart';
import 'profile_trust_model.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.displayName,
    required super.initials,
    required super.cityName,
    super.ageBand,
    super.gender,
    required super.memberSince,
    required super.avatarUrl,
    required super.attendanceScore,
    required super.activitiesJoinedCount,
    required super.activitiesHostedCount,
    required super.rating,
    required super.isVerified,
    required super.isPremium,
    required super.trust,
    required super.interests,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final trust = ProfileTrustModel.fromJson(_mapValue(json['trust']));

    return ProfileModel(
      id: _stringValue(json['id']),
      displayName: _stringValue(json['display_name']),
      initials: _stringValue(json['initials']),
      cityName: _stringValue(json['city_name']),
      ageBand: _nullableString(json['age_band']),
      gender: _nullableString(json['gender']),
      memberSince:
          DateTime.tryParse(_stringValue(json['member_since'])) ??
          DateTime.now(),
      avatarUrl: _nullableString(json['avatar_url']),
      attendanceScore: _intValue(json['attendance_score'], fallback: 100),
      activitiesJoinedCount: _intValue(json['activities_joined_count']),
      activitiesHostedCount: _intValue(json['activities_hosted_count']),
      rating: _doubleValue(json['rating']),
      isVerified: trust.identityVerified,
      isPremium: _boolValue(json['is_premium']),
      trust: trust,
      interests: _uniqueInterests(
        _listValue(json['interests'])
            .map(
              (interest) => ProfileInterestModel.fromJson(_mapValue(interest)),
            )
            .where((interest) => interest.id.isNotEmpty),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'initials': initials,
      'city_name': cityName,
      'age_band': ageBand,
      'gender': gender,
      'member_since': memberSince.toIso8601String(),
      'avatar_url': avatarUrl,
      'attendance_score': attendanceScore,
      'activities_joined_count': activitiesJoinedCount,
      'activities_hosted_count': activitiesHostedCount,
      'rating': rating,
      'is_verified': isVerified,
      'is_premium': isPremium,
      'trust': ProfileTrustModel.fromEntity(trust).toJson(),
      'interests': interests
          .map((interest) => ProfileInterestModel.fromEntity(interest).toJson())
          .toList(),
    };
  }
}

class ProfileInterestModel extends ProfileInterest {
  const ProfileInterestModel({
    required super.id,
    required super.label,
    required super.iconKey,
    required super.foregroundColorHex,
    required super.backgroundColorHex,
  });

  factory ProfileInterestModel.fromEntity(ProfileInterest interest) {
    return ProfileInterestModel(
      id: interest.id,
      label: interest.label,
      iconKey: interest.iconKey,
      foregroundColorHex: interest.foregroundColorHex,
      backgroundColorHex: interest.backgroundColorHex,
    );
  }

  factory ProfileInterestModel.fromJson(Map<String, dynamic> json) {
    return ProfileInterestModel(
      id: _stringValue(json['id']),
      label: _stringValue(json['label'] ?? json['title']),
      iconKey: _stringValue(json['icon_key']),
      foregroundColorHex: _stringValue(
        json['foreground_color'] ?? json['color_hex'],
      ),
      backgroundColorHex: _stringValue(
        json['background_color'] ?? json['background_color_hex'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'icon_key': iconKey,
      'foreground_color': foregroundColorHex,
      'background_color': backgroundColorHex,
    };
  }
}

List<ProfileInterestModel> _uniqueInterests(
  Iterable<ProfileInterestModel> interests,
) {
  final seen = <String>{};
  final unique = <ProfileInterestModel>[];

  for (final interest in interests) {
    final key = interest.id.trim().toLowerCase();
    if (key.isEmpty || !seen.add(key)) {
      continue;
    }
    unique.add(interest);
  }

  return unique;
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

List<Object?> _listValue(Object? value) {
  if (value is List) {
    return value;
  }
  return const [];
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

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolValue(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  return switch (value?.toString().toLowerCase()) {
    'true' || '1' || 'yes' => true,
    'false' || '0' || 'no' => false,
    _ => fallback,
  };
}
