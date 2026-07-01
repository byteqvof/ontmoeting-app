import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/services/activity_share_service.dart';
import 'package:meetings_app/core/utils/activity_deep_links.dart';
import 'package:meetings_app/features/home/domain/entities/home_activity.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';

void main() {
  test('builds share text with a public activity link', () {
    final activity = _activity();

    final text = buildActivityShareText(
      activity,
      publicBaseUrl: 'https://gatoch.nl',
    );

    expect(text, contains(activity.title));
    expect(text, contains('https://gatoch.nl/activities/activity-1'));
    expect(text, isNot(contains('meetingsapp://')));
  });

  test('falls back to a Supabase hosted activity share page', () {
    final uri = activityShareUri(
      'activity-1',
      supabaseProjectUrl: 'https://example.supabase.co',
    );

    expect(
      uri.toString(),
      'https://example.supabase.co/functions/v1/activity-share'
      '?activity_id=activity-1',
    );
  });

  test('parses gatoch activity links back to an activity id', () {
    final uri = Uri.parse('https://gatoch.nl/activities/activity-1');

    expect(activityIdFromActivityDetailDeepLink(uri), 'activity-1');
  });
}

HomeActivity _activity() {
  return HomeActivity(
    id: 'activity-1',
    category: const HomeCategory(
      id: 'outside',
      label: 'Buiten',
      icon: Icons.park_rounded,
      color: Color(0xFF1E5740),
      backgroundColor: Color(0xFFE6EFE9),
    ),
    distanceKm: 1.2,
    distanceLabel: '1,2 km',
    title: 'Avondvissen aan de Maas',
    dateLabel: 'vrijdag 26 jun',
    timeLabel: '17:00',
    locationName: 'Ter Apel',
    meetingPoint: 'Markeweg 23',
    description: 'Ik ga testen. Sluit gezellig aan.',
    hostId: 'host-1',
    hostName: 'Joren',
    hostFullName: 'Joren',
    hostSubtitle: 'Ter Apel',
    hostScore: 55,
    participants: const [],
    availableSpots: 4,
    spotsLabel: 'nog 4 plekken',
  );
}
