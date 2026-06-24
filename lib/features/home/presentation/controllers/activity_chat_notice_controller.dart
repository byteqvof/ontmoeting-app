import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/supabase_function_auth.dart';
import '../../data/models/activity_chat_notice_model.dart';
import '../../domain/entities/activity_chat_message.dart';
import '../../domain/entities/activity_chat_notice.dart';
import 'activity_chat_realtime_controller.dart';

class ActivityChatNoticeTracker {
  ActivityChatNoticeTracker({String? currentUserId, String? activeActivityId})
    : _currentUserId = currentUserId,
      _activeActivityId = activeActivityId;

  String? _currentUserId;
  String? _activeActivityId;
  int _unreadCount = 0;
  final Map<String, int> _unreadByActivityId = <String, int>{};
  final Set<String> _seenMessageIds = <String>{};

  int get unreadCount => _unreadCount;

  bool isActivityOpen(String activityId) => _activeActivityId == activityId;

  set currentUserId(String? value) {
    _currentUserId = value;
  }

  set activeActivityId(String? value) {
    _activeActivityId = value;
  }

  ActivityChatNotice? trackRealtimeRecord(Map<String, dynamic> record) {
    final notice = ActivityChatNoticeModel.fromRealtimeRecord(
      record,
      currentUserId: _currentUserId,
    );
    if (notice == null || notice.isMine || !_seenMessageIds.add(notice.id)) {
      return null;
    }

    if (!isActivityOpen(notice.activityId)) {
      _unreadCount++;
      _unreadByActivityId.update(
        notice.activityId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return notice;
  }

  ActivityChatNotice? trackMessage(
    ActivityChatMessage message, {
    String? activityTitle,
  }) {
    if (message.isMine || !_seenMessageIds.add(message.id)) {
      return null;
    }

    final notice = ActivityChatNotice(
      id: message.id,
      activityId: message.activityId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderInitials: message.senderInitials,
      senderAvatarUrl: message.senderAvatarUrl,
      activityTitle: activityTitle == null || activityTitle.isEmpty
          ? 'Nieuwe chat'
          : activityTitle,
      body: message.body,
      createdAt: message.createdAt,
      isMine: message.isMine,
    );

    if (!isActivityOpen(notice.activityId)) {
      _unreadCount++;
      _unreadByActivityId.update(
        notice.activityId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return notice;
  }

  void rememberRealtimeRecord(Map<String, dynamic> record) {
    final notice = ActivityChatNoticeModel.fromRealtimeRecord(
      record,
      currentUserId: _currentUserId,
    );
    if (notice == null) {
      return;
    }
    _seenMessageIds.add(notice.id);
  }

  void clearUnread() {
    _unreadCount = 0;
    _unreadByActivityId.clear();
  }

  void markActivityRead(String activityId) {
    final count = _unreadByActivityId.remove(activityId) ?? 0;
    if (count <= 0) {
      return;
    }
    final nextCount = _unreadCount - count;
    _unreadCount = nextCount < 0 ? 0 : nextCount;
  }
}

class ActivityChatNoticeController {
  ActivityChatNoticeController(this._client, this._realtime);

  final SupabaseClient _client;
  final ActivityChatRealtimeController _realtime;
  final ActivityChatNoticeTracker _tracker = ActivityChatNoticeTracker();
  final ValueNotifier<int> _unreadCount = ValueNotifier<int>(0);
  final StreamController<ActivityChatNotice> _notices =
      StreamController<ActivityChatNotice>.broadcast();

  Timer? _initialSyncTimer;
  Timer? _syncTimer;
  StreamSubscription<ActivityChatMessage>? _messageSubscription;
  bool _isSyncing = false;
  DateTime? _activityIdsFetchedAt;
  final Set<String> _watchedActivityIds = <String>{};
  final Map<String, String> _watchedActivityTitles = <String, String>{};

  ValueListenable<int> get unreadCountListenable => _unreadCount;

  Stream<ActivityChatNotice> get notices => _notices.stream;

  bool isActivityOpen(String activityId) => _tracker.isActivityOpen(activityId);

  Future<void> start() async {
    if (_initialSyncTimer != null ||
        _syncTimer != null ||
        _messageSubscription != null) {
      return;
    }

    _tracker.currentUserId = _currentUserId;
    AppLogger.debug('Starting activity chat notice realtime subscriptions');
    _messageSubscription = _realtime.messages.listen(_handleRealtimeMessage);

    _initialSyncTimer = Timer(_initialSyncDelay, () {
      _initialSyncTimer = null;
      unawaited(_syncWatchedActivities());
      _syncTimer = Timer.periodic(
        _agendaRefreshInterval,
        (_) => unawaited(_syncWatchedActivities()),
      );
    });
  }

  Future<void> stop() async {
    _initialSyncTimer?.cancel();
    _syncTimer?.cancel();
    await _messageSubscription?.cancel();
    _initialSyncTimer = null;
    _syncTimer = null;
    _messageSubscription = null;
    _activityIdsFetchedAt = null;
    _watchedActivityIds.clear();
    _watchedActivityTitles.clear();
    _tracker.activeActivityId = null;
    clearUnread();
    await _realtime.stopAll();
  }

  void markActivityOpen(String activityId) {
    _tracker.activeActivityId = activityId;
    markActivityRead(activityId);
  }

  void markActivityClosed(String activityId) {
    if (_tracker.isActivityOpen(activityId)) {
      _tracker.activeActivityId = null;
    }
  }

  void clearUnread() {
    _tracker.clearUnread();
    _unreadCount.value = _tracker.unreadCount;
  }

  void markActivityRead(String activityId) {
    _tracker.markActivityRead(activityId);
    _unreadCount.value = _tracker.unreadCount;
  }

  void dispose() {
    unawaited(stop());
    _unreadCount.dispose();
    _notices.close();
  }

  String? get _currentUserId =>
      _client.auth.currentSession?.user.id ?? _client.auth.currentUser?.id;

  Future<void> _syncWatchedActivities() async {
    if (_isSyncing) {
      return;
    }
    final fetchedAt = _activityIdsFetchedAt;
    if (fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _agendaRefreshInterval) {
      return;
    }

    _isSyncing = true;
    try {
      final response = await _client.functions
          .invoke(
            supabaseActivityAgendaFunctionName,
            method: HttpMethod.get,
            headers: authenticatedFunctionHeaders(_client),
            queryParameters: {'limit': '100'},
          )
          .timeout(_noticeFunctionTimeout);

      final activities = _activitiesFromAgendaPayload(_asMap(response.data));
      final limitedEntries = activities.entries.take(_maxWatchedActivities);
      final activityIds = limitedEntries.map((entry) => entry.key).toSet();
      _activityIdsFetchedAt = DateTime.now();
      _watchedActivityIds
        ..clear()
        ..addAll(activityIds);
      _watchedActivityTitles
        ..clear()
        ..addEntries(limitedEntries);
      await _realtime.subscribeToActivities(_watchedActivityIds);
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Activity chat notice activity sync failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isSyncing = false;
    }
  }

  void _handleRealtimeMessage(ActivityChatMessage message) {
    _tracker.currentUserId = _currentUserId;
    final unreadBefore = _tracker.unreadCount;
    final notice = _tracker.trackMessage(
      message,
      activityTitle: _watchedActivityTitles[message.activityId],
    );
    if (notice == null) {
      return;
    }

    if (_tracker.unreadCount != unreadBefore) {
      _unreadCount.value = _tracker.unreadCount;
    }
    _notices.add(notice);
  }
}

const _initialSyncDelay = Duration(seconds: 2);
const _agendaRefreshInterval = Duration(seconds: 30);
const _noticeFunctionTimeout = Duration(seconds: 5);
const _maxWatchedActivities = 75;

Map<String, String> _activitiesFromAgendaPayload(Map<String, dynamic> payload) {
  final activities = [
    ..._asList(payload['hosted']),
    ..._asList(payload['joined']),
    ..._asList(payload['completed']),
  ].map(_asMap);

  return {
    for (final activity in activities)
      if (_stringValue(activity['id']).isNotEmpty)
        _stringValue(activity['id']): _stringValue(
          activity['title'],
          fallback: 'Nieuwe chat',
        ),
  };
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
