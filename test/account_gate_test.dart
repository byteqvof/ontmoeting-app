import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/toch_theme.dart';
import 'package:meetings_app/core/di/injection_container.dart';
import 'package:meetings_app/core/services/account_trust_service.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_trust.dart';
import 'package:meetings_app/features/profile/presentation/pages/account_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  tearDown(() async {
    AccountGate.resetSessionCache();
    await sl.reset();
  });

  testWidgets(
    'does not recheck account trust for an already verified user during navigation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = _CountingAccountTrustService(preferences);
      sl.registerLazySingleton<AccountTrustService>(() => service);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [TochTokens.light()]),
          home: const AccountGate(
            key: ValueKey('route-one'),
            child: Text('route one'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('route one'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [TochTokens.light()]),
          home: const AccountGate(
            key: ValueKey('route-two'),
            child: Text('route two'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('route two'), findsOneWidget);
      expect(find.text('Account controleren'), findsNothing);
      expect(service.syncTrustCalls, 1);
    },
  );
}

class _CountingAccountTrustService extends AccountTrustService {
  _CountingAccountTrustService(SharedPreferences preferences)
    : super(_testSupabaseClient(), preferences);

  int syncTrustCalls = 0;

  @override
  Future<ProfileTrust> syncTrust() async {
    syncTrustCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return ProfileTrust(
      phoneVerified: true,
      phoneVerifiedAt: DateTime(2026, 6, 26, 12),
      identityStatus: 'unverified',
      identityMethod: null,
      identityCompletedAt: null,
      ageVerified: false,
      reputationLevel: 'new_member',
      reputationScore: 0,
    );
  }
}

SupabaseClient _testSupabaseClient() {
  return SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}
