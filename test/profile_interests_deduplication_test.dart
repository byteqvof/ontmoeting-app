import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/features/profile/data/models/profile_model.dart';
import 'package:meetings_app/features/profile/domain/entities/profile_interest.dart';
import 'package:meetings_app/features/profile/presentation/widgets/profile_interests_card.dart';

void main() {
  test('profile model keeps each interest only once from backend payload', () {
    final profile = ProfileModel.fromJson({
      'id': 'profile-1',
      'display_name': 'Joren',
      'initials': 'JO',
      'city_name': 'Ter Apel',
      'member_since': '2026-06-01T00:00:00.000Z',
      'avatar_url': null,
      'attendance_score': 100,
      'activities_joined_count': 0,
      'activities_hosted_count': 0,
      'rating': 0,
      'is_premium': false,
      'trust': const {},
      'interests': const [
        {
          'id': 'sport',
          'label': 'Sport',
          'icon_key': 'sports_basketball',
          'foreground_color': '#1E5740',
          'background_color': '#E6EFE9',
        },
        {
          'id': 'sport',
          'label': 'Sport',
          'icon_key': 'sports_basketball',
          'foreground_color': '#1E5740',
          'background_color': '#E6EFE9',
        },
        {
          'id': 'outside',
          'label': 'Buiten',
          'icon_key': 'favorite',
          'foreground_color': '#1E5740',
          'background_color': '#E6EFE9',
        },
      ],
    });

    expect(profile.interests.map((interest) => interest.id), [
      'sport',
      'outside',
    ]);
  });

  testWidgets('profile interests card renders duplicate interests once', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProfileInterestsCard(
            interests: [_sportInterest, _sportInterest, _outsideInterest],
          ),
        ),
      ),
    );

    expect(find.text('Sport'), findsOneWidget);
    expect(find.text('Buiten'), findsOneWidget);
  });

  testWidgets('profile interests card fills the available profile width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: Column(
                children: [
                  ProfileInterestsCard(
                    interests: [_sportInterest, _outsideInterest],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final cardWidth = tester.getSize(find.byType(DecoratedBox).first).width;

    expect(cardWidth, 360);
  });
}

const _sportInterest = ProfileInterest(
  id: 'sport',
  label: 'Sport',
  iconKey: 'sports_basketball',
  foregroundColorHex: '#1E5740',
  backgroundColorHex: '#E6EFE9',
);

const _outsideInterest = ProfileInterest(
  id: 'outside',
  label: 'Buiten',
  iconKey: 'favorite',
  foregroundColorHex: '#1E5740',
  backgroundColorHex: '#E6EFE9',
);
