import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/profile/data/models/profile_trust_model.dart';

void main() {
  test('maps verified identity and phone status from backend json', () {
    final trust = ProfileTrustModel.fromJson({
      'phone_verified': true,
      'phone_verified_at': '2026-06-06T10:30:00Z',
      'identity_status': 'verified',
      'identity_method': 'idin',
      'identity_completed_at': '2026-06-06T11:00:00Z',
      'age_verified': false,
      'reputation_level': 'known_member',
      'reputation_score': 72,
    });

    expect(trust.phoneVerified, isTrue);
    expect(trust.identityVerified, isTrue);
    expect(trust.identityMethod, 'idin');
    expect(trust.reputationLabel, 'Bekend lid');
    expect(trust.reputationScore, 72);
  });

  test('falls back to safe defaults for missing trust json', () {
    final trust = ProfileTrustModel.fromJson(const {});

    expect(trust.phoneVerified, isFalse);
    expect(trust.identityVerified, isFalse);
    expect(trust.reputationLabel, 'Nieuw lid');
    expect(trust.reputationScore, 0);
  });
}
