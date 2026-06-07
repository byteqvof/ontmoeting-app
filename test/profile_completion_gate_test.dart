import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/toch_theme.dart';
import 'package:meetings_app/core/di/injection_container.dart';
import 'package:meetings_app/core/errors/failures.dart';
import 'package:meetings_app/features/profile/domain/entities/create_profile_draft.dart';
import 'package:meetings_app/features/profile/domain/entities/profile.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_activity.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_interest.dart';
import 'package:meetings_app/features/profile/domain/entities/update_profile_draft.dart';
import 'package:meetings_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:meetings_app/features/profile/domain/usecases/is_profile_onboarding_required.dart';
import 'package:meetings_app/features/profile/presentation/pages/profile_completion_gate.dart';

void main() {
  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'allows app through when profile status check has network issues',
    (tester) async {
      sl.registerLazySingleton(
        () => IsProfileOnboardingRequired(
          const _NetworkFailingProfileRepository(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [TochTokens.light()]),
          home: const ProfileCompletionGate(child: Text('home is available')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('home is available'), findsOneWidget);
      expect(find.text('Profielstatus onbekend'), findsNothing);
    },
  );
}

class _NetworkFailingProfileRepository implements ProfileRepository {
  const _NetworkFailingProfileRepository();

  @override
  Future<Either<Failure, bool>> isProfileOnboardingRequired() async {
    return left(
      const NetworkFailure('De verbinding hapert. Probeer het opnieuw.'),
    );
  }

  @override
  Future<Either<Failure, Profile>> createProfile(
    CreateProfileDraft draft,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ProfileInterest>>> getAvailableInterests() async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<ProfileActivity>>> getActivitiesForUser({
    String? profileId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Profile>> getProfile({String? profileId}) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, Profile>> updateProfile(
    UpdateProfileDraft draft,
  ) async {
    throw UnimplementedError();
  }
}
