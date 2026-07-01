import 'dart:async';

import '../entities/activity_chat_message.dart';

abstract interface class ActivityChatRealtimeService {
  Stream<ActivityChatMessage> get messages;

  Future<void> subscribeToActivity(String activityId);

  Future<void> subscribeToActivities(Iterable<String> activityIds);

  Future<void> unsubscribeFromActivity(String activityId);

  Future<void> stopAll();
}
