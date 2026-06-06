import 'package:equatable/equatable.dart';

class ProfileTrust extends Equatable {
  const ProfileTrust({
    required this.phoneVerified,
    required this.phoneVerifiedAt,
    required this.identityStatus,
    required this.identityMethod,
    required this.identityCompletedAt,
    required this.ageVerified,
    required this.reputationLevel,
    required this.reputationScore,
  });

  static const empty = ProfileTrust(
    phoneVerified: false,
    phoneVerifiedAt: null,
    identityStatus: 'unverified',
    identityMethod: null,
    identityCompletedAt: null,
    ageVerified: false,
    reputationLevel: 'new_member',
    reputationScore: 0,
  );

  final bool phoneVerified;
  final DateTime? phoneVerifiedAt;
  final String identityStatus;
  final String? identityMethod;
  final DateTime? identityCompletedAt;
  final bool ageVerified;
  final String reputationLevel;
  final int reputationScore;

  bool get identityVerified => identityStatus == 'verified';

  String get identityStatusLabel {
    return switch (identityStatus) {
      'verified' => 'Identiteit bevestigd',
      'pending' => 'Identiteitscontrole loopt',
      'rejected' => 'Identiteit niet bevestigd',
      'expired' => 'Identiteitscontrole verlopen',
      _ => 'Identiteit niet bevestigd',
    };
  }

  String get phoneStatusLabel {
    return phoneVerified ? 'Telefoon bevestigd' : 'Telefoon niet bevestigd';
  }

  String get reputationLabel {
    return switch (reputationLevel) {
      'top_participant' => 'Top deelnemer',
      'known_member' => 'Bekend lid',
      'active_member' => 'Actief lid',
      _ => 'Nieuw lid',
    };
  }

  @override
  List<Object?> get props => [
    phoneVerified,
    phoneVerifiedAt,
    identityStatus,
    identityMethod,
    identityCompletedAt,
    ageVerified,
    reputationLevel,
    reputationScore,
  ];
}
