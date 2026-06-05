import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/create_activity_draft.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_location.dart';

abstract interface class HomeRemoteDataSource {
  Future<String> createActivity(CreateActivityDraft draft);

  Future<HomeFeed> getHomeFeed({
    required HomeLocation location,
    required int distanceKm,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<String> createActivity(CreateActivityDraft draft) async {
    AppLogger.debug('Creating activity "${draft.title}"');

    final response = await _client.functions.invoke(
      supabaseCreateActivityFunctionName,
      body: {
        'category_id': draft.categoryId,
        'title': draft.title,
        'description': draft.description,
        'latitude': draft.latitude,
        'longitude': draft.longitude,
        'address_line': draft.addressLine,
        'city': draft.city,
        'country_code': draft.countryCode,
        'starts_at': draft.startsAt.toUtc().toIso8601String(),
        'max_participants': draft.maxParticipants,
      },
    );

    final payload = _asMap(response.data);
    final activity = _asMap(payload['activity']);
    final activityId = _stringValue(activity['id']);
    if (activityId.isEmpty) {
      throw StateError('Create activity completed without an activity id.');
    }

    AppLogger.debug('Created activity $activityId');
    return activityId;
  }

  @override
  Future<HomeFeed> getHomeFeed({
    required HomeLocation location,
    required int distanceKm,
  }) async {
    AppLogger.debug(
      'Fetching nearby activities for ${location.latitude}, '
      '${location.longitude} in ${distanceKm}km',
    );

    final response = await _client.functions.invoke(
      supabaseNearbyActivitiesFunctionName,
      body: {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'radius_km': distanceKm,
        'limit': 50,
      },
    );

    final payload = _asMap(response.data);
    final activitiesJson = _asList(payload['activities']);
    final activities = activitiesJson
        .map((activity) => _activityFromJson(_asMap(activity)))
        .toList();
    final categories = await _categoriesFromPayload(payload, activities);

    return HomeFeed(
      locationName: location.cityName,
      selectedTimeFilter: 'Alles',
      selectedDistanceKm: distanceKm,
      timeFilters: const ['Alles', 'Vandaag', 'Dit weekend'],
      distanceFilters: const [5, 10, 25, 50],
      categories: categories,
      activities: activities,
    );
  }

  Future<List<HomeCategory>> _categoriesFromPayload(
    Map<String, dynamic> payload,
    List<HomeActivity> activities,
  ) async {
    final categoriesJson = _asList(payload['categories']);
    final categories = categoriesJson.isNotEmpty
        ? categoriesJson
              .map((category) => _categoryFromJson(_asMap(category)))
              .toList()
        : await _fetchActivityCategories();

    final uniqueCategories = <String, HomeCategory>{};
    for (final category in [
      ...categories,
      ...activities.map((activity) => activity.category),
    ]) {
      uniqueCategories[category.id] = category;
    }

    final sortedCategories = _sortedCategories(
      uniqueCategories.values.where((category) => category.id != 'all'),
    );
    if (sortedCategories.isEmpty) {
      throw StateError(
        'No activity categories available. Check activity_categories read access.',
      );
    }

    return [_allCategory, ...sortedCategories];
  }

  Future<List<HomeCategory>> _fetchActivityCategories() async {
    try {
      final data = await _client.from('activity_categories').select();

      final categories = _asList(data)
          .map((category) => _categoryFromJson(_asMap(category)))
          .where((category) => category.id.isNotEmpty)
          .toList();

      AppLogger.debug('Fetched ${categories.length} activity categories');
      return categories;
    } catch (error) {
      AppLogger.debug('Fetching activity categories failed: $error');
      return const [];
    }
  }

  HomeActivity _activityFromJson(Map<String, dynamic> json) {
    final category = _categoryFromJson(_asMap(json['category']));
    final host = _asMap(json['host']);
    final participants = _asList(
      json['participantPreview'] ?? json['participant_preview'],
    ).map((participant) => _asMap(participant)).toList();
    final startAt = _dateTimeOrNull(json['startAt'] ?? json['start_at']);
    final availableSpots = _intValue(
      json['availableSpots'] ?? json['available_spots'],
    );
    final isJoined = _boolValue(json['isJoined'] ?? json['is_joined']);
    final distanceKm = _doubleValue(json['distanceKm'] ?? json['distance_km']);

    return HomeActivity(
      id: _stringValue(json['id']),
      category: category,
      distanceKm: distanceKm,
      distanceLabel: _stringValue(
        json['distanceLabel'] ?? json['distance_label'],
        fallback: _formatDistance(distanceKm),
      ),
      title: _stringValue(json['title']),
      dateLabel: _stringValue(
        json['dateLabel'] ?? json['date_label'],
        fallback: startAt == null ? '' : _formatDateLabel(startAt),
      ),
      timeLabel: _stringValue(
        json['timeLabel'] ?? json['time_label'],
        fallback: startAt == null ? '' : _formatTimeLabel(startAt),
      ),
      locationName: _stringValue(
        json['locationName'] ?? json['location_name'] ?? json['city_name'],
      ),
      meetingPoint: _stringValue(json['meetingPoint'] ?? json['meeting_point']),
      description: _stringValue(json['description']),
      hostName: _stringValue(
        host['shortName'] ?? host['short_name'] ?? host['displayName'],
      ),
      hostFullName: _stringValue(host['displayName'] ?? host['display_name']),
      hostSubtitle: _stringValue(host['subtitle']),
      hostScore: _intValue(
        host['attendanceScore'] ?? host['attendance_score'],
        fallback: 100,
      ),
      participantInitials: participants
          .map((participant) => _stringValue(participant['initials']))
          .where((initials) => initials.isNotEmpty)
          .toList(),
      participantNames: participants
          .map(
            (participant) => _stringValue(
              participant['displayName'] ?? participant['display_name'],
            ),
          )
          .where((name) => name.isNotEmpty)
          .toList(),
      availableSpots: availableSpots,
      spotsLabel: _stringValue(
        json['spotsLabel'] ?? json['spots_label'],
        fallback: isJoined ? 'jij gaat ook' : 'nog $availableSpots plekken',
      ),
      isJoined: isJoined,
    );
  }

  HomeCategory _categoryFromJson(Map<String, dynamic> json) {
    final slug = _stringValue(json['slug'], fallback: 'unknown');

    return HomeCategory(
      id: _stringValue(json['id'], fallback: slug),
      label: _stringValue(json['label'] ?? json['title'], fallback: slug),
      icon: _iconForKey(_stringValue(json['iconKey'] ?? json['icon_key'])),
      color: _colorFromHex(
        _stringValue(
          json['colorHex'] ?? json['color_hex'] ?? json['foreground_color'],
        ),
        fallback: const Color(0xFF1E5740),
      ),
      backgroundColor: _colorFromHex(
        _stringValue(
          json['backgroundColorHex'] ??
              json['background_color_hex'] ??
              json['background_color'],
        ),
        fallback: const Color(0xFFE6EFE9),
      ),
    );
  }
}

const _allCategory = HomeCategory(
  id: 'all',
  label: 'Alles',
  icon: Icons.grid_view_rounded,
  color: Color(0xFF19211C),
  backgroundColor: Color(0xFFFFFFFF),
);

List<HomeCategory> _sortedCategories(Iterable<HomeCategory> categories) {
  return categories.toList()..sort(
    (left, right) =>
        left.label.toLowerCase().compareTo(right.label.toLowerCase()),
  );
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is String) {
    final decoded = jsonDecode(value);
    return _asMap(decoded);
  }
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _asList(Object? value) {
  if (value is String) {
    final decoded = jsonDecode(value);
    return _asList(decoded);
  }
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

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
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

DateTime? _dateTimeOrNull(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}

String _formatDistance(double distanceKm) {
  return '${distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km';
}

String _formatDateLabel(DateTime date) {
  const weekdays = [
    'maandag',
    'dinsdag',
    'woensdag',
    'donderdag',
    'vrijdag',
    'zaterdag',
    'zondag',
  ];
  const months = [
    'jan',
    'feb',
    'mrt',
    'apr',
    'mei',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];

  return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
}

String _formatTimeLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Color _colorFromHex(String hex, {required Color fallback}) {
  final normalized = hex.replaceFirst('#', '').trim();
  if (normalized.length != 6 && normalized.length != 8) {
    return fallback;
  }

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return fallback;
  }

  return Color(normalized.length == 6 ? 0xFF000000 | value : value);
}

IconData _iconForKey(String key) {
  return switch (key) {
    'set_meal' || 'fishing' => Icons.set_meal_rounded,
    'directions_walk' || 'walking' => Icons.directions_walk_rounded,
    'local_cafe' || 'coffee' => Icons.local_cafe_rounded,
    'sports_basketball' || 'sport' => Icons.sports_basketball_rounded,
    'sports_esports' || 'gaming' => Icons.sports_esports_rounded,
    'two_wheeler' || 'motor' => Icons.two_wheeler_rounded,
    'casino' || 'boardgames' => Icons.casino_rounded,
    'photo_camera' || 'photo' => Icons.photo_camera_rounded,
    'favorite' || 'social' => Icons.favorite_rounded,
    _ => Icons.grid_view_rounded,
  };
}
