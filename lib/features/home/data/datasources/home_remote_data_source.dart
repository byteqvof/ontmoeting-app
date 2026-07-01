import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/supabase_function_auth.dart';
import '../../../../core/utils/toch_category_icons.dart';
import '../../domain/entities/activity_agenda.dart';
import '../../domain/entities/activity_chat_message.dart';
import '../../domain/entities/activity_completion_update.dart';
import '../../domain/entities/activity_feedback.dart';
import '../../domain/entities/activity_participation_update.dart';
import '../../domain/entities/create_activity_draft.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/entities/home_participant.dart';
import '../../domain/entities/meeting_location_suggestion.dart';
import '../models/activity_chat_message_model.dart';
import '../models/activity_feedback_model.dart';
import '../models/meeting_location_suggestion_model.dart';

abstract interface class HomeRemoteDataSource {
  Future<String> createActivity(CreateActivityDraft draft);

  Future<HomeActivity> updateActivity({
    required String activityId,
    required CreateActivityDraft draft,
  });

  Future<HomeFeed> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
  });

  Future<HomeActivity> getActivityById(String activityId);

  Future<ActivityParticipationUpdate> setActivityParticipation({
    required String activityId,
    required bool join,
  });

  Future<ActivityAgenda> getActivityAgenda();

  Future<List<ActivityChatMessage>> getActivityChatMessages({
    required String activityId,
    DateTime? afterCreatedAt,
    String? afterId,
  });

  Future<ActivityChatMessage> sendActivityChatMessage({
    required String activityId,
    required String body,
    required String clientMessageId,
  });

  Future<void> markActivityChatRead({
    required String activityId,
    String? messageId,
  });

  Future<ActivityCompletionUpdate> completeActivity({
    required String activityId,
  });

  Future<ActivityFeedback> submitActivityFeedback({
    required String activityId,
    required String targetProfileId,
    required int rating,
    required String comment,
  });

  Future<List<MeetingLocationSuggestion>> searchMeetingLocations({
    required String query,
    required HomeLocation nearLocation,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<String> createActivity(CreateActivityDraft draft) async {
    AppLogger.debug('Creating activity "${draft.title}"');

    final response = await _client.functions
        .invoke(
          supabaseCreateActivityFunctionName,
          headers: authenticatedFunctionHeaders(_client),
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
            'group_type': draft.groupType,
            'min_reputation_level': draft.minReputationLevel,
            'requires_identity_verified': draft.requiresIdentityVerified,
            'is_private_location': draft.isPrivateLocation,
            'target_age_bands': draft.targetAgeBands,
            'target_genders': draft.targetGenders,
          },
        )
        .timeout(_functionTimeout);

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
  Future<HomeActivity> updateActivity({
    required String activityId,
    required CreateActivityDraft draft,
  }) async {
    AppLogger.debug('Updating activity $activityId');

    final response = await _client.functions
        .invoke(
          supabaseUpdateActivityFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {
            'activity_id': activityId,
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
            'group_type': draft.groupType,
            'min_reputation_level': draft.minReputationLevel,
            'requires_identity_verified': draft.requiresIdentityVerified,
            'is_private_location': draft.isPrivateLocation,
            'target_age_bands': draft.targetAgeBands,
            'target_genders': draft.targetGenders,
          },
        )
        .timeout(_functionTimeout);

    final payload = _asMap(response.data);
    final activityJson = _asMap(payload['activity']);
    final activity = _activityFromJson(
      activityJson,
      _locationForActivityJson(activityJson),
      _client.auth.currentUser?.id,
      distanceLabelFallback: _locationLabelForActivityJson(activityJson),
      isOwnedByCurrentUserOverride: true,
    );
    if (activity.id.isEmpty) {
      throw StateError('Update activity completed without an activity id.');
    }
    return activity;
  }

  @override
  Future<HomeFeed> getHomeFeed({
    required HomeLocation location,
    required HomeFeedFilters filters,
  }) async {
    AppLogger.debug(
      'Fetching nearby activities for ${location.latitude}, '
      '${location.longitude} in ${filters.distanceKm}km',
    );

    final response = await _client.functions
        .invoke(
          supabaseNearbyActivitiesFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {
            'latitude': location.latitude,
            'longitude': location.longitude,
            'radius_km': filters.distanceKm,
            if (filters.dateFrom != null)
              'date_from': filters.dateFrom!.toUtc().toIso8601String(),
            if (filters.dateTo != null)
              'date_to': filters.dateTo!.toUtc().toIso8601String(),
            if (filters.categoryIds.isNotEmpty)
              'category_ids': filters.categoryIds,
            if (filters.targetAgeBands.isNotEmpty)
              'target_age_bands': filters.targetAgeBands,
            if (filters.targetGenders.isNotEmpty)
              'target_genders': filters.targetGenders,
            'requires_identity_verified': filters.requiresIdentityVerified,
            'available_only': filters.availableOnly,
            if (filters.minParticipants != null)
              'min_participants': filters.minParticipants,
            if (filters.maxParticipants != null)
              'max_participants': filters.maxParticipants,
            'sort': filters.sort,
            'limit': 50,
          },
        )
        .timeout(_startupFunctionTimeout);

    final payload = _asMap(response.data);
    final activitiesJson = _asList(payload['activities']);
    final currentUserId = _client.auth.currentUser?.id;
    final mappedActivities = activitiesJson
        .map(
          (activity) =>
              _activityFromJson(_asMap(activity), location, currentUserId),
        )
        .toList();
    final categories = await _categoriesFromPayload(payload, mappedActivities);
    final activities = _activitiesWithResolvedCategories(
      mappedActivities,
      categories,
    ).where((activity) => !activity.isOwnedByCurrentUser).toList();

    return HomeFeed(
      locationName: location.cityName,
      selectedTimeFilter: filters.selectedTimeFilter,
      selectedDistanceKm: filters.distanceKm,
      timeFilters: const ['Alles', 'Vandaag', 'Dit weekend'],
      distanceFilters: const [5, 10, 25, 50],
      categories: categories,
      activities: activities,
    );
  }

  @override
  Future<HomeActivity> getActivityById(String activityId) async {
    AppLogger.debug('Fetching activity detail for $activityId');

    final response = await _client.functions
        .invoke(
          supabaseActivityDetailFunctionName,
          method: HttpMethod.get,
          headers: authenticatedFunctionHeaders(_client),
          queryParameters: {'activity_id': activityId},
        )
        .timeout(_functionTimeout);

    final payload = _asMap(response.data);
    final activityJson = _asMap(payload['activity']);
    final currentUserId = _client.auth.currentUser?.id;
    final activity = _activityFromJson(
      activityJson,
      _locationForActivityJson(activityJson),
      currentUserId,
      distanceLabelFallback: _locationLabelForActivityJson(activityJson),
    );
    if (activity.id.isEmpty) {
      throw StateError('Activity detail completed without an activity id.');
    }

    return activity;
  }

  @override
  Future<ActivityParticipationUpdate> setActivityParticipation({
    required String activityId,
    required bool join,
  }) async {
    AppLogger.debug('${join ? 'Joining' : 'Leaving'} activity $activityId');

    final response = await _client.functions
        .invoke(
          supabaseActivityParticipationFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {'activity_id': activityId, 'action': join ? 'join' : 'leave'},
        )
        .timeout(_functionTimeout);

    final payload = _asMap(response.data);
    final participation = _participationUpdateFromJson(
      _asMap(payload['participation']),
    );

    if (participation.activityId.isEmpty) {
      throw StateError('Participation update completed without activity id.');
    }

    AppLogger.debug(
      'Participation updated for ${participation.activityId}: '
      'isJoined=${participation.isJoined}',
    );
    return participation;
  }

  @override
  Future<ActivityAgenda> getActivityAgenda() async {
    AppLogger.debug('Fetching activity agenda');

    final response = await _client.functions
        .invoke(
          supabaseActivityAgendaFunctionName,
          method: HttpMethod.get,
          headers: authenticatedFunctionHeaders(_client),
          queryParameters: {'limit': '100'},
        )
        .timeout(_functionTimeout);

    final payload = _asMap(response.data);
    final currentUserId = _client.auth.currentUser?.id;
    final hosted = _asList(payload['hosted'])
        .map((activity) => _asMap(activity))
        .map(
          (activity) => _activityFromJson(
            activity,
            _locationForActivityJson(activity),
            currentUserId,
            distanceLabelFallback: _locationLabelForActivityJson(activity),
            isOwnedByCurrentUserOverride: true,
          ),
        )
        .where((activity) => activity.id.isNotEmpty)
        .toList();
    final joined = _asList(payload['joined'])
        .map((activity) => _asMap(activity))
        .map(
          (activity) => _activityFromJson(
            activity,
            _locationForActivityJson(activity),
            currentUserId,
            distanceLabelFallback: _locationLabelForActivityJson(activity),
            isOwnedByCurrentUserOverride: false,
          ),
        )
        .where((activity) => activity.id.isNotEmpty)
        .toList();
    final completed = _asList(payload['completed'])
        .map((activity) => _asMap(activity))
        .map(
          (activity) => _activityFromJson(
            activity,
            _locationForActivityJson(activity),
            currentUserId,
            distanceLabelFallback: _locationLabelForActivityJson(activity),
          ),
        )
        .where((activity) => activity.id.isNotEmpty)
        .toList();

    AppLogger.debug(
      'Fetched activity agenda hosted=${hosted.length}, '
      'joined=${joined.length}, completed=${completed.length}',
    );
    return ActivityAgenda(
      hostedActivities: hosted,
      joinedActivities: joined,
      completedActivities: completed,
    );
  }

  @override
  Future<List<ActivityChatMessage>> getActivityChatMessages({
    required String activityId,
    DateTime? afterCreatedAt,
    String? afterId,
  }) async {
    AppLogger.debug('Fetching chat messages for activity $activityId');
    final queryParameters = <String, String>{
      'activity_id': activityId,
      'limit': '50',
      if (afterCreatedAt != null)
        'after_created_at': afterCreatedAt.toUtc().toIso8601String(),
      if (afterId != null && afterId.isNotEmpty) 'after_id': afterId,
    };

    final response = await _client.functions
        .invoke(
          supabaseActivityChatFunctionName,
          method: HttpMethod.get,
          headers: authenticatedFunctionHeaders(_client),
          queryParameters: queryParameters,
        )
        .timeout(_chatFunctionTimeout);

    final payload = _asMap(response.data);
    final currentUserId = _client.auth.currentUser?.id;
    return _asList(payload['messages'])
        .map(
          (message) => ActivityChatMessageModel.fromJson(
            _asMap(message),
            currentUserId: currentUserId,
          ),
        )
        .where((message) => message.id.isNotEmpty)
        .toList();
  }

  @override
  Future<ActivityChatMessage> sendActivityChatMessage({
    required String activityId,
    required String body,
    required String clientMessageId,
  }) async {
    AppLogger.debug('Sending chat message for activity $activityId');

    final response = await _client.functions
        .invoke(
          supabaseActivityChatFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {
            'activity_id': activityId,
            'body': body,
            'client_message_id': clientMessageId,
          },
        )
        .timeout(_functionTimeout);

    final payload = _asMap(response.data);
    final message = ActivityChatMessageModel.fromJson(
      _asMap(payload['message']),
      currentUserId: _client.auth.currentUser?.id,
    );

    if (message.id.isEmpty) {
      throw StateError('Send chat message completed without a message id.');
    }

    return message;
  }

  @override
  Future<void> markActivityChatRead({
    required String activityId,
    String? messageId,
  }) async {
    AppLogger.debug('Marking activity chat read for $activityId');

    await _client.functions
        .invoke(
          supabaseActivityChatFunctionName,
          method: HttpMethod.patch,
          headers: authenticatedFunctionHeaders(_client),
          body: {
            'activity_id': activityId,
            if (messageId != null && messageId.isNotEmpty)
              'message_id': messageId,
          },
        )
        .timeout(_functionTimeout);
  }

  @override
  Future<ActivityCompletionUpdate> completeActivity({
    required String activityId,
  }) async {
    AppLogger.debug('Completing activity $activityId');

    final response = await _client.functions
        .invoke(
          supabaseActivityCompleteFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {'activity_id': activityId},
        )
        .timeout(_functionTimeout);

    final payload = _asMap(response.data);
    final completion = _completionUpdateFromJson(_asMap(payload['completion']));
    if (completion.activityId.isEmpty) {
      throw StateError('Complete activity completed without activity id.');
    }
    return completion;
  }

  @override
  Future<ActivityFeedback> submitActivityFeedback({
    required String activityId,
    required String targetProfileId,
    required int rating,
    required String comment,
  }) async {
    AppLogger.debug('Submitting feedback for activity $activityId');

    final response = await _client.functions
        .invoke(
          supabaseActivityFeedbackFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {
            'activity_id': activityId,
            'target_profile_id': targetProfileId,
            'rating': rating,
            'comment': comment,
          },
        )
        .timeout(_functionTimeout);

    final payload = _asMap(response.data);
    final feedback = ActivityFeedbackModel.fromJson(
      _asMap(payload['feedback']),
    );
    if (feedback.id.isEmpty) {
      throw StateError('Submit feedback completed without feedback id.');
    }
    return feedback;
  }

  @override
  Future<List<MeetingLocationSuggestion>> searchMeetingLocations({
    required String query,
    required HomeLocation nearLocation,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.debug(
      'Meeting location search request '
      'function=$supabaseLocationsSearchFunctionName '
      'query="$query" queryLength=${query.trim().length} '
      'near="${nearLocation.cityName}" '
      'lat=${nearLocation.latitude} lon=${nearLocation.longitude}',
    );

    try {
      final response = await _client.functions
          .invoke(
            supabaseLocationsSearchFunctionName,
            method: HttpMethod.get,
            headers: authenticatedFunctionHeaders(_client),
            queryParameters: {
              'q': query,
              'limit': '8',
              'lat': nearLocation.latitude.toString(),
              'lon': nearLocation.longitude.toString(),
            },
          )
          .timeout(_functionTimeout);

      final payload = _asMap(response.data);
      final requestId = _stringValue(
        payload['request_id'] ?? payload['requestId'],
        fallback: '-',
      );
      final rawSuggestions = _asList(payload['suggestions']);
      final mappedSuggestions = rawSuggestions.map((suggestion) {
        return MeetingLocationSuggestionModel.fromJson(_asMap(suggestion));
      }).toList();
      final validSuggestions = mappedSuggestions.where((suggestion) {
        return suggestion.id.isNotEmpty &&
            suggestion.addressLine.isNotEmpty &&
            suggestion.city.isNotEmpty &&
            suggestion.latitude != 0 &&
            suggestion.longitude != 0;
      }).toList();
      final droppedCount = mappedSuggestions.length - validSuggestions.length;

      AppLogger.debug(
        'Meeting location search response '
        'status=${response.status} requestId=$requestId '
        'raw=${rawSuggestions.length} mapped=${mappedSuggestions.length} '
        'valid=${validSuggestions.length} dropped=$droppedCount '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
      );

      if (droppedCount > 0) {
        AppLogger.debug(
          'Meeting location search dropped invalid suggestions '
          'requestId=$requestId dropped=$droppedCount',
        );
      }

      return validSuggestions;
    } on FunctionException catch (error, stackTrace) {
      AppLogger.debug(
        'Meeting location search function failed '
        'status=${error.status} reason=${error.reasonPhrase} '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        error: error.details,
        stackTrace: stackTrace,
      );
      rethrow;
    } on TimeoutException catch (error, stackTrace) {
      AppLogger.debug(
        'Meeting location search timed out '
        'afterMs=${stopwatch.elapsedMilliseconds}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Meeting location search failed '
        'elapsedMs=${stopwatch.elapsedMilliseconds}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      stopwatch.stop();
    }
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
      final data = await _client
          .from('activity_categories')
          .select()
          .timeout(_startupFunctionTimeout);

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

  HomeActivity _activityFromJson(
    Map<String, dynamic> json,
    HomeLocation userLocation,
    String? currentUserId, {
    String? distanceLabelFallback,
    bool? isJoinedOverride,
    bool? isOwnedByCurrentUserOverride,
  }) {
    final categoryJson = _asMap(json['category']);
    final category = _categoryFromJson(
      categoryJson.isEmpty ? {'id': json['category_id']} : categoryJson,
    );
    final host = _asMap(json['host']);
    final hostTrust = _asMap(host['trust']);
    final chatSummary = _asMap(json['chat_summary'] ?? json['chatSummary']);
    final lastSender = _asMap(
      chatSummary['last_sender'] ?? chatSummary['lastSender'],
    );
    final participants = _asList(
      json['participants'] ??
          json['participantPreview'] ??
          json['participant_preview'],
    ).map((participant) => _asMap(participant)).toList();
    final startAt = _dateTimeOrNull(
      json['startAt'] ?? json['start_at'] ?? json['starts_at'],
    );
    final participantCount = _optionalIntValue(
      json['participantCount'] ??
          json['participant_count'] ??
          json['participants_count'],
    );
    final maxParticipants = _optionalIntValue(
      json['maxParticipants'] ?? json['max_participants'] ?? json['capacity'],
    );
    final availableSpots =
        _optionalIntValue(json['availableSpots'] ?? json['available_spots']) ??
        _availableSpotsFrom(maxParticipants, participantCount);
    final participationStatus = _nullableString(
      json['participation_status'] ?? json['participationStatus'],
    );
    final isJoined = _boolValue(json['isJoined'] ?? json['is_joined']);
    final cityName = _stringValue(
      json['locationName'] ??
          json['location_name'] ??
          json['city_name'] ??
          json['city'],
    );
    final distanceKm =
        _optionalDoubleValue(json['distanceKm'] ?? json['distance_km']) ??
        _distanceKmFrom(
          userLocation: userLocation,
          latitude: _optionalDoubleValue(json['latitude'] ?? json['lat']),
          longitude: _optionalDoubleValue(json['longitude'] ?? json['lng']),
        );
    final latitude = _optionalDoubleValue(json['latitude'] ?? json['lat']) ?? 0;
    final longitude =
        _optionalDoubleValue(json['longitude'] ?? json['lng']) ?? 0;
    final meetingPoint = _stringValue(
      json['meetingPoint'] ??
          json['meeting_point'] ??
          json['address_line'] ??
          json['address'] ??
          json['city'],
    );
    final hostId = _stringValue(
      host['id'] ??
          host['profile_id'] ??
          host['hostId'] ??
          json['organizer_id'] ??
          json['host_id'],
    );
    final isOwnedByCurrentUser =
        isOwnedByCurrentUserOverride ??
        (currentUserId != null &&
            currentUserId.isNotEmpty &&
            hostId == currentUserId);
    final effectiveIsJoined = isJoinedOverride ?? isJoined;
    final canSendChat = _boolValue(
      json['can_send_chat'] ??
          json['canSendChat'] ??
          chatSummary['can_send_chat'] ??
          chatSummary['canSendChat'],
      fallback: isOwnedByCurrentUser || effectiveIsJoined,
    );

    return HomeActivity(
      id: _stringValue(json['id']),
      category: category,
      distanceKm: distanceKm,
      distanceLabel: _stringValue(
        json['distanceLabel'] ?? json['distance_label'],
        fallback: distanceLabelFallback ?? _formatDistance(distanceKm),
      ),
      title: _stringValue(json['title']),
      isFeatured: _boolValue(
        json['featured'] ?? json['is_featured'] ?? json['isFeatured'],
      ),
      dateLabel: _stringValue(
        json['dateLabel'] ?? json['date_label'],
        fallback: startAt == null ? '' : _formatDateLabel(startAt),
      ),
      timeLabel: _stringValue(
        json['timeLabel'] ?? json['time_label'],
        fallback: startAt == null ? '' : _formatTimeLabel(startAt),
      ),
      startsAt: startAt,
      latitude: latitude,
      longitude: longitude,
      locationName: cityName,
      meetingPoint: meetingPoint,
      description: _stringValue(json['description']),
      hostId: hostId,
      hostName: _stringValue(
        host['shortName'] ??
            host['short_name'] ??
            host['displayName'] ??
            host['display_name'],
        fallback: 'Organisator',
      ),
      hostFullName: _stringValue(
        host['displayName'] ?? host['display_name'],
        fallback: 'Organisator',
      ),
      hostSubtitle: _stringValue(host['subtitle'], fallback: cityName),
      hostScore: _intValue(
        hostTrust['reputation_score'] ??
            host['reputationScore'] ??
            host['reputation_score'] ??
            host['attendanceScore'] ??
            host['attendance_score'],
        fallback: 100,
      ),
      hostIdentityVerified:
          _stringValue(hostTrust['identity_status']) == 'verified' ||
          _boolValue(host['identity_verified'] ?? host['is_verified']),
      hostReputationLevel: _stringValue(
        hostTrust['reputation_level'] ?? host['reputation_level'],
        fallback: 'new_member',
      ),
      hostAvatarUrl: _nullableString(host['avatarUrl'] ?? host['avatar_url']),
      hostFeedbackSubmitted: _boolValue(
        host['feedback_submitted'] ?? host['feedbackSubmitted'],
      ),
      participants: participants.map(_participantFromJson).toList(),
      participantCount: participantCount ?? participants.length,
      availableSpots: availableSpots,
      spotsLabel: _stringValue(
        json['spotsLabel'] ?? json['spots_label'],
        fallback: _spotsLabelFor(
          status: _stringValue(json['status'], fallback: 'published'),
          isJoined: effectiveIsJoined,
          availableSpots: availableSpots,
        ),
      ),
      status: _stringValue(json['status'], fallback: 'published'),
      groupType: _stringValue(json['group_type'], fallback: 'open'),
      minReputationLevel: _stringValue(
        json['min_reputation_level'],
        fallback: 'new_member',
      ),
      requiresIdentityVerified: _boolValue(json['requires_identity_verified']),
      isPrivateLocation: _boolValue(json['is_private_location']),
      targetAgeBands: _stringListValue(json['target_age_bands']),
      targetGenders: _stringListValue(json['target_genders']),
      isJoined: effectiveIsJoined,
      participationStatus: participationStatus,
      isOwnedByCurrentUser: isOwnedByCurrentUser,
      chatLastMessage: _nullableString(
        chatSummary['last_message'] ?? chatSummary['lastMessage'],
      ),
      chatLastMessageAt: _dateTimeOrNull(
        chatSummary['last_message_at'] ?? chatSummary['lastMessageAt'],
      ),
      chatLastSenderName: _nullableString(
        lastSender['display_name'] ??
            lastSender['displayName'] ??
            chatSummary['last_sender_name'] ??
            chatSummary['lastSenderName'],
      ),
      chatLastMessageType: _stringValue(
        chatSummary['last_message_type'] ?? chatSummary['lastMessageType'],
        fallback: 'user',
      ),
      chatUnreadCount: _intValue(
        chatSummary['unread_count'] ?? chatSummary['unreadCount'],
      ),
      canSendChat: canSendChat,
      isFavorited: _boolValue(json['is_favorited'] ?? json['isFavorited']),
    );
  }

  HomeParticipant _participantFromJson(Map<String, dynamic> json) {
    final displayName = _stringValue(
      json['displayName'] ?? json['display_name'],
    );

    return HomeParticipant(
      id: _stringValue(json['id'] ?? json['profile_id'] ?? json['user_id']),
      displayName: displayName,
      initials: _stringValue(
        json['initials'],
        fallback: _initialsFor(displayName),
      ),
      isHost: _boolValue(json['isHost'] ?? json['is_host']),
      avatarUrl: _nullableString(json['avatarUrl'] ?? json['avatar_url']),
      attendanceStatus: _nullableString(
        json['attendanceStatus'] ?? json['attendance_status'],
      ),
      attendanceMarkedAt: _dateTimeOrNull(
        json['attendanceMarkedAt'] ?? json['attendance_marked_at'],
      ),
      feedbackSubmitted: _boolValue(
        json['feedbackSubmitted'] ?? json['feedback_submitted'],
      ),
    );
  }

  ActivityParticipationUpdate _participationUpdateFromJson(
    Map<String, dynamic> json,
  ) {
    return ActivityParticipationUpdate(
      activityId: _stringValue(json['activity_id'] ?? json['activityId']),
      isJoined: _boolValue(json['is_joined'] ?? json['isJoined']),
      participants: _asList(json['participants'])
          .map((participant) => _participantFromJson(_asMap(participant)))
          .toList(),
      participantsCount: _intValue(
        json['participants_count'] ?? json['participantsCount'],
      ),
      availableSpots: _intValue(
        json['available_spots'] ?? json['availableSpots'],
      ),
      participationStatus: _nullableString(
        json['participation_status'] ?? json['participationStatus'],
      ),
    );
  }

  ActivityCompletionUpdate _completionUpdateFromJson(
    Map<String, dynamic> json,
  ) {
    return ActivityCompletionUpdate(
      activityId: _stringValue(json['activity_id'] ?? json['activityId']),
      status: _stringValue(json['status'], fallback: 'completed'),
    );
  }

  HomeCategory _categoryFromJson(Map<String, dynamic> json) {
    final slug = _stringValue(json['slug'], fallback: 'unknown');
    final id = _stringValue(json['id'], fallback: slug);
    final label = _stringValue(json['label'] ?? json['title'], fallback: slug);
    final iconKey = _stringValue(json['iconKey'] ?? json['icon_key']);

    return HomeCategory(
      id: id,
      label: label,
      icon: tochCategoryIcon(id: id, label: label, iconKey: iconKey),
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

const _startupFunctionTimeout = Duration(seconds: 5);
const _chatFunctionTimeout = Duration(seconds: 5);
const _functionTimeout = Duration(seconds: 8);

const _allCategory = HomeCategory(
  id: 'all',
  label: 'Alles',
  icon: Icons.explore_rounded,
  color: Color(0xFF19211C),
  backgroundColor: Color(0xFFFFFFFF),
);

List<HomeCategory> _sortedCategories(Iterable<HomeCategory> categories) {
  return categories.toList()..sort(
    (left, right) =>
        left.label.toLowerCase().compareTo(right.label.toLowerCase()),
  );
}

List<HomeActivity> _activitiesWithResolvedCategories(
  List<HomeActivity> activities,
  List<HomeCategory> categories,
) {
  final categoriesById = {
    for (final category in categories)
      if (category.id != 'all') category.id: category,
  };

  return activities
      .map(
        (activity) => activity.copyWith(
          category: categoriesById[activity.category.id] ?? activity.category,
        ),
      )
      .toList();
}

HomeLocation _locationForActivityJson(Map<String, dynamic> json) {
  return HomeLocation(
    latitude: _optionalDoubleValue(json['latitude'] ?? json['lat']) ?? 0,
    longitude: _optionalDoubleValue(json['longitude'] ?? json['lng']) ?? 0,
    cityName: _locationLabelForActivityJson(json),
  );
}

String _locationLabelForActivityJson(Map<String, dynamic> json) {
  return _stringValue(
    json['locationName'] ??
        json['location_name'] ??
        json['city_name'] ??
        json['city'] ??
        json['address_line'],
    fallback: 'Activiteit',
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

List<String> _stringListValue(Object? value) {
  return _asList(value)
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

double? _optionalDoubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _optionalIntValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

int _availableSpotsFrom(int? maxParticipants, int? participantCount) {
  if (maxParticipants == null || maxParticipants <= 0) {
    return 0;
  }
  final remaining = maxParticipants - (participantCount ?? 0);
  return remaining < 0 ? 0 : remaining;
}

double _distanceKmFrom({
  required HomeLocation userLocation,
  required double? latitude,
  required double? longitude,
}) {
  if (latitude == null || longitude == null) {
    return 0;
  }

  const earthRadiusKm = 6371.0;
  final userLatitude = _degreesToRadians(userLocation.latitude);
  final activityLatitude = _degreesToRadians(latitude);
  final latitudeDelta = _degreesToRadians(latitude - userLocation.latitude);
  final longitudeDelta = _degreesToRadians(longitude - userLocation.longitude);
  final haversine =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(userLatitude) *
          math.cos(activityLatitude) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  final centralAngle =
      2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  return earthRadiusKm * centralAngle;
}

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

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
  final text = value.toString();
  return (DateTime.tryParse(text) ??
          DateTime.tryParse(text.replaceFirst(' ', 'T')))
      ?.toLocal();
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

String _spotsLabelFor({
  required String status,
  required bool isJoined,
  required int availableSpots,
}) {
  if (status == 'completed') {
    return 'afgerond';
  }
  if (isJoined) {
    return 'jij gaat ook';
  }
  return 'nog $availableSpots plekken';
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(0, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String? _nullableString(Object? value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
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
