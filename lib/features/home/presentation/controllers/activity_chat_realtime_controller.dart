import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_logger.dart';
import '../../data/models/activity_chat_message_model.dart';
import '../../domain/entities/activity_chat_message.dart';

class ActivityChatRealtimeController {
  ActivityChatRealtimeController(this._client);

  final SupabaseClient _client;
  final StreamController<ActivityChatMessage> _messages =
      StreamController<ActivityChatMessage>.broadcast();
  final Map<String, RealtimeChannel> _channels = <String, RealtimeChannel>{};
  final Set<String> _subscribingActivityIds = <String>{};

  Stream<ActivityChatMessage> get messages => _messages.stream;

  Future<void> subscribeToActivity(String activityId) async {
    if (activityId.isEmpty ||
        _channels.containsKey(activityId) ||
        _subscribingActivityIds.contains(activityId)) {
      return;
    }

    _subscribingActivityIds.add(activityId);
    final completer = Completer<void>();
    try {
      await _refreshRealtimeAuth();
      final channel = _client.channel(
        'activity-chat:$activityId',
        opts: const RealtimeChannelConfig(private: true),
      );
      _channels[activityId] = channel;
      channel
          .onBroadcast(
            event: 'message_created',
            callback: (payload) => _handleBroadcastPayload(payload),
          )
          .subscribe((status, error) {
            AppLogger.debug(
              'Activity chat realtime status for $activityId: ${status.name}',
              error: error,
            );
            if (!completer.isCompleted &&
                (status == RealtimeSubscribeStatus.subscribed ||
                    status == RealtimeSubscribeStatus.channelError ||
                    status == RealtimeSubscribeStatus.timedOut ||
                    status == RealtimeSubscribeStatus.closed)) {
              completer.complete();
            }
          });

      await completer.future.timeout(
        _subscribeTimeout,
        onTimeout: () {
          AppLogger.debug(
            'Activity chat realtime subscribe timed out for $activityId',
          );
        },
      );
    } finally {
      _subscribingActivityIds.remove(activityId);
    }
  }

  Future<void> subscribeToActivities(Iterable<String> activityIds) async {
    for (final activityId in activityIds.where((id) => id.isNotEmpty)) {
      if (_channels.length >= _maxActivityChannels &&
          !_channels.containsKey(activityId)) {
        AppLogger.debug('Activity chat realtime channel cap reached');
        return;
      }
      await subscribeToActivity(activityId);
    }
  }

  Future<void> unsubscribeFromActivity(String activityId) async {
    final channel = _channels.remove(activityId);
    _subscribingActivityIds.remove(activityId);
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }

  Future<void> stopAll() async {
    final channels = _channels.values.toList();
    _channels.clear();
    _subscribingActivityIds.clear();
    for (final channel in channels) {
      await _client.removeChannel(channel);
    }
  }

  void dispose() {
    unawaited(stopAll());
    _messages.close();
  }

  Future<void> _refreshRealtimeAuth() async {
    final token = _client.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      await _client.realtime.setAuth(token);
    }
  }

  void _handleBroadcastPayload(Map<String, dynamic> payload) {
    final messagePayload = _messagePayload(payload);
    final message = ActivityChatMessageModel.fromJson(
      messagePayload,
      currentUserId: _client.auth.currentUser?.id,
    );
    if (message.id.isEmpty || message.activityId.isEmpty) {
      return;
    }
    _messages.add(message);
  }
}

const _subscribeTimeout = Duration(seconds: 5);
const _maxActivityChannels = 75;

Map<String, dynamic> _messagePayload(Map<String, dynamic> payload) {
  final nestedPayload = payload['payload'];
  if (nestedPayload is Map<String, dynamic>) {
    return nestedPayload;
  }
  if (nestedPayload is Map) {
    return nestedPayload.map((key, value) => MapEntry(key.toString(), value));
  }
  return payload;
}
