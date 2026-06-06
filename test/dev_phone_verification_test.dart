import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/config/supabase_config.dart';
import 'package:meetings_app/core/services/account_trust_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('dev phone verification', () {
    test('allows fake phone verification only in dev when requested', () {
      expect(
        isFakePhoneVerificationAllowed(environment: 'dev', requested: true),
        isTrue,
      );
      expect(
        isFakePhoneVerificationAllowed(environment: 'dev', requested: false),
        isFalse,
      );
      expect(
        isFakePhoneVerificationAllowed(environment: 'prod', requested: true),
        isFalse,
      );
      expect(
        isFakePhoneVerificationAllowed(
          environment: 'production',
          requested: true,
        ),
        isFalse,
      );
    });

    test(
      'stores fake phone verification after a fake code is verified',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final service = AccountTrustService(
          SupabaseClient('https://example.supabase.co', 'anon-key'),
          preferences,
          fakePhoneVerification: true,
        );

        await service.requestPhoneCode('+31625215170');
        final trust = await service.verifyPhoneCode(
          phoneNumber: '+31625215170',
          token: '1234',
        );
        final syncedTrust = await service.syncTrust();

        expect(trust.phoneVerified, isTrue);
        expect(trust.phoneVerifiedAt, isNotNull);
        expect(syncedTrust.phoneVerified, isTrue);
        expect(syncedTrust.phoneVerifiedAt, isNotNull);
      },
    );

    test('rejects fake verification before a fake code is requested', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = AccountTrustService(
        SupabaseClient('https://example.supabase.co', 'anon-key'),
        preferences,
        fakePhoneVerification: true,
      );

      expect(
        () =>
            service.verifyPhoneCode(phoneNumber: '+31625215170', token: '1234'),
        throwsA(isA<AccountTrustException>()),
      );
    });

    test('rejects fake verification codes shorter than four digits', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = AccountTrustService(
        SupabaseClient('https://example.supabase.co', 'anon-key'),
        preferences,
        fakePhoneVerification: true,
      );

      await service.requestPhoneCode('+31625215170');

      expect(
        () =>
            service.verifyPhoneCode(phoneNumber: '+31625215170', token: '123'),
        throwsA(isA<AccountTrustException>()),
      );
    });
  });
}
