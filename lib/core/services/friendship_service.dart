import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/supabase_function_auth.dart';

enum FriendshipStatus {
  none,
  self,
  pendingSent,
  pendingReceived,
  accepted,
  declined,
  blocked;

  factory FriendshipStatus.fromBackend(String? value) {
    return switch (value?.trim()) {
      'self' => FriendshipStatus.self,
      'pending_sent' => FriendshipStatus.pendingSent,
      'pending_received' => FriendshipStatus.pendingReceived,
      'accepted' => FriendshipStatus.accepted,
      'declined' => FriendshipStatus.declined,
      'blocked' => FriendshipStatus.blocked,
      _ => FriendshipStatus.none,
    };
  }

  String get backendValue {
    return switch (this) {
      FriendshipStatus.none => 'none',
      FriendshipStatus.self => 'self',
      FriendshipStatus.pendingSent => 'pending_sent',
      FriendshipStatus.pendingReceived => 'pending_received',
      FriendshipStatus.accepted => 'accepted',
      FriendshipStatus.declined => 'declined',
      FriendshipStatus.blocked => 'blocked',
    };
  }

  bool get canRequest =>
      this == FriendshipStatus.none || this == FriendshipStatus.declined;

  bool get isPendingSent => this == FriendshipStatus.pendingSent;

  bool get isPendingReceived => this == FriendshipStatus.pendingReceived;

  bool get isFriend => this == FriendshipStatus.accepted;
}

class FriendshipSummary extends Equatable {
  const FriendshipSummary({
    required this.profileId,
    required this.status,
    this.direction = 'none',
  });

  final String profileId;
  final FriendshipStatus status;
  final String direction;

  @override
  List<Object?> get props => [profileId, status, direction];
}

class FriendProfile extends Equatable {
  const FriendProfile({
    required this.id,
    required this.displayName,
    required this.initials,
    this.cityName,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String initials;
  final String? cityName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, displayName, initials, cityName, avatarUrl];
}

class FriendshipListItem extends Equatable {
  const FriendshipListItem({
    required this.friendshipId,
    required this.profileId,
    required this.status,
    required this.direction,
    required this.updatedAt,
    required this.profile,
  });

  factory FriendshipListItem.fromJson(Map<String, dynamic> json) {
    final profile = _asMap(json['profile']);
    return FriendshipListItem(
      friendshipId: _stringValue(json['friendship_id']),
      profileId: _stringValue(json['profile_id']),
      status: FriendshipStatus.fromBackend(_stringValue(json['status'])),
      direction: _stringValue(json['direction'], fallback: 'none'),
      updatedAt:
          DateTime.tryParse(_stringValue(json['updated_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      profile: FriendProfile(
        id: _stringValue(profile['id'] ?? json['profile_id']),
        displayName: _stringValue(
          profile['display_name'],
          fallback: 'TOCH gebruiker',
        ),
        initials: _stringValue(profile['initials'], fallback: '?'),
        cityName: _nullableString(profile['city_name']),
        avatarUrl: _nullableString(profile['avatar_url']),
      ),
    );
  }

  final String friendshipId;
  final String profileId;
  final FriendshipStatus status;
  final String direction;
  final DateTime updatedAt;
  final FriendProfile profile;

  bool get isIncomingPending =>
      status == FriendshipStatus.pendingReceived || direction == 'incoming';

  @override
  List<Object?> get props => [
    friendshipId,
    profileId,
    status,
    direction,
    updatedAt,
    profile,
  ];
}

class FriendshipService {
  const FriendshipService(this._client);

  final SupabaseClient _client;

  Future<FriendshipSummary> getStatus(String profileId) async {
    final response = await _client.functions
        .invoke(
          supabaseFriendsFunctionName,
          method: HttpMethod.get,
          headers: authenticatedFunctionHeaders(_client),
          queryParameters: {'profile_id': profileId},
        )
        .timeout(_friendshipTimeout);

    return _summaryFromPayload(_asMap(response.data), profileId);
  }

  Future<List<FriendshipListItem>> listFriends() async {
    final response = await _client.functions
        .invoke(
          supabaseFriendsFunctionName,
          method: HttpMethod.get,
          headers: authenticatedFunctionHeaders(_client),
        )
        .timeout(_friendshipTimeout);

    return _asList(_asMap(response.data)['friendships'])
        .map((item) => FriendshipListItem.fromJson(_asMap(item)))
        .where((item) => item.profileId.isNotEmpty)
        .toList();
  }

  Future<FriendshipSummary> request(String profileId) {
    return _update(profileId: profileId, action: 'request');
  }

  Future<FriendshipSummary> accept(String profileId) {
    return _update(profileId: profileId, action: 'accept');
  }

  Future<FriendshipSummary> decline(String profileId) {
    return _update(profileId: profileId, action: 'decline');
  }

  Future<FriendshipSummary> remove(String profileId) {
    return _update(profileId: profileId, action: 'remove');
  }

  Future<FriendshipSummary> _update({
    required String profileId,
    required String action,
  }) async {
    final response = await _client.functions
        .invoke(
          supabaseFriendsFunctionName,
          headers: authenticatedFunctionHeaders(_client),
          body: {'action': action, 'profile_id': profileId},
        )
        .timeout(_friendshipTimeout);

    return _summaryFromPayload(_asMap(response.data), profileId);
  }

  FriendshipSummary _summaryFromPayload(
    Map<String, dynamic> payload,
    String fallbackProfileId,
  ) {
    final friendship = _asMap(payload['friendship']);
    return FriendshipSummary(
      profileId: _stringValue(
        friendship['profile_id'],
        fallback: fallbackProfileId,
      ),
      status: FriendshipStatus.fromBackend(_stringValue(friendship['status'])),
      direction: _stringValue(friendship['direction'], fallback: 'none'),
    );
  }
}

const _friendshipTimeout = Duration(seconds: 5);

int countIncomingFriendRequests(Iterable<FriendshipListItem> friendships) {
  return friendships.where((friendship) => friendship.isIncomingPending).length;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is String) {
    return _asMap(jsonDecode(value));
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
    return _asList(jsonDecode(value));
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

String? _nullableString(Object? value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
}
