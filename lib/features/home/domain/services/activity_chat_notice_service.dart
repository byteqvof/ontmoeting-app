import 'dart:async';

import '../entities/activity_chat_notice.dart';

abstract interface class ActivityChatNoticeService {
  Stream<ActivityChatNotice> get notices;

  Stream<int> get unreadCounts;

  int get unreadCount;

  bool isActivityOpen(String activityId);

  Future<void> start();

  Future<void> stop();

  void markActivityOpen(String activityId);

  void markActivityClosed(String activityId);

  void clearUnread();

  void markActivityRead(String activityId);
}
