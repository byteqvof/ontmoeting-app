import '../../domain/entities/profile_trust.dart';

class ProfileTrustModel extends ProfileTrust {
  const ProfileTrustModel({
    required super.phoneVerified,
    required super.phoneVerifiedAt,
    required super.identityStatus,
    required super.identityMethod,
    required super.identityCompletedAt,
    required super.ageVerified,
    required super.reputationLevel,
    required super.reputationScore,
  });

  factory ProfileTrustModel.fromEntity(ProfileTrust trust) {
    return ProfileTrustModel(
      phoneVerified: trust.phoneVerified,
      phoneVerifiedAt: trust.phoneVerifiedAt,
      identityStatus: trust.identityStatus,
      identityMethod: trust.identityMethod,
      identityCompletedAt: trust.identityCompletedAt,
      ageVerified: trust.ageVerified,
      reputationLevel: trust.reputationLevel,
      reputationScore: trust.reputationScore,
    );
  }

  factory ProfileTrustModel.fromJson(Map<String, dynamic> json) {
    return ProfileTrustModel(
      phoneVerified: _boolValue(json['phone_verified']),
      phoneVerifiedAt: _dateValue(json['phone_verified_at']),
      identityStatus: _stringValue(
        json['identity_status'],
        fallback: 'unverified',
      ),
      identityMethod: _nullableString(json['identity_method']),
      identityCompletedAt: _dateValue(json['identity_completed_at']),
      ageVerified: _boolValue(json['age_verified']),
      reputationLevel: _stringValue(
        json['reputation_level'],
        fallback: 'new_member',
      ),
      reputationScore: _intValue(json['reputation_score']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_verified': phoneVerified,
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'identity_status': identityStatus,
      'identity_method': identityMethod,
      'identity_completed_at': identityCompletedAt?.toIso8601String(),
      'age_verified': ageVerified,
      'reputation_level': reputationLevel,
      'reputation_score': reputationScore,
    };
  }
}

DateTime? _dateValue(Object? value) {
  final text = _nullableString(value);
  if (text == null) {
    return null;
  }
  return DateTime.tryParse(text);
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
